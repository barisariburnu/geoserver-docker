#!/bin/bash

# GeoTIFF Optimizasyon Script'i
# Yüksek boyutlu TIFF dosyalarını Cloud-Optimized GeoTIFF'e dönüştürür

set -e

# Renkler
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# GDAL kontrolü
if ! command -v gdal_translate &> /dev/null; then
    print_error "GDAL bulunamadı! Lütfen GDAL'ı yükleyin:"
    echo "  Ubuntu: sudo apt install gdal-bin"
    echo "  macOS: brew install gdal"
    exit 1
fi

# Kullanım bilgisi
usage() {
    cat << EOF
TIFF Optimizasyon Script'i

Kullanım:
  $0 <input.tif> [output.tif]
  $0 --batch <input_directory> <output_directory>

Örnekler:
  # Tek dosya
  $0 large_image.tif optimized.tif
  
  # Dizin (batch)
  $0 --batch /path/to/tiffs /path/to/output

Seçenekler:
  --help        Bu yardım mesajını göster
  --batch       Toplu işlem modu
  --compression Sıkıştırma tipi (LZW, DEFLATE, JPEG, NONE) - Varsayılan: LZW
  --quality     JPEG kalitesi (1-100) - Varsayılan: 85

EOF
    exit 1
}

# Tek dosya optimizasyonu
optimize_tiff() {
    local input="$1"
    local output="$2"
    local compression="${3:-LZW}"
    local quality="${4:-85}"
    
    if [ ! -f "$input" ]; then
        print_error "Dosya bulunamadı: $input"
        return 1
    fi
    
    print_info "Optimizasyon başlıyor: $input"
    
    # Geçici dosya
    local temp_file="${output}.tmp.tif"
    
    # Cloud-Optimized GeoTIFF oluştur
    if [ "$compression" = "JPEG" ]; then
        gdal_translate \
            -of GTiff \
            -co TILED=YES \
            -co COMPRESS=JPEG \
            -co JPEG_QUALITY=$quality \
            -co PHOTOMETRIC=YCBCR \
            -co BIGTIFF=IF_SAFER \
            -co BLOCKXSIZE=512 \
            -co BLOCKYSIZE=512 \
            -co NUM_THREADS=ALL_CPUS \
            "$input" "$temp_file"
    else
        gdal_translate \
            -of GTiff \
            -co TILED=YES \
            -co COMPRESS=$compression \
            -co BIGTIFF=IF_SAFER \
            -co BLOCKXSIZE=512 \
            -co BLOCKYSIZE=512 \
            -co NUM_THREADS=ALL_CPUS \
            "$input" "$temp_file"
    fi
    
    # Overviews (piramit) ekle
    print_info "Overviews oluşturuluyor..."
    gdaladdo \
        -r average \
        --config COMPRESS_OVERVIEW $compression \
        --config BIGTIFF_OVERVIEW IF_SAFER \
        --config NUM_THREADS ALL_CPUS \
        "$temp_file" \
        2 4 8 16 32 64 128
    
    # COG validate (eğer varsa)
    if command -v rio &> /dev/null; then
        print_info "COG doğrulaması yapılıyor..."
        rio cogeo validate "$temp_file" || print_warning "COG validation başarısız"
    fi
    
    # Geçici dosyayı çıktıya taşı
    mv "$temp_file" "$output"
    
    # Boyut karşılaştırması
    local input_size=$(du -h "$input" | cut -f1)
    local output_size=$(du -h "$output" | cut -f1)
    
    print_info "✓ Tamamlandı!"
    echo "  Input:  $input_size"
    echo "  Output: $output_size"
    echo "  Dosya:  $output"
}

# Toplu optimizasyon
batch_optimize() {
    local input_dir="$1"
    local output_dir="$2"
    local compression="${3:-LZW}"
    local quality="${4:-85}"
    
    if [ ! -d "$input_dir" ]; then
        print_error "Input dizini bulunamadı: $input_dir"
        exit 1
    fi
    
    mkdir -p "$output_dir"
    
    print_info "Toplu optimizasyon başlıyor..."
    print_info "Input:  $input_dir"
    print_info "Output: $output_dir"
    
    local count=0
    local success=0
    local failed=0
    
    # TIFF dosyalarını bul ve işle
    while IFS= read -r -d '' file; do
        count=$((count + 1))
        local basename=$(basename "$file")
        local output_file="$output_dir/${basename%.tif}_cog.tif"
        
        print_info "[$count] İşleniyor: $basename"
        
        if optimize_tiff "$file" "$output_file" "$compression" "$quality"; then
            success=$((success + 1))
        else
            failed=$((failed + 1))
        fi
        
    done < <(find "$input_dir" -type f \( -iname "*.tif" -o -iname "*.tiff" \) -print0)
    
    print_info "===================="
    print_info "Toplu işlem tamamlandı!"
    echo "  Toplam:   $count"
    echo "  Başarılı: $success"
    echo "  Başarısız: $failed"
}

# Ana kontrol
COMPRESSION="LZW"
QUALITY=85

case "${1:-}" in
    --help|-h)
        usage
        ;;
    --batch)
        if [ -z "$2" ] || [ -z "$3" ]; then
            print_error "Batch mod için input ve output dizinleri gerekli!"
            usage
        fi
        batch_optimize "$2" "$3" "$COMPRESSION" "$QUALITY"
        ;;
    "")
        usage
        ;;
    *)
        input="$1"
        output="${2:-${input%.tif}_cog.tif}"
        optimize_tiff "$input" "$output" "$COMPRESSION" "$QUALITY"
        ;;
esac
