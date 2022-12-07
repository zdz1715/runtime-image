ARG PHP_VERSION=8.1

FROM zdzserver/runtime:php${PHP_VERSION}-nginx-ubuntu


COPY images/php-nginx-ubuntu-oci8/packages/php${PHP_VERSION} /tmp/oci-packages

WORKDIR /tmp/oci-packages

RUN mv instantclient-basic*.zip instantclient-basic.zip; \
    mv instantclient-sdk*.zip instantclient-sdk.zip; \
    mv oci8*.tgz oci8.tgz; \
    unzip instantclient-basic.zip; \
    unzip instantclient-sdk.zip; \
    mkdir /opt/oracle; \
    mv instantclient_21_4 /opt/oracle; \
    echo /opt/oracle/instantclient_21_4 > /etc/ld.so.conf.d/oracle-instantclient.conf; \
    ldconfig; \
    $ZZ_TOOLS/install.sh libaio1; \
    $ZZ_TOOLS/install.sh --action php-ext --php-ext-dir /tmp/oci-packages --php-ext "oci8:--with-oci8=instantclient,/opt/oracle/instantclient_21_4"; \
    rm -rf /tmp/oci-packages;

WORKDIR /var/www

# 修改权限
RUN chown -R www-data:www-data /var/www/