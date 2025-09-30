# n8n Otomatik Kurulum Scripti

Tek komutla n8n'i Docker, Nginx reverse proxy ve SSL sertifikası ile birlikte kurun!

## 🚀 Özellikler

- ✅ Docker ve Docker Compose otomatik kurulumu
- ✅ n8n son sürümü kurulumu
- ✅ Nginx reverse proxy yapılandırması
- ✅ Let's Encrypt SSL sertifikası (ücretsiz HTTPS)
- ✅ Otomatik firewall yapılandırması
- ✅ Production-ready ayarlar
- ✅ Tek komutla kurulum

## 📋 Gereksinimler

- Debian 12 (veya Ubuntu 20.04+)
- Root veya sudo yetkisi
- Bir domain adı (örn: example.com)
- Domain'in DNS A kaydı sunucunuza yönlendirilmiş olmalı

## ⚡ Hızlı Kurulum

```bash
wget https://raw.githubusercontent.com/enzifiri/n8n-auto-setup/main/setup.sh
chmod +x setup.sh
sudo ./setup.sh
```

## 📝 Script Ne Yapar?

1. **Sistem Güncellemesi** - Tüm paketleri günceller
2. **Docker Kurulumu** - Docker ve Docker Compose'u kurar
3. **Nginx Kurulumu** - Nginx web sunucusunu kurar
4. **Certbot Kurulumu** - SSL sertifikası için Let's Encrypt aracını kurar
5. **n8n Dizini** - `/opt/n8n` dizinini oluşturur
6. **Docker Compose Yapılandırması** - Girdiğiniz bilgilerle `docker-compose.yml` oluşturur
7. **n8n Başlatma** - n8n container'ını başlatır
8. **Nginx Yapılandırması** - Reverse proxy ayarlarını yapar
9. **SSL Sertifikası** - Otomatik olarak SSL sertifikası alır ve yapılandırır
10. **Firewall** - Gerekli portları açar (80, 443, 22)

## 🎯 Kullanım

Script çalıştırıldığında sizden şu bilgileri isteyecek:

- **Domain adınız**: Örn: `kedileriseverizki.xyz`
- **n8n kullanıcı adı**: Örn: `admin`
- **n8n şifresi**: Güçlü bir şifre girin
- **Email adresiniz**: SSL sertifikası için

### Örnek Kullanım

```bash
sudo ./setup.sh

# Script çıktısı:
==========================================
n8n Docker + SSL Kurulum Scripti
==========================================

Lütfen aşağıdaki bilgileri girin:
Domain adınız (örn: kedileriseverizki.xyz): kedileriseverizki.xyz
n8n kullanıcı adı (örn: admin): admin
n8n şifresi: ********
Email adresiniz (SSL sertifikası için): user@example.com

Girilen bilgiler:
Domain: kedileriseverizki.xyz
Kullanıcı: admin
Email: user@example.com

Devam etmek istiyor musunuz? (y/n): y
```

## ✅ Kurulum Tamamlandıktan Sonra

Kurulum başarıyla tamamlandığında şu bilgileri göreceksiniz:

```
==========================================
✓ Kurulum başarıyla tamamlandı!
==========================================

n8n Bilgileri:
URL: https://kedileriseverizki.xyz
Kullanıcı adı: admin
Şifre: [belirlediğiniz şifre]

Yönetim Komutları:
Durdurmak: cd /opt/n8n && docker-compose stop
Başlatmak: cd /opt/n8n && docker-compose start
Loglar: cd /opt/n8n && docker-compose logs -f
Güncellemek: cd /opt/n8n && docker-compose pull && docker-compose up -d

Tarayıcınızda https://kedileriseverizki.xyz adresine gidebilirsiniz!
```

## 🔧 Yönetim Komutları

### n8n'i Durdurmak
```bash
cd /opt/n8n
docker-compose stop
```

### n8n'i Başlatmak
```bash
cd /opt/n8n
docker-compose start
```

### n8n'i Yeniden Başlatmak
```bash
cd /opt/n8n
docker-compose restart
```

