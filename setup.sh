#!/bin/bash

# n8n Docker + Domain + SSL Otomatik Kurulum Scripti
# Debian 12 için hazırlanmıştır

set -e

# Renkli çıktı için
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=========================================="
echo "n8n Docker + SSL Kurulum Scripti"
echo "=========================================="
echo ""

# Root kontrolü
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Bu scripti root olarak veya sudo ile çalıştırın${NC}"
    exit 1
fi

# Kullanıcı bilgilerini al
echo -e "${YELLOW}Lütfen aşağıdaki bilgileri girin:${NC}"
read -p "Domain adınız (örn: kedileriseverizki.xyz): " DOMAIN
read -p "n8n kullanıcı adı (örn: admin): " N8N_USER
read -sp "n8n şifresi: " N8N_PASSWORD
echo ""
read -p "Email adresiniz (SSL sertifikası için): " EMAIL

echo ""
echo -e "${GREEN}Girilen bilgiler:${NC}"
echo "Domain: $DOMAIN"
echo "Kullanıcı: $N8N_USER"
echo "Email: $EMAIL"
echo ""
read -p "Devam etmek istiyor musunuz? (y/n): " CONFIRM

if [ "$CONFIRM" != "y" ]; then
    echo "Kurulum iptal edildi."
    exit 0
fi

# Sistem güncellemesi
echo ""
echo -e "${GREEN}[1/10] Sistem güncelleniyor...${NC}"
apt update && apt upgrade -y

# Git ve UFW kurulumu
echo -e "${GREEN}[2/10] Git ve UFW kuruluyor...${NC}"
apt install git ufw -y

# Docker kurulumu
if ! command -v docker &> /dev/null; then
    echo -e "${GREEN}[3/10] Docker kuruluyor...${NC}"
    apt install apt-transport-https ca-certificates curl gnupg lsb-release -y
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt update
    apt install docker-ce docker-ce-cli containerd.io -y
    systemctl start docker
    systemctl enable docker
else
    echo -e "${YELLOW}[3/10] Docker zaten kurulu, atlanıyor...${NC}"
fi

# Docker Compose kurulumu
if ! command -v docker-compose &> /dev/null; then
    echo -e "${GREEN}[4/10] Docker Compose kuruluyor...${NC}"
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
else
    echo -e "${YELLOW}[4/10] Docker Compose zaten kurulu, atlanıyor...${NC}"
fi

# Nginx ve Certbot kurulumu
echo -e "${GREEN}[5/10] Nginx ve Certbot kuruluyor...${NC}"
apt install nginx certbot python3-certbot-nginx -y

# n8n dizini oluşturma
echo -e "${GREEN}[6/10] n8n dizini oluşturuluyor...${NC}"
mkdir -p /opt/n8n
cd /opt/n8n

# docker-compose.yml oluşturma
echo -e "${GREEN}[7/10] docker-compose.yml dosyası oluşturuluyor...${NC}"
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
      
      # N8N settings with Domain
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

# n8n başlatma
echo -e "${GREEN}[8/10] n8n başlatılıyor...${NC}"
docker-compose up -d
sleep 10

# Nginx yapılandırması
echo -e "${GREEN}[9/10] Nginx yapılandırılıyor...${NC}"
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

ln -sf /etc/nginx/sites-available/n8n /etc/nginx/sites-enabled/
nginx -t
systemctl reload nginx

# Firewall ayarları
echo -e "${GREEN}[10/10] Firewall yapılandırılıyor...${NC}"
ufw --force enable
ufw allow 'Nginx Full'
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw reload

# SSL sertifikası alma
echo -e "${GREEN}SSL sertifikası alınıyor...${NC}"
certbot --nginx -d ${DOMAIN} --non-interactive --agree-tos --email ${EMAIL} --redirect

# Kurulum tamamlandı
echo ""
echo "=========================================="
echo -e "${GREEN}✓ Kurulum başarıyla tamamlandı!${NC}"
echo "=========================================="
echo ""
echo -e "${GREEN}n8n Bilgileri:${NC}"
echo "URL: https://${DOMAIN}"
echo "Kullanıcı adı: ${N8N_USER}"
echo "Şifre: [belirlediğiniz şifre]"
echo ""
echo -e "${YELLOW}Yönetim Komutları:${NC}"
echo "Durdurmak: cd /opt/n8n && docker-compose stop"
echo "Başlatmak: cd /opt/n8n && docker-compose start"
echo "Loglar: cd /opt/n8n && docker-compose logs -f"
echo "Güncellemek: cd /opt/n8n && docker-compose pull && docker-compose up -d"
echo ""
echo -e "${GREEN}Tarayıcınızda https://${DOMAIN} adresine gidebilirsiniz!${NC}"
echo ""