#!/bin/bash

# n8n Docker Kurulum Scripti (Domain'siz - Local IP)
# Debian 12 için hazırlanmıştır

set -e

# Renkli çıktı için
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "=========================================="
echo "n8n Docker Kurulum Scripti"
echo "=========================================="
echo ""

# Root kontrolü
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Bu scripti root olarak veya sudo ile çalıştırın${NC}"
    exit 1
fi

# Kullanıcı bilgilerini al
echo -e "${YELLOW}Lütfen aşağıdaki bilgileri girin:${NC}"
read -p "n8n kullanıcı adı (örn: admin): " N8N_USER
read -sp "n8n şifresi: " N8N_PASSWORD
echo ""

echo ""
echo -e "${GREEN}Girilen bilgiler:${NC}"
echo "Kullanıcı: $N8N_USER"
echo "Şifre: ********"
echo ""
read -p "Devam etmek istiyor musunuz? (y/n): " CONFIRM

if [ "$CONFIRM" != "y" ]; then
    echo "Kurulum iptal edildi."
    exit 0
fi

# Sunucu IP adresini otomatik al
SERVER_IP=$(hostname -I | awk '{print $1}')

# Sistem güncellemesi
echo ""
echo -e "${GREEN}[1/9] Sistem güncelleniyor...${NC}"
apt update && apt upgrade -y

# Git kurulumu
echo -e "${GREEN}[2/9] Git kuruluyor...${NC}"
apt install git -y

# Docker kurulumu
if ! command -v docker &> /dev/null; then
    echo -e "${GREEN}[3/9] Docker kuruluyor...${NC}"
    apt install apt-transport-https ca-certificates curl gnupg lsb-release -y
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt update
    apt install docker-ce docker-ce-cli containerd.io -y
    systemctl start docker
    systemctl enable docker
else
    echo -e "${YELLOW}[3/9] Docker zaten kurulu, atlanıyor...${NC}"
fi

# Docker Compose kurulumu
if ! command -v docker-compose &> /dev/null; then
    echo -e "${GREEN}[4/9] Docker Compose kuruluyor...${NC}"
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
else
    echo -e "${YELLOW}[4/9] Docker Compose zaten kurulu, atlanıyor...${NC}"
fi

# UFW kurulumu
echo -e "${GREEN}[5/9] UFW (Firewall) kuruluyor...${NC}"
apt install ufw -y

# n8n dizini oluşturma
echo -e "${GREEN}[6/9] n8n dizini oluşturuluyor...${NC}"
mkdir -p /opt/n8n
cd /opt/n8n

# docker-compose.yml oluşturma
echo -e "${GREEN}[7/9] docker-compose.yml dosyası oluşturuluyor...${NC}"
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
      - N8N_SECURE_COOKIE=false
      - N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true
      - N8N_RUNNERS_ENABLED=true
      - N8N_RUNNERS_MODE=internal
      - DB_SQLITE_POOL_SIZE=5
      - N8N_PAYLOAD_SIZE_MAX=100
      - EXECUTIONS_TIMEOUT=300
      - EXECUTIONS_TIMEOUT_MAX=600
      - N8N_DEFAULT_BINARY_DATA_MODE=filesystem
      - WEBHOOK_TIMEOUT=300
      
      # N8N settings (Local IP - HTTP)
      - N8N_HOST=${SERVER_IP}
      - N8N_PORT=5678
      - N8N_PROTOCOL=http
      - NODE_ENV=production
      - N8N_CORS_ORIGIN=*
      - WEBHOOK_URL=http://${SERVER_IP}:5678/
      
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
echo -e "${GREEN}[8/9] n8n başlatılıyor...${NC}"
docker-compose up -d
sleep 10

# Firewall ayarları
echo -e "${GREEN}[9/9] Firewall yapılandırılıyor...${NC}"
ufw --force enable
ufw allow 22/tcp
ufw allow 5678/tcp
ufw reload

# Kurulum tamamlandı
echo ""
echo "=========================================="
echo -e "${GREEN}✓ n8n başarıyla kuruldu!${NC}"
echo "=========================================="
echo ""
echo -e "${GREEN}n8n Erişim Bilgileri:${NC}"
echo "URL: http://${SERVER_IP}:5678"
echo "Kullanıcı adı: ${N8N_USER}"
echo "Şifre: [belirlediğiniz şifre]"
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}📌 Domain ile SSL kurulumu yapmak ister misiniz?${NC}"
echo ""
echo "Domain ile HTTPS erişimi için şu komutu çalıştırın:"
echo -e "${GREEN}wget https://raw.githubusercontent.com/enzifiri/n8n-auto-setup/main/configure-domain.sh${NC}"
echo -e "${GREEN}chmod +x configure-domain.sh${NC}"
echo -e "${GREEN}sudo ./configure-domain.sh${NC}"
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}Yönetim Komutları:${NC}"
echo "Durdurmak: cd /opt/n8n && docker-compose stop"
echo "Başlatmak: cd /opt/n8n && docker-compose start"
echo "Loglar: cd /opt/n8n && docker-compose logs -f"
echo "Güncellemek: cd /opt/n8n && docker-compose pull && docker-compose up -d"
echo ""