### Logları Görüntülemek
```bash
cd /opt/n8n
docker-compose logs -f
```

### n8n'i Güncellemek
```bash
cd /opt/n8n
docker-compose pull
docker-compose up -d
```

### Durumu Kontrol Etmek
```bash
docker ps
systemctl status nginx
```

## 🔒 Güvenlik

Script otomatik olarak şunları yapar:

- ✅ HTTPS/SSL aktif eder (Let's Encrypt)
- ✅ Basic Authentication aktif eder
- ✅ Firewall kuralları ekler
- ✅ Güvenli cookie ayarları
- ✅ Production mode aktif eder

## 🌍 DNS Ayarları

Script çalıştırmadan **önce** domain'inizin DNS ayarlarında A kaydını sunucunuzun IP'sine yönlendirin:

```
Tip: A
Host: @ (veya subdomain)
Değer: SUNUCU_IP_ADRESI
TTL: 3600 (veya otomatik)
```

DNS kontrolü:
```bash
dig kedileriseverizki.xyz
# veya
nslookup kedileriseverizki.xyz
```

## 🐛 Sorun Giderme

### "DNS validation failed" hatası

Domain'inizin DNS ayarlarının yayılması için 5-10 dakika bekleyin.

```bash
# DNS kontrolü
dig +short kedileriseverizki.xyz
```

### n8n container'ı başlamıyor

```bash
cd /opt/n8n
docker-compose logs
```

### SSL sertifikası alınamadı

1. Port 80 ve 443'ün açık olduğundan emin olun
2. Nginx'in çalıştığını kontrol edin: `systemctl status nginx`
3. Manuel olarak tekrar deneyin:
```bash
sudo certbot --nginx -d kedileriseverizki.xyz
```

### Firewall sorunları

```bash
# Firewall durumunu kontrol et
sudo ufw status

# Gerekli portları aç
sudo ufw allow 'Nginx Full'
sudo ufw allow 22/tcp
sudo ufw enable
```

## 📦 Script Tarafından Oluşturulan Dosyalar

```
/opt/n8n/
├── docker-compose.yml          # n8n yapılandırması

/etc/nginx/sites-available/
└── n8n                          # Nginx yapılandırması

/etc/letsencrypt/
└── live/kedileriseverizki.xyz/ # SSL sertifikaları
```

## 🔄 n8n Yedekleme

### Yedek Alma

```bash
# Docker volume'ü yedekle
docker run --rm \
  -v n8n_n8n_data:/data \
  -v $(pwd):/backup \
  ubuntu tar czf /backup/n8n-backup-$(date +%Y%m%d).tar.gz /data
```

### Yedekten Geri Yükleme

```bash
# Container'ı durdur
cd /opt/n8n
docker-compose down

# Yedekten geri yükle
docker run --rm \
  -v n8n_n8n_data:/data \
  -v $(pwd):/backup \
  ubuntu tar xzf /backup/n8n-backup-YYYYMMDD.tar.gz -C /

# Container'ı başlat
docker-compose up -d
```

## 🎨 Özelleştirme

Script çalıştıktan sonra `/opt/n8n/docker-compose.yml` dosyasını düzenleyerek özelleştirmeler yapabilirsiniz:

```bash
cd /opt/n8n
nano docker-compose.yml
docker-compose up -d
```

## 📚 Kaynaklar

- [n8n Resmi Dokümantasyonu](https://docs.n8n.io/)
- [Docker Dokümantasyonu](https://docs.docker.com/)
- [Let's Encrypt Dokümantasyonu](https://letsencrypt.org/docs/)
- [Nginx Dokümantasyonu](https://nginx.org/en/docs/)

## 🤝 Katkıda Bulunma

Pull request'ler memnuniyetle karşılanır! Büyük değişiklikler için lütfen önce bir issue açın.

## 📄 Lisans

MIT License

## ⭐ Destek

Bu script işinize yaradıysa GitHub'da yıldız vermeyi unutmayın!

---

**Not:** Bu script Debian 12 ve Ubuntu 20.04+ için test edilmiştir. Diğer dağıtımlarda küçük değişiklikler gerekebilir.
