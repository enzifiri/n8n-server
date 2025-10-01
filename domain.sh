#!/bin/bash

# n8n Domain + SSL Yapılandırma Scripti
# Mevcut n8n kurulumuna domain ve SSL ekler

set -e

# Renkli çıktı için
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "=========================================="
echo "n8n Domain + SSL Yapılandırma"
echo "=========================================="
echo ""

# Root kontrolü
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Bu scripti root olarak veya sudo ile çalıştırın${NC}"
    exit 1
fi

# n8n kurulu mu kontrol et
if [ ! -f "/opt/n8n/docker-compose.yml" ]; then
    echo -e "${RED}Hata: n8n kurulumu bulunamadı!${NC}"
    echo "Önce setup.sh scriptini çalıştırarak n8n'i kurun."
    exit 1
fi

# Docker çalışıyor mu kontrol et
if ! docker ps | grep -q n8n; then
    echo -e "${RED}Hata: n8n container'ı çalışmıyor!${NC}"
    echo "n8n'i başlatmak için: cd /opt/n8n && docker-compose start"
    exit 1
fi

# Kullanıcı bilgilerini al
echo -e "${YELLOW}Domain Yapılandırması${NC}"
echo ""
echo -e "${BLUE}ℹ️  DNS ayarlarınızın sunucunuza yönlendirildiğinden emin olun!${NC}"
echo ""
read -p "Domain adınız (örn: example.com): " DOMAIN
read -p "Email adresiniz (SSL sertifikası için): " EMAIL

# Mevcut kullanıcı bilgilerini docker-compose.yml'den al
N8N_USER=$(grep "N8N_BASIC_AUTH_USER=" /opt/n8n/docker-compose.yml | cut -d'=' -f2)
N8N_PASSWORD=$(grep "N8N_BASIC_AUTH_PASSWORD=" /opt/n8n/docker-compose.yml | cut -d'=' -f2)

echo ""
echo -e "${GREEN}Yapılandırma Bilgileri:${NC}"
echo "Domain: $DOMAIN"
echo "Email: $EMAIL"
echo "n8n Kullanıcı: $N8N_USER"
echo ""
read -p "Devam etmek istiyor musunuz? (y/n): " CONFIRM

if [ "$CONFIRM" != "y" ]; then
    echo "İşlem iptal edildi."
    exit 0
fi

# DNS kontrolü
echo ""
echo -e "${YELLOW}DNS kontrolü yapılıyor...${NC}"
DOMAIN_IP=$(dig +short $DOMAIN | tail -n1)
SERVER_IP=$(hostname -I | awk '{print $1}')

if [ -z "$DOMAIN_IP" ]; then
    echo -e "${RED}⚠️  Uyarı: Domain DNS kaydı bulunamadı!${NC}"
    echo "DNS ayarlarınızın yayılması için 5-30 dakika beklemeniz gerekebilir."
    echo ""
    read -p "Yine de devam etmek istiyor musunuz? (y/n): " FORCE_CONTINUE
    if [ "$FORCE_CONTINUE" != "y" ]; then
        echo "İşlem iptal edildi. DNS ayarlarınız yayıldıktan sonra tekrar deneyin."
        exit 0
    fi
elif [ "$DOMAIN_IP" != "$SERVER_IP" ]; then
    echo -e "${RED}⚠️  Uyarı: Domain IP ($DOMAIN_IP) sunucu IP'niz ($SERVER_IP) ile eşleşmiyor!${NC}"
    echo ""
    read -p "Yine de devam etmek istiyor musunuz? (y/n): " FORCE_CONTINUE
    if [ "$FORCE_CONTINUE" != "y" ]; then
        echo "İşlem iptal edildi. DNS ayarlarınızı kontrol edin."
        exit 0
    fi
else
    echo -e "${GREEN}✓ DNS doğrulaması başarılı!${NC}"
fi

# Nginx kurulumu
echo ""
echo -e "${GREEN}[1/6] Nginx ve Certbot kuruluyor...${NC}"
apt update
apt install nginx certbot python3-certbot-nginx -y

# n8n container'ı durdur
echo -e "${GREEN}[2/6] n8n container'ı durduruluyor...${NC}"
cd /opt/n8n
docker-compose down

