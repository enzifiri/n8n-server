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
dig example.xyz
# veya
nslookup example.xyz
```
## ⚡ Hızlı Kurulum

```bash
sudo ufw allow 'Nginx Full'
sudo ufw allow 22/tcp
sudo ufw allow 80
sudo ufw allow 443
sudo ufw enable
wget https://raw.githubusercontent.com/enzifiri/n8n-auto-setup/main/setup.sh
chmod +x setup.sh
sudo ./setup.sh
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


## 📄 Lisans

MIT License

## ⭐ Destek

Bu script işinize yaradıysa GitHub'da yıldız vermeyi unutmayın!

---

**Not:** Bu script Debian 12 ve Ubuntu 20.04+ için test edilmiştir. Diğer dağıtımlarda küçük değişiklikler gerekebilir.
