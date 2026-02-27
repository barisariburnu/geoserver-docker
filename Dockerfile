FROM kartoza/geoserver:2.28.2

LABEL maintainer="barisariburnu"
LABEL description="GeoServer with Oracle Spatial/Locator support"

# Oracle JDBC driver ve i18n desteğini Maven Central'dan indir
ARG ORACLE_JDBC_VERSION=19.3.0.0
ARG GEOSERVER_LIB_DIR=/opt/geoserver/webapps/geoserver/WEB-INF/lib

RUN curl -fSL -o ${GEOSERVER_LIB_DIR}/ojdbc8-${ORACLE_JDBC_VERSION}.jar \
    "https://repo1.maven.org/maven2/com/oracle/database/jdbc/ojdbc8/${ORACLE_JDBC_VERSION}/ojdbc8-${ORACLE_JDBC_VERSION}.jar" && \
    curl -fSL -o ${GEOSERVER_LIB_DIR}/orai18n-${ORACLE_JDBC_VERSION}.jar \
    "https://repo1.maven.org/maven2/com/oracle/database/nls/orai18n/${ORACLE_JDBC_VERSION}/orai18n-${ORACLE_JDBC_VERSION}.jar"
