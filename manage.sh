#!/bin/bash

# GeoServer Yönetim Script'i
# Bu script ile GeoServer'ı kolayca yönetebilirsiniz

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Renkli output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Gerekli dizinleri oluştur
setup_directories() {
    print_info "Dizinler oluşturuluyor..."
    
    mkdir -p geoserver_data
    mkdir -p postgres_data
    mkdir -p gwc_cache
    mkdir -p logs
    mkdir -p geoserver_extensions
    mkdir -p gdal_data
    mkdir -p ssl
    
    # Setenv.sh için executable yetkisi
    chmod +x setenv.sh 2>/dev/null || true
    
    print_info "Dizinler başarıyla oluşturuldu!"
}

# GeoServer başlat
start_geoserver() {
    print_info "GeoServer başlatılıyor..."
    docker-compose up -d
    
    print_info "GeoServer başlatıldı. Loglara bakmak için: docker-compose logs -f geoserver"
    print_info "GeoServer web arayüzü: http://localhost:8080/geoserver"
    print_info "Varsayılan kullanıcı adı: admin"
    print_info "Varsayılan şifre: geoserver (ÖNEMLİ: Değiştirin!)"
}

# GeoServer durdur
stop_geoserver() {
    print_info "GeoServer durduruluyor..."
    docker-compose down
    print_info "GeoServer durduruldu!"
}

# GeoServer yeniden başlat
restart_geoserver() {
    print_info "GeoServer yeniden başlatılıyor..."
    docker-compose restart
    print_info "GeoServer yeniden başlatıldı!"
}

# Logları göster
show_logs() {
    docker-compose logs -f geoserver
}

# GeoServer durumunu göster
status_geoserver() {
    docker-compose ps
}

# Cache temizle
clear_cache() {
    print_warning "GeoWebCache temizleniyor..."
    
    if [ -d "gwc_cache" ]; then
        read -p "GeoWebCache cache'i temizlensin mi? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf gwc_cache/*
            print_info "Cache temizlendi!"
        fi
    fi
}

# Backup oluştur
backup_data() {
    BACKUP_DIR="backups"
    BACKUP_NAME="geoserver_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
    
    print_info "Backup oluşturuluyor..."
    
    mkdir -p "$BACKUP_DIR"
    
    tar -czf "$BACKUP_DIR/$BACKUP_NAME" \
        geoserver_data \
        postgres_data \
        2>/dev/null || true
    
    print_info "Backup oluşturuldu: $BACKUP_DIR/$BACKUP_NAME"
}

# Extension yükle
install_extension() {
    if [ -z "$1" ]; then
        print_error "Extension adı belirtilmedi!"
        print_info "Kullanım: $0 install-extension <extension_name>"
        exit 1
    fi
    
    print_info "Extension yükleniyor: $1"
    print_warning "Extension dosyalarını geoserver_extensions/ dizinine manuel olarak kopyalamanız gerekiyor."
    print_info "GeoServer'ı yeniden başlatmayı unutmayın: $0 restart"
}

# Sistem bilgilerini göster
show_info() {
    print_info "GeoServer Sistem Bilgileri"
    echo "================================"
    echo "GeoServer Data Dizini: $(pwd)/geoserver_data"
    echo "PostgreSQL Data Dizini: $(pwd)/postgres_data"
    echo "GeoWebCache Dizini: $(pwd)/gwc_cache"
    echo "Loglar: $(pwd)/logs"
    echo "Extensions: $(pwd)/geoserver_extensions"
    echo ""
    echo "Container Durumu:"
    docker-compose ps
    echo ""
    echo "Disk Kullanımı:"
    du -sh geoserver_data postgres_data gwc_cache 2>/dev/null || echo "Henüz veri yok"
}

