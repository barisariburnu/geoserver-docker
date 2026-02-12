# GeoServer - Hızlı Başlangıç Rehberi

## 🚀 5 Dakikada Kurulum

### 1. Ön Gereksinimler

```bash
# Docker ve Docker Compose kurulu mu kontrol edin
docker --version
docker-compose --version

# Eğer kurulu değilse:
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
newgrp docker
```

### 2. Dosyaları Yerleştirin

```bash
# Tüm dosyaları /opt/geoserver-setup dizinine kopyalayın
cd /opt/geoserver-setup

# Executable izinleri verin
chmod +x manage.sh optimize_tiff.sh setenv.sh
```

### 3. Konfigürasyon

```bash
# .env dosyası oluşturun
cp .env.example .env

# Şifreleri düzenleyin (ÖNEMLİ!)
nano .env
```

Değiştirmeniz gerekenler:
- `GEOSERVER_ADMIN_PASSWORD`
- `POSTGRES_PASSWORD`

### 4. Başlatın!

```bash
# İlk kurulum
./manage.sh setup

# GeoServer'ı başlatın
./manage.sh start

# Logları takip edin
./manage.sh logs
```

### 5. Erişim

**3-5 dakika bekleyin** (ilk başlatma biraz zaman alır)

- **GeoServer**: http://your-server:8080/geoserver
- **Kullanıcı**: admin
- **Şifre**: .env dosyasında belirlediğiniz şifre

## 📊 İlk Adımlar

### PostGIS Store Ekleme

1. **Data** → **Stores** → **Add new Store** → **PostGIS**
2. Bağlantı bilgileri:
   ```
   Host: postgis
   Port: 5432
   Database: geoserver
   User: geoserver
   Password: .env dosyasındaki şifre
   ```

### TIFF Layer Ekleme

1. TIFF dosyanızı optimize edin:
   ```bash
   ./optimize_tiff.sh /path/to/large.tif /path/to/optimized.tif
   ```

2. Optimized TIFF'i `geoserver_data/data/` dizinine kopyalayın

3. **Data** → **Stores** → **Add new Store** → **GeoTIFF**
4. **Connection Parameters**:
   - URL: `file:data/optimized.tif`
   - Use JAI ImageRead: ✓

### GeoWebCache Etkinleştirme

1. Layer'ı seçin → **Tile Caching** sekmesi
2. **Create a cached layer for this layer**: ✓
3. Gridsets seçin (EPSG:4326, EPSG:3857)
4. **Save**

## 🔧 Sık Kullanılan Komutlar

```bash
# Durum kontrolü
./manage.sh status

# Yeniden başlat
./manage.sh restart

# Logları görüntüle
./manage.sh logs

# Cache temizle
./manage.sh clear-cache

# Backup oluştur
./manage.sh backup

# Performans ipuçları
./manage.sh performance
```

## ⚡ Performans Kontrol Listesi

- [ ] JVM memory ayarları yapıldı (docker-compose.yml)
- [ ] TIFF dosyaları COG formatına çevrildi
- [ ] GeoWebCache etkinleştirildi
- [ ] Nginx cache ayarları kontrol edildi
- [ ] PostGIS indeksleri oluşturuldu
- [ ] Firewall kuralları ayarlandı
- [ ] SSL sertifikası yüklendi (production için)

## 🆘 Sorun mu var?

```bash
# Container çalışıyor mu?
docker ps

# Son 100 log satırı
docker logs --tail 100 geoserver

# Sistem kaynakları
docker stats

# Port dinleniyor mu?
sudo netstat -tulpn | grep 8080
```

## 📚 Sonraki Adımlar

1. **README.md** dosyasını okuyun (detaylı bilgi)
2. GeoServer güvenlik ayarlarını yapın
3. Monitoring kurulumunu yapın (opsiyonel)
4. Sistemik backup planı oluşturun
5. Performans testleri yapın

---

**İyi çalışmalar!** 🗺️
