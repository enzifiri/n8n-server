
# n8n Docker Kurulum Rehberi (Debian 12)

Bu repo, Debian 12/ Ubuntu 22.04 24.04 sunucunuza Docker kullanarak n8n kurulumu için adım adım talimatlar içerir.

## Gereksinimler

- Debian 12 / Ubuntu 22,24 sunucu
- Root veya sudo yetkisi
- Mobaxterm (SSH Uygulaması)
https://mobaxterm.mobatek.net/download-home-edition.html

## Kurulum Adımları

### 1. Sistemi Güncelleyin

```bash
sudo apt update && sudo apt upgrade -y
```

### 2. Docker Kurulumu

Gerekli paketleri yükleyin:

```bash
sudo apt install apt-transport-https ca-certificates curl gnupg lsb-release -y
```

Docker'ın GPG anahtarını ekleyin:

```bash
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
```

Docker repository'sini ekleyin:

```bash
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

Docker'ı yükleyin:

```bash
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io -y
```

Docker servisini başlatın ve aktif edin:

```bash
sudo systemctl start docker
sudo systemctl enable docker
```

Docker kurulumunu kontrol edin:

```bash
docker --version
```

### 3. Docker Compose Kurulumu

```bash
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

Kurulumu kontrol edin:

```bash
docker-compose --version
```

### 4. n8n İçin Dizin Oluşturma

```bash
mkdir -p ~/.n8n
cd ~/.n8n
```

### 5. Docker Compose Dosyası Oluşturma

```bash
nano docker-compose.yml
```

Aşağıdaki içeriği yapıştırın:

```yaml
version: '3.8'

services:
  n8n:
    image: n8nio/n8n
    container_name: n8n
    restart: unless-stopped
    ports:
      - "5678:5678"
    environment:
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=skooldoa
      - N8N_BASIC_AUTH_PASSWORD=asd123asd
      - N8N_HOST=localhost
      - N8N_PORT=5678
      - N8N_PROTOCOL=http
      - WEBHOOK_URL=http://localhost:5678/
      - GENERIC_TIMEZONE=Europe/Istanbul
      - TZ=Europe/Istanbul
    volumes:
      - /root/.n8n:/home/node/.n8n
```

**Önemli:** `N8N_BASIC_AUTH_PASSWORD` değerini mutlaka güçlü bir şifre ile değiştirin!

Dosyayı kaydedin (CTRL+X, sonra Y, sonra Enter).

### 7. n8n'i Başlatın

```bash
docker-compose up -d
```

### 8. Kontrol

Container'ın çalıştığını kontrol edin:

```bash
docker ps
```

Logları görüntüleyin:

```bash
docker-compose logs -f
```

### 9. n8n'e Erişim

Tarayıcınızda şu adresi açın:

```
http://SUNUCU_IP_ADRESINIZ:5678
```

**Giriş Bilgileri:**
- Kullanıcı adı: `admin`
- Şifre: `docker-compose.yml` dosyasında belirlediğiniz şifre

## Yönetim Komutları

### n8n'i Durdurmak

```bash
docker-compose stop
```

### n8n'i Başlatmak

```bash
docker-compose start
```

### n8n'i Yeniden Başlatmak

```bash
docker-compose restart
```

### n8n'i Tamamen Kaldırmak

```bash
docker-compose down
```

Container'ı ve volume'leri tamamen silmek için:

```bash
docker-compose down -v
```

### Logları Görüntülemek

```bash
docker-compose logs -f
```

### n8n'i Güncellemek

```bash
docker-compose pull
docker-compose up -d
```
