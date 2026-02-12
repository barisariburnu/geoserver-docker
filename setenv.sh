#!/bin/bash
# GeoServer JVM Optimization Script
# Bu dosyayı geoserver container'ına mount ederek JVM ayarlarını özelleştirebilirsiniz

export JAVA_OPTS="\
-server \
-Xms4g \
-Xmx8g \
-XX:+UseG1GC \
-XX:MaxGCPauseMillis=200 \
-XX:ParallelGCThreads=4 \
-XX:ConcGCThreads=2 \
-XX:+UseStringDeduplication \
-XX:+OptimizeStringConcat \
-XX:+UseCompressedOops \
-XX:+UseCompressedClassPointers \
-XX:ReservedCodeCacheSize=256m \
-XX:InitialCodeCacheSize=128m \
-Djava.awt.headless=true \
-Dfile.encoding=UTF-8 \
-Djavax.servlet.request.encoding=UTF-8 \
-Djavax.servlet.response.encoding=UTF-8 \
-Duser.timezone=Europe/Istanbul \
-Djava.io.tmpdir=/tmp \
-DGEOSERVER_DATA_DIR=/opt/geoserver/data_dir \
-DGEOSERVER_LOG_LOCATION=/opt/geoserver/data_dir/logs/geoserver.log \
-DGEOWEBCACHE_CACHE_DIR=/opt/geoserver/data_dir/gwc \
-Dorg.geotools.shapefile.datetime=true \
-Dorg.geotools.referencing.forceXY=true \
-Dorg.geotools.coverage.max.executor.threads=8 \
-Dorg.geotools.coverage.max.queue.size=100000 \
-DENABLE_JSONP=true \
-DGWCTruncateEmptyTiles=true \
-Dorg.geoserver.wfs.xml.encode.canonical=false \
"

# JAI Ayarları
export JAI_OPTS="\
-Dcom.sun.media.jai.disableMediaLib=true \
-Djava.awt.headless=true \
-Djavax.media.jai.tilecache.size=512 \
-Djavax.media.jai.memory.threshold=0.75 \
-Djavax.media.jai.tilethreads=7 \
-Djavax.media.jai.recycling=true \
"

# GDAL Ayarları
export GDAL_OPTS="\
-DGDAL_DATA=/usr/share/gdal \
-DGDAL_CACHEMAX=512 \
-DCPL_TMPDIR=/tmp \
-DGDAL_DISABLE_READDIR_ON_OPEN=YES \
-DGDAL_HTTP_MERGE_CONSECUTIVE_RANGES=YES \
-DVSI_CACHE=TRUE \
-DVSI_CACHE_SIZE=50000000 \
-DCPL_VSIL_CURL_ALLOWED_EXTENSIONS=.tif,.tiff,.vrt,.xml,.ovr \
"

# Tüm ayarları birleştir
export CATALINA_OPTS="$JAVA_OPTS $JAI_OPTS $GDAL_OPTS"

echo "GeoServer JVM Options configured:"
echo "$CATALINA_OPTS"
