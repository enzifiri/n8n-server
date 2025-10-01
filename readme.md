# n8n Otomatik Kurulum Scripti

İki adımda n8n kurun: Önce temel kurulum, sonra domain ekleyin!

## 📋 Gereksinimler

- Debian 12 veya Ubuntu 20.04+
- MobaxTerm → [İndir](https://mobaxterm.mobatek.net/download-home-edition.html)
- **Domain için:** [Namecheap'den domain alın](https://www.namecheap.com/)
- **Server için*** [Netcuptan kirala N8N'yi 20€'ya 6 ay kullan](https://www.netcup.com/en)
- **Netcup indirim kodları** : (SINIRLI SAYIDA)
36nc17592432444 36nc17592432443 36nc17592432442 36nc17592432441 36nc17592432440 36nc17593223300 36nc17593223301 36nc17593223302 36nc17593223303 36nc17593223304 36nc17593223305 36nc17593223306  36nc17593223307 36nc17593223308 36nc17593223309
## 🚀 Adım 1: n8n Kurulumu (Zorunlu)

MobaxTerm ile sunucunuza bağlanın ve şu komutları çalıştırın:

```bash
apt install git ufw -y
sudo ufw --force enable
sudo ufw allow 22/tcp
sudo ufw allow 5678/tcp
git clone https://github.com/enzifiri/n8n-server
cd n8n-server
chmod +x setup.sh
sudo ./setup.sh
```

**Script sizden soracak:**
- n8n kullanıcı adı
- n8n şifresi

**Kurulum sonrası erişim:** `http://SUNUCU_IP:5678`

## 🌐 Adım 2: Domain + SSL Ekleme (Opsiyonel)

Domain ile HTTPS kullanmak istiyorsanız:

### 2.1 DNS Ayarları Yapın

Domain sağlayıcınızın panelinden A kaydı ekleyin:

```
Tip: A Record
Host: @ 
Değer: SUNUCU_IP_ADRESI
TTL: Auto
```
<img width="1189" height="145" alt="image" src="https://github.com/user-attachments/assets/1c4ad3de-ea43-4227-9c20-3390613c1124" />

### 2.2 DNS Kontrolü

[dnschecker.org](https://dnschecker.org) adresinde domain'inizi kontrol edin.

✅ **Yeşil tik ve sunucu IP'niz görünüyorsa** → Domain yapılandırmasına geçebilirsiniz  
❌ **Kırmızı X görünüyorsa** → 30-60 dakika bekleyin

<img width="583" height="199" alt="image" src="https://github.com/user-attachments/assets/e2c87d13-1f9a-4fba-b073-af6eb6a0ebe3" />


### 2.3 Domain Scriptini Çalıştırın

```bash
cd n8n-server
chmod +x configure-domain.sh
sudo ./configure-domain.sh
```

**Script sizden soracak:**
- Domain adınız
- Email adresiniz (SSL için)

**Kurulum sonrası erişim:** `https://yourdomain.com`

## 📊 Hangi Kurulum Bana Uygun?

| Durum | Kurulum |
|-------|---------|
| Sadece test yapmak istiyorum | Sadece Adım 1 |
| Hızlıca denemek istiyorum | Sadece Adım 1 |
| Production kullanacağım | Adım 1 + Adım 2 |
| SSL/HTTPS istiyorum | Adım 1 + Adım 2 |

## 🔧 Yönetim Komutları

```bash
# Durdurmak
cd /opt/n8n && docker-compose stop

# Başlatmak
cd /opt/n8n && docker-compose start

# Yeniden başlatmak
cd /opt/n8n && docker-compose restart

# Logları görüntülemek
cd /opt/n8n && docker-compose logs -f

# Güncellemek
cd /opt/n8n && docker-compose pull && docker-compose up -d

# Durum kontrolü
docker ps
```

## 🐛 Sorun Giderme

### Adım 1 Sorunları (n8n Kurulumu)

**Container başlamıyor:**
```bash
cd /opt/n8n
docker-compose logs
```

**Port 5678'e erişilemiyor:**
```bash
sudo ufw status
sudo ufw allow 5678/tcp
```

### Adım 2 Sorunları (Domain + SSL)

**DNS hatası:**
```bash
# DNS kontrolü
dig +short yourdomain.com

# Bekleme süresi: 30-60 dakika
```

**SSL sertifika hatası:**
```bash
# Portları kontrol edin
sudo ufw status
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Manuel SSL denemesi
sudo certbot --nginx -d yourdomain.com
```

**Nginx hatası:**
```bash
sudo systemctl status nginx
sudo nginx -t
```

## 📚 Faydalı Linkler

- [n8n Dokümantasyonu](https://docs.n8n.io/)
- [n8n Community](https://community.n8n.io/)

## 📄 Lisans

MIT License

---

**⭐ Beğendiyseniz yıldız vermeyi unutmayın!**
