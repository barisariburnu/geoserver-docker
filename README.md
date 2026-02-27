# GeoServer Production Docker Kurulumu

Bu kurulum, yüksek performanslı, production-ready bir GeoServer ortamı sunar.

## 🚀 Özellikler

- **Optimize Edilmiş JVM**: G1GC, string deduplication, optimized heap
- **GeoWebCache**: Tile cache ile hızlı harita servisi
- **Nginx Reverse Proxy**: Cache, rate limiting, load balancing
- **PostgreSQL/PostGIS**: Coğrafi veri depolama
- **GDAL Desteği**: TIFF, ECW ve diğer formatlar
- **Host Erişimi**: Data klasörüne doğrudan erişim
- **Auto-restart**: Container çökmelerinde otomatik yeniden başlatma
- **Health Check**: Container sağlık kontrolü

## 📋 Gereksinimler

- Ubuntu Server 20.04 veya üzeri
- Docker 20.10+
- Docker Compose 1.29+
- En az 8GB RAM (16GB+ önerilir)
- En az 50GB disk alanı

## 🔧 Kurulum

### 1. Sistem Hazırlığı

```bash
# Sistem güncellemesi
sudo apt update && sudo apt upgrade -y

# Docker kurulumu (eğer yoksa)
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Docker Compose kurulumu
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Logout/login yapın veya:
newgrp docker
```

### 2. GeoServer Kurulumu

```bash
# Projeyi yerleştirin
cd /opt  # veya istediğiniz dizin
# Dosyaları buraya kopyalayın

# İzinleri düzenleyin
chmod +x manage.sh setenv.sh

# İlk kurulum
./manage.sh setup

# GeoServer'ı başlatın
./manage.sh start
```

### 3. İlk Erişim

GeoServer başlatıldıktan sonra:

- **Web Arayüzü**: http://sunucu-ip:8080/geoserver
- **Nginx (Proxy)**: http://sunucu-ip
- **Kullanıcı Adı**: admin
- **Şifre**: geoserver

**⚠️ ÖNEMLİ**: İlk girişte şifreyi mutlaka değiştirin!

## 📁 Dizin Yapısı

```
geoserver-setup/
├── docker-compose.yml          # Ana Docker Compose dosyası
├── Dockerfile                  # Custom GeoServer image (Oracle JDBC desteği)
├── nginx.conf                  # Nginx konfigürasyonu
├── manage.sh                   # Yönetim script'i
├── setenv.sh                   # JVM optimizasyon ayarları
├── geoserver_data/            # GeoServer veri dizini (HOST ERİŞİMİ)
├── postgres_data/             # PostgreSQL veri dizini
├── gwc_cache/                 # GeoWebCache dizini
├── logs/                      # GeoServer logları
├── geoserver_extensions/      # Ek eklentiler
├── gdal_data/                 # GDAL veri dosyaları
└── ssl/                       # SSL sertifikaları (opsiyonel)
```

## 🎯 Yönetim Komutları

```bash
# GeoServer'ı başlat
./manage.sh start

# GeoServer'ı durdur
./manage.sh stop

# Yeniden başlat
./manage.sh restart

# Logları görüntüle
./manage.sh logs

# Durum kontrolü
./manage.sh status

# Cache temizle
./manage.sh clear-cache

# Backup oluştur
./manage.sh backup

# Sistem bilgileri
./manage.sh info

# Performans ipuçları
./manage.sh performance
```

## 🔥 TIFF Optimizasyonu

Yüksek boyutlu TIFF dosyaları için:

### 1. Cloud-Optimized GeoTIFF (COG) Oluşturma

```bash
# GDAL ile COG oluşturma
gdal_translate -of GTiff \
  -co TILED=YES \
  -co COMPRESS=LZW \
  -co BIGTIFF=YES \
  -co BLOCKXSIZE=512 \
  -co BLOCKYSIZE=512 \
  input.tif output_cog.tif

# Overviews (piramit) oluşturma
gdaladdo -r average output_cog.tif 2 4 8 16 32 64
```

### 2. GeoServer'da TIFF Katmanı Eklerken

1. **Data** → **Stores** → **Add new Store** → **GeoTIFF**
2. **Connection Parameters**:
   - Use JAI ImageRead: `true`
   - Use Multithreading: `true`
   - Overview Policy: `QUALITY` veya `SPEED`
   - Max Allowed Tiles: `2147483647`

### 3. Coverage Ayarları

Layer yapılandırmasında:

