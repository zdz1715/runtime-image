FROM ubuntu:22.04

ARG TZ=Asia/Shanghai
ARG MIRROR=Huawei
ARG PHP_VERSION=8.1

ARG COMPOSER_MIRROR=https://mirrors.aliyun.com/composer/

ARG PHP_EXTRA_EXTENSIONS

# 定义环境变量
### 基本
ENV TZ="${TZ}"
ENV ZZ_TOOLS="/usr/local/zz-tools"
### php
ENV PHP_VERSION=${PHP_VERSION}
ENV PHP_ETC="/etc/php/${PHP_VERSION}"
ENV PHP_EXTRA_EXTENSIONS=${PHP_EXTRA_EXTENSIONS}
ENV PHP_INI_D="${PHP_ETC}/fpm/conf.d"
ENV PHP_CLI_INI_D="${PHP_ETC}/cli/conf.d"
ENV PHP_FPM_CONF_D="${PHP_ETC}/fpm/pool.d"
ENV PHP_FPM_POOL_CONF="${PHP_ETC}/fpm/pool.d/zz.conf"
ENV PHP_FPM_SOCK="unix:/run/php/php${PHP_VERSION}-fpm.sock"

### nginx
ENV NGINX_CONF_D="/etc/nginx/conf.d"
ENV NGINX_MAIN_CONF="/etc/nginx/nginx.conf"
ENV NGINX_DEFAULT_CONF="$NGINX_CONF_D/default.conf"
ENV NGINX_CUSTOM_VARS_CONF="$NGINX_CONF_D/vars.conf"
ENV NGINX_CUSTOM_CONF="$NGINX_CONF_D/custom-options.include"


### supervisor
ENV SUPERVISOR_CONF_DIR='/etc/supervisor/conf.d'
ENV SUPERVISOR_MAIN_CONF="/etc/supervisor/supervisord.conf"
ENV SUPERVISOR_LOG_DIR='/var/log/supervisor'

### cron
ENV CRON_D='/etc/cron.d'


## other 自定义配置，选填
### 文件上传大小
ENV UPLOAD_LIMIT="1024m"

### 默认php ini 配置
ENV PHP_INI_SET="memory_limit = -1;"
### 默认 php-fpm 配置
ENV PHP_FPM_SET="clear_env = no;"

ENV ENABLE_OPCACHE=false

### 添加laravel调度定时任务
ENV CRON_LARAVEL_SCHEDULE=false

### nginx options请求快速返回
ENV NGINX_OPTIONS_RETURN=true
ENV NGINX_HEADER_ALLOW_ORIGIN=""
ENV NGINX_HEADER_ALLOW_HEADERS=""
ENV NGINX_HEADER_ALLOW_METHODS=""
ENV NGINX_EXPIRES_IMG="30d"
ENV NGINX_EXPIRES_CSS_JS="7d"



COPY tools $ZZ_TOOLS
# 拷贝启动脚本
COPY images/php-nginx-ubuntu/entrypoint.sh /entrypoint.sh

## 换源 > 设置时区 > 安装基本软件
RUN chmod +x $ZZ_TOOLS/*.sh /entrypoint.sh; \
    $ZZ_TOOLS/install.sh --action init --mirror $MIRROR;

RUN $ZZ_TOOLS/install.sh --action php-fpm_nginx_composer --root $ZZ_TOOLS --proxy https://launchpad.proxy.ustclug.org --composer-mirror $COMPOSER_MIRROR;

# 拷贝配置文件， before： 软件安装完成
COPY images/php-nginx-ubuntu/etc /etc/

# 安装php扩展

COPY images/php-nginx-ubuntu/ext/$PHP_VERSION /tmp/php-extra-ext

RUN cp /etc/php/fpm/*.conf ${PHP_ETC}/fpm/pool.d; \
    ln -sf $ZZ_TOOLS/cron-log.sh /usr/local/bin/cron-log; \
    $ZZ_TOOLS/install.sh --action php-ext --php-ext-dir /tmp/php-extra-ext

EXPOSE 80

WORKDIR /var/www

# 修改权限
RUN chown -R www-data:www-data /var/www/

ENTRYPOINT ["/entrypoint.sh"]

