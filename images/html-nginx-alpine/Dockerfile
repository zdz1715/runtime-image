FROM alpine:3.16

ARG TZ=Asia/Shanghai
ARG MIRROR=Huawei

ENV ZZ_TOOLS="/usr/local/zz-tools"
ENV TZ="${TZ}"

COPY tools $ZZ_TOOLS

COPY images/html-nginx-alpine/entrypoint.sh /entrypoint.sh


RUN chmod +x $ZZ_TOOLS/*.sh /entrypoint.sh; \
    $ZZ_TOOLS/install.sh --action init --mirror $MIRROR --timezone $TZ;


RUN $ZZ_TOOLS/install.sh ca-certificates nginx curl dos2unix;

RUN  adduser -S -D -H -h /var/www -s /sbin/nologin -G www-data -g www-data www-data; \
     chown -R www-data:www-data /var/www/;



### 环境变量配置
## nginx
ENV NGINX_CONF_D="/etc/nginx/http.d"
ENV NGINX_MAIN_CONF="/etc/nginx/nginx.conf"
ENV NGINX_DEFAULT_CONF="$NGINX_CONF_D/default.conf"
ENV NGINX_CUSTOM_VARS_CONF="$NGINX_CONF_D/vars.conf"
ENV NGINX_CUSTOM_CONF="$NGINX_CONF_D/custom-options.include"

## other 自定义配置，选填
ENV EXPIRES_IMG="30d"
ENV EXPIRES_CSS_JS="7d"
ENV NGINX_HEADER_ALLOW_ORIGIN=""
ENV NGINX_HEADER_ALLOW_HEADERS=""
ENV NGINX_HEADER_ALLOW_METHODS=""


COPY images/html-nginx-alpine/etc /etc

EXPOSE 80

WORKDIR /var/www

STOPSIGNAL SIGQUIT



ENTRYPOINT ["/entrypoint.sh"]