# Performans ayarlarını göster
show_performance_tips() {
    cat << 'EOF'
================================
GeoServer Performans İpuçları
================================

1. TIFF Optimizasyonu:
   - GeoTIFF dosyalarınızı cloud-optimized (COG) formatına dönüştürün
   - Komut: gdal_translate -co TILED=YES -co COMPRESS=LZW -co BIGTIFF=YES input.tif output_cog.tif

2. JVM Ayarları:
   - docker-compose.yml dosyasındaki INITIAL_MEMORY ve MAXIMUM_MEMORY değerlerini sisteminize göre ayarlayın
   - Önerilen: Toplam RAM'in %50-70'i

3. GeoWebCache:
   - Sık kullanılan katmanlar için tile cache oluşturun
   - Gridset'leri ihtiyacınıza göre optimize edin

4. Database İndeksleri:
   - PostGIS tablolarınızda spatial index oluşturun
   - VACUUM ve ANALYZE komutlarını düzenli çalıştırın

5. Nginx Cache:
   - WMS istekleri için cache süresini ayarlayın
   - Static dosyalar için uzun süreli cache kullanın

6. Monitoring:
   - GeoServer monitoring extension'ı yükleyin
   - Prometheus + Grafana ile metrikleri izleyin

7. Connection Pooling:
   - PostGIS connection pool ayarlarını optimize edin
   - Max connections: 50-100 arası

EOF
}

# Oracle kurulum talimatları
show_oracle_setup() {
    cat << 'EOF'
================================
Oracle Desteği Kurulum
================================

Oracle JDBC driver'ı lisans kısıtlamaları nedeniyle otomatik olarak yüklenemez.
Manuel olarak yüklemeniz gerekiyor:

1. Oracle JDBC driver'ı indirin:
   https://www.oracle.com/database/technologies/jdbc-downloads.html
   
2. ojdbc8.jar dosyasını şu dizine kopyalayın:
   ./geoserver_extensions/
   
3. GeoServer'ı yeniden başlatın:
   ./manage.sh restart

4. GeoServer web arayüzünden Oracle datastore ekleyin.

EOF
}

# ECW kurulum talimatları
show_ecw_setup() {
    cat << 'EOF'
================================
ECW (ERDAS Compressed Wavelet) Desteği
================================

ECW desteği için GDAL ECW plugin gereklidir:

1. GDAL ECW plugin'i yükleyin (lisans gerektirir)
2. Dockerfile'ı özelleştirmeniz gerekebilir
3. Alternatif: ECW dosyalarını GeoTIFF'e dönüştürün:
   
   gdal_translate -of GTiff input.ecw output.tif

Not: ECW yerine açık kaynak alternatifler (GeoTIFF, JPEG2000) kullanmanız önerilir.

EOF
}

# Ana menü
show_menu() {
    cat << 'EOF'
================================
GeoServer Yönetim Script'i
================================
Komutlar:
  setup         - İlk kurulum (dizinleri oluştur)
  start         - GeoServer'ı başlat
  stop          - GeoServer'ı durdur
  restart       - GeoServer'ı yeniden başlat
  logs          - Logları göster
  status        - Durum bilgisi
  clear-cache   - GeoWebCache temizle
  backup        - Veri yedekle
  info          - Sistem bilgileri
  performance   - Performans ipuçları
  oracle        - Oracle kurulum talimatları
  ecw           - ECW kurulum talimatları
  
Kullanım: ./manage.sh [komut]
EOF
}

# Ana kontrol
case "${1:-}" in
    setup)
        setup_directories
        ;;
    start)
        setup_directories
        start_geoserver
        ;;
    stop)
        stop_geoserver
        ;;
    restart)
        restart_geoserver
        ;;
    logs)
        show_logs
        ;;
    status)
        status_geoserver
        ;;
    clear-cache)
        clear_cache
        ;;
    backup)
        backup_data
        ;;
    info)
        show_info
        ;;
    performance)
        show_performance_tips
        ;;
    oracle)
        show_oracle_setup
        ;;
    ecw)
        show_ecw_setup
        ;;
    *)
        show_menu
        exit 1
        ;;
esac
