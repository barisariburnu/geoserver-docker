FROM kartoza/geoserver:2.28.2

LABEL maintainer="barisariburnu"
LABEL description="GeoServer with Oracle Spatial/Locator support"

# Oracle i18n desteğini ekle (WE8ISO8859P9 gibi karakter setleri için gerekli)
# Not: ojdbc17 zaten base image'da mevcut (v23.7.0.25.01)
ARG ORACLE_NLS_VERSION=23.7.0.25.01
ARG GEOSERVER_LIB_DIR=/usr/local/tomcat/webapps/geoserver/WEB-INF/lib

RUN curl -fSL -o ${GEOSERVER_LIB_DIR}/orai18n-${ORACLE_NLS_VERSION}.jar \
    "https://repo1.maven.org/maven2/com/oracle/database/nls/orai18n/${ORACLE_NLS_VERSION}/orai18n-${ORACLE_NLS_VERSION}.jar"