- **Tile Cache**: Etkinleştirin
- **Tile Size**: 256x256 veya 512x512
- **Gridset**: İhtiyacınıza göre (EPSG:4326, EPSG:3857)

## 🗄️ PostgreSQL/PostGIS Kullanımı

### Bağlantı Bilgileri (Container İçinden)

```
Host: postgis
Port: 5432
Database: geoserver
Username: geoserver
Password: geoserver  (ÖNEMLİ: Değiştirin!)
```

### Bağlantı Bilgileri (Host'tan)

```
Host: localhost
Port: 5432
Database: geoserver
Username: geoserver
Password: geoserver
```

### PostGIS Tablo Oluşturma Örneği

```sql
-- Spatial extension etkinleştir (zaten aktif)
CREATE EXTENSION IF NOT EXISTS postgis;

-- Örnek tablo
CREATE TABLE public.my_spatial_data (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255),
    geom GEOMETRY(Point, 4326)
);

-- Spatial index
CREATE INDEX idx_my_spatial_data_geom
ON public.my_spatial_data
USING GIST(geom);

-- Örnek veri
INSERT INTO public.my_spatial_data (name, geom)
VALUES ('Ankara', ST_SetSRID(ST_MakePoint(32.8597, 39.9334), 4326));
```

## 🔌 Eklenti Kurulumu

### Varsayılan Olarak Yüklü Eklentiler

- Vector Tiles
- Charts
- CSS Styling
- MBStyle
- WPS (Web Processing Service)
- Importer
- GDAL/OGR

### Ek Eklenti Yükleme

1. GeoServer eklentisini indirin (sürüm uyumluluğuna dikkat!)
2. JAR dosyalarını `geoserver_extensions/` dizinine kopyalayın
3. GeoServer'ı yeniden başlatın:
   ```bash
   ./manage.sh restart
   ```

### Oracle Eklentisi Kurulumu

Oracle JDBC driver'ları (`ojdbc8`, `orai18n`) **Dockerfile içinde Maven Central'dan otomatik indirilir**. Manuel JAR indirmeye gerek yoktur.

#### 1. Docker Image Oluşturma

```bash
# Image'ı oluşturun (Oracle JARs otomatik indirilir)
./manage.sh rebuild

# Farklı JDBC sürümü kullanmak için:
docker compose build --build-arg ORACLE_JDBC_VERSION=21.9.0.0 geoserver
```

#### 2. Doğrulama

```bash
# Oracle kurulumunu doğrulayın
./manage.sh verify-oracle
```

#### 3. Oracle Store Ekleme

GeoServer web arayüzünden: **Data** → **Stores** → **Add new Store** → **Oracle NG**

Bağlantı parametreleri:

- **host**: Oracle sunucu adresi
- **port**: 1521
- **database**: SID veya Service Name
- **schema**: Şema adı
- **user**: Kullanıcı adı
- **passwd**: Şifre
- **Expose primary keys**: true (önerilir)

Connection pool ayarları:

- **min connections**: 5
- **max connections**: 20
- **validate connections**: true
- **Test while idle**: true

## ⚙️ Performans Optimizasyonu

### 1. JVM Ayarları

`docker-compose.yml` içinde:

```yaml
environment:
  INITIAL_MEMORY: "4G" # Başlangıç heap (RAM'in %25-30'u)
  MAXIMUM_MEMORY: "8G" # Maksimum heap (RAM'in %50-70'i)
```

### 2. GeoServer Global Ayarları

Web arayüzünden: **Settings** → **Global**

- **Number of decimals**: 6
- **Character Set**: UTF-8
- **Proxy Base URL**: http://your-domain.com/geoserver
- **Logging Profile**: PRODUCTION_LOGGING.xml
- **Enable Global Services**: Sadece gerekli servisleri aktifleştirin

### 3. WMS Ayarları

**Settings** → **WMS**:

- **Max rendering memory (KB)**: 524288 (512 MB)
- **Max rendering time (s)**: 60
- **Max rendering errors**: 1000

### 4. Coverage Access Ayarları

**Settings** → **Coverage Access**:

- **Core Pool Size**: 4
- **Max Pool Size**: 8
- **Queue Type**: UNBOUNDED
- **ImageIO Cache Memory Threshold**: 0.75

### 5. GeoWebCache Ayarları

```bash
# GeoWebCache arayüzü
http://sunucu-ip:8080/geoserver/gwc/

# Disk quota ayarlama
# Settings → Tile Caching → Disk Quota
# Disk quota enabled: true
# Maximum disk quota: 10 GB
```

