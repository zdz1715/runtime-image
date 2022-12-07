ARG PHP_VERSION=8.1

FROM zdzserver/runtime:php${PHP_VERSION}-nginx-ubuntu

ARG NPM_MIRROR=https://registry.npmmirror.com

RUN curl -sL https://deb.nodesource.com/setup_16.x | bash -; \
    apt-get install -y nodejs; \
    $ZZ_TOOLS/install.sh --action remove lsb-release gnupg;

# 安装依赖项：https://github.com/puppeteer/puppeteer/blob/main/docs/troubleshooting.md#chrome-headless-doesnt-launch-on-unix
RUN $ZZ_TOOLS/install.sh \
        ca-certificates \
        fonts-liberation \
        libappindicator3-1 \
        libasound2 \
        libatk-bridge2.0-0 \
        libatk1.0-0 \
        libc6 \
        libcairo2 \
        libcups2 \
        libdbus-1-3 \
        libexpat1 \
        libfontconfig1 \
        libgbm1 \
        libgcc1 \
        libglib2.0-0 \
        libgtk-3-0 \
        libnspr4 \
        libnss3 \
        libpango-1.0-0 \
        libpangocairo-1.0-0 \
        libstdc++6 \
        libx11-6 \
        libx11-xcb1 \
        libxcb1 \
        libxcomposite1 \
        libxcursor1 \
        libxdamage1 \
        libxext6 \
        libxfixes3 \
        libxi6 \
        libxrandr2 \
        libxrender1 \
        libxss1 \
        libxtst6 \
        lsb-release \
        wget \
        xdg-utils

# 设置npm包路径环境变量
ENV NODE_PATH="/usr/local/lib/node_modules:/usr/lib/node_modules"
ENV PUPPETEER_CACHE_DIR="/usr/lib/node_modules/puppeteer/.local-chromium"


RUN echo "NODE_PATH=$NODE_PATH" >> /etc/environment; \
    echo "PUPPETEER_CACHE_DIR=$PUPPETEER_CACHE_DIR" >> /etc/environment; \
    npm config set registry $NPM_MIRROR; \
    npm install --location=global puppeteer; \
    npm cache clear --force;



COPY images/php-nginx-ubuntu-puppeteer/test.js /var/www/test.js

WORKDIR /var/www

# 修改权限
RUN chown -R www-data:www-data /var/www/

