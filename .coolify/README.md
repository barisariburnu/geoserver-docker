# Coolify Git Deployment Yapılandırması

Kaynak: GitHub `main`. Build Pack: Docker Compose; Base Directory `/`; Compose Location `/.coolify/compose.yaml`; Raw Compose açık. Depoya gerçek ortam değerleri eklenmez. Host yolları, volume adları ve alan adları Coolify ortam değişkenlerinden alınır. External volume ve ağ adları mevcut kaynaklara işaret etmelidir.

Yalnız kaynak kod image içine alınır. Kalıcı veri, yükleme, arşiv ve TLS alanları mevcut host yolları veya external volume’larla korunur. Veritabanı image’ları sabittir; yeniden başlatma yeni bir veritabanı oluşturmaz. Veri dizinlerini veya volume’ları silen komut kullanılmamalıdır.

Zamanlanmış veri işlerinde build tamamlandıktan sonra çalışan işin doğal olarak bitmesi beklenir; zorla SIGKILL gönderilmez. İlk legacy cron geçişi aktif iş varsa durdurulmadan ertelenir. Coolify sunucu deployment timeout değeri uzun veri işlerine uygun olmalıdır. Başarısız deployment kayıtları kontrol edilmeli ve gerekirse aynı commit yeniden yayına alınmalıdır. Zamanlayıcının normal yeniden başlatma davranışı değiştirilmez; iş mantığına yeni migration/senkronizasyon komutu eklenmez.