### 6. Database Connection Pool

GeoServer'da PostGIS store oluştururken:

- **min connections**: 5
- **max connections**: 50
- **validate connections**: true
- **Test while idle**: true
- **Max wait**: 10 seconds

## 📊 Monitoring

### GeoServer Metrics

```bash
# JVM metrikleri
curl http://localhost:8080/geoserver/rest/about/system-status.json

# Container metrikleri
docker stats geoserver
```

### Log Görüntüleme

```bash
# Tüm loglar
./manage.sh logs

# Sadece GeoServer
docker logs -f geoserver

# Host üzerinden
tail -f logs/geoserver.log
```

## 🔒 Güvenlik

### 1. Şifreleri Değiştirin

```bash
# docker-compose.yml içinde değiştirin:
# GEOSERVER_ADMIN_PASSWORD: "güçlü-şifre"
# POSTGRES_PASSWORD: "güçlü-şifre"
```

### 2. Firewall Ayarları

```bash
# Sadece gerekli portları açın
sudo ufw allow 80/tcp      # HTTP
sudo ufw allow 443/tcp     # HTTPS
sudo ufw enable
```

### 3. SSL Sertifikası

```bash
# Let's Encrypt ile:
sudo apt install certbot

sudo certbot certonly --standalone -d your-domain.com

# Sertifikaları kopyalayın
sudo cp /etc/letsencrypt/live/your-domain.com/fullchain.pem ssl/cert.pem
sudo cp /etc/letsencrypt/live/your-domain.com/privkey.pem ssl/key.pem

# nginx.conf içindeki HTTPS bloğunu aktifleştirin
# Container'ı yeniden başlatın
```

### 4. Rate Limiting

Nginx konfigürasyonunda:

```nginx
limit_req_zone $binary_remote_addr zone=geoserver_limit:10m rate=100r/s;
```

İhtiyacınıza göre ayarlayın.

## 🔄 Backup ve Restore

### Backup

```bash
# Otomatik backup
./manage.sh backup

# Manuel backup
tar -czf geoserver_backup.tar.gz geoserver_data postgres_data
```

### Restore

```bash
# GeoServer'ı durdurun
./manage.sh stop

# Backup'ı geri yükleyin
tar -xzf geoserver_backup.tar.gz

# GeoServer'ı başlatın
./manage.sh start
```

## 📝 WMS/WFS Örnek İstekler

### GetCapabilities

```
http://localhost:8080/geoserver/wms?service=WMS&version=1.3.0&request=GetCapabilities
```

### GetMap

```
http://localhost:8080/geoserver/wms?
  service=WMS&
  version=1.3.0&
  request=GetMap&
  layers=workspace:layer&
  styles=&
  bbox=minx,miny,maxx,maxy&
  width=768&
  height=512&
  srs=EPSG:4326&
  format=image/png
```

### WFS GetFeature

```
http://localhost:8080/geoserver/wfs?
  service=WFS&
  version=2.0.0&
  request=GetFeature&
  typeName=workspace:layer&
  outputFormat=application/json
```

## 🐛 Sorun Giderme

### Container Başlamıyor

```bash
# Logları kontrol edin
docker logs geoserver

# Port çakışması kontrolü
sudo netstat -tulpn | grep :8080

# Disk alanı kontrolü
df -h
```

### Yavaş Performans

1. JVM memory ayarlarını kontrol edin
2. GeoWebCache cache boyutunu artırın
3. Coverage thread pool ayarlarını optimize edin
4. TIFF dosyalarını COG formatına çevirin
5. Database indekslerini kontrol edin

### TIFF Açılmıyor

1. GDAL kurulumunu kontrol edin
2. JAI ayarlarını kontrol edin
3. TIFF formatını doğrulayın (COG olmalı)
4. Coverage store ayarlarını kontrol edin

## 📚 Kaynaklar

- [GeoServer Documentation](https://docs.geoserver.org/)
- [GeoTools Documentation](https://docs.geotools.org/)
- [PostGIS Documentation](https://postgis.net/documentation/)
- [GDAL Documentation](https://gdal.org/)

## 🤝 Destek

Sorun yaşarsanız:

1. Logları kontrol edin: `./manage.sh logs`
2. Sistem bilgilerini görüntüleyin: `./manage.sh info`
3. GeoServer community forumlarına başvurun

## 📄 Lisans

Bu kurulum scripti MIT lisansı altındadır.
GeoServer ve ilgili bileşenler kendi lisanslarına tabidir.