# docker-compose.yml güncelle
echo -e "${GREEN}[3/6] docker-compose.yml güncelleniyor...${NC}"
cat > docker-compose.yml <<EOF
version: '3.8'

services:
  n8n:
    image: n8nio/n8n:latest
    container_name: n8n
    restart: unless-stopped
    ports:
      - "5678:5678"
    environment:
      # Authentication
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=${N8N_USER}
      - N8N_BASIC_AUTH_PASSWORD=${N8N_PASSWORD}
      - N8N_SECURE_COOKIE=true
      - N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true
      - N8N_RUNNERS_ENABLED=true
      - N8N_RUNNERS_MODE=internal
      - DB_SQLITE_POOL_SIZE=5
      - N8N_PAYLOAD_SIZE_MAX=100
      - EXECUTIONS_TIMEOUT=300
      - EXECUTIONS_TIMEOUT_MAX=600
      - N8N_DEFAULT_BINARY_DATA_MODE=filesystem
      - WEBHOOK_TIMEOUT=300
      
      # N8N settings with Domain (HTTPS)
      - N8N_HOST=${DOMAIN}
      - N8N_PORT=5678
      - N8N_PROTOCOL=https
      - NODE_ENV=production
      - N8N_CORS_ORIGIN=*
      - WEBHOOK_URL=https://${DOMAIN}/
      
      # Timezone
      - GENERIC_TIMEZONE=Europe/Istanbul
      - TZ=Europe/Istanbul
      
    volumes:
      - n8n_data:/home/node/.n8n
    networks:
      - n8n-network

volumes:
  n8n_data:

networks:
  n8n-network:
    driver: bridge
EOF

# n8n'i tekrar başlat
echo -e "${GREEN}[4/6] n8n tekrar başlatılıyor...${NC}"
docker-compose up -d
sleep 10

# Nginx yapılandırması
echo -e "${GREEN}[5/6] Nginx yapılandırılıyor...${NC}"
cat > /etc/nginx/sites-available/n8n <<EOF
server {
    listen 80;
    server_name ${DOMAIN};

    location / {
        proxy_pass http://localhost:5678;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        
        # Timeout ayarları
        proxy_connect_timeout 300s;
        proxy_send_timeout 300s;
        proxy_read_timeout 300s;
    }
}
EOF

# Nginx site'ı aktif et
ln -sf /etc/nginx/sites-available/n8n /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl reload nginx

# Firewall güncelle
echo -e "${GREEN}[6/6] Firewall güncelleniyor...${NC}"
ufw allow 'Nginx Full'
ufw allow 80/tcp
ufw allow 443/tcp
ufw reload

# SSL sertifikası al
echo ""
echo -e "${GREEN}SSL sertifikası alınıyor...${NC}"
certbot --nginx -d ${DOMAIN} --non-interactive --agree-tos --email ${EMAIL} --redirect

# Kurulum tamamlandı
echo ""
echo "=========================================="
echo -e "${GREEN}✓ Domain yapılandırması tamamlandı!${NC}"
echo "=========================================="
echo ""
echo -e "${GREEN}🎉 n8n artık domain ile erişilebilir!${NC}"
echo ""
echo -e "${GREEN}Erişim Bilgileri:${NC}"
echo "URL: https://${DOMAIN}"
echo "Kullanıcı adı: ${N8N_USER}"
echo "Şifre: [daha önce belirlediğiniz şifre]"
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}📌 SSL Sertifikası${NC}"
echo "Let's Encrypt sertifikanız otomatik olarak yenilenecektir."
echo "Test etmek için: sudo certbot renew --dry-run"
echo ""
echo -e "${YELLOW}📌 Yönetim Komutları:${NC}"
echo "n8n Durdurmak: cd /opt/n8n && docker-compose stop"
echo "n8n Başlatmak: cd /opt/n8n && docker-compose start"
echo "Loglar: cd /opt/n8n && docker-compose logs -f"
echo "Nginx Reload: sudo systemctl reload nginx"
echo ""
echo -e "${GREEN}Tarayıcınızda https://${DOMAIN} adresine gidebilirsiniz!${NC}"
echo ""