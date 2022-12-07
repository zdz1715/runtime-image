FROM zdzserver/runtime:php7.4-nginx-ubuntu


# php.ini 设置多个模块的值
ENV PHP_INI_SET_ldap="ldap.max_links = -1"
ENV PHP_INI_SET_Tidy="tidy.clean_output = Off"
ENV PHP_INI_SET_'CLI Server'="cli_server.color = On"
ENV PHP_INI_SET_Pdo_mysql="pdo_mysql.default_socket="
ENV PHP_INI_SET_'mail function'="SMTP = localhost; smtp_port = 25; mail.add_x_header = Off"

# nginx 设置多个header值

ENV NGINX_HEADER_ALLOW_ORIGIN="*"
ENV NGINX_HEADER_ALLOW_HEADERS="*"
ENV NGINX_HEADER_ALLOW_METHODS="GET,POST,OPTIONS"

ENV NGINX_HEADER_SET_Access-Control-Allow-Private-Network=True
ENV NGINX_HEADER_SET_Access-Control-Allow-Methods="GET,POST"

# 安装swoole扩展

RUN $ZZ_TOOLS/install.sh php${PHP_VERSION}-swoole;

