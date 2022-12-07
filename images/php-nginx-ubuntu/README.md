# php-nginx-ubuntu
基于ubuntu 22.04，使用supervisor管理进程:php-fpm、nginx等，适用于laravel、thinkphp等框架，并优化了nginx和fpm配置

## 最低运行要求
### kubernetes
- cpu: "0.5"
- memory: "512Mi"

## 软件包
> 这里只列出程序主要的软件包

| 软件包             | 版本                         |
|:----------------|:---------------------------|
| ca-certificates | -                          |
| supervisor      | 4.2.1                      |
| nginx           | 1.18.0                     |
| php7.4          | 7.4.30（每次构建7.4的最新版本）|     
| unzip           | 6.0-26                     |
| cron            | 3.0pl1                     |
| curl            | 7.81.0                     |
### 软件管理
```shell
# 更新软件源
apt update

# 搜索软件是否存在
apt search vim

# 安装
apt install vim

# 卸载
apt remove vim
```
### 进程管理

```shell
# 查看进程状态
supervisorctl status

# 重启
supervisorctl restart php-fpm

# 停止
supervisorctl stop php-fpm

# 重新加载配置
supervisorctl reload
```

## 使用
> `${IMAGE_REGISTRY}` `${PHP_VERSION}` 请修改成真实使用的值
### laravel
```dockerfile
FROM ${IMAGE_REGISTRY}/runtime:php${PHP_VERSION}-nginx-ubuntu

## 切换目录
WORKDIR /var/www

## 拷贝代码
COPY . .

## 删除多余
RUN rm -rf storage/logs/*.log && rm -rf storage/framework/cache/data/* && rm -rf bootstrap/cache/*
RUN rm -rf .git && rm -rf .idea

## 修改权限
RUN chown -R www-data:www-data /var/www/

## 环境变量
### nginx header Access-Control-Allow-Origin, 多个“,”分开
# ENV NGINX_HEADER_ALLOW_ORIGIN="*"

### nginx header Access-Control-Allow-Headers，多个“,”分开
# ENV NGINX_HEADER_ALLOW_HEADERS="*"

### nginx header Access-Control-Allow-Methods，多个“,”分开
# ENV NGINX_HEADER_ALLOW_METHODS="GET,POST,OPTIONS"

### OPTIONS请求不快速返回，默认: true
# ENV NGINX_OPTIONS_RETURN=false

### 开启laravel调度任务, 需CMD ["cron"]
ENV CRON_LARAVEL_SCHEDULE=true

### 开启opcache,默认: false
ENV ENABLE_OPCACHE=true

## 默认以root用户运行，若想以www-data运行，则写成这样：[ "su - www-data -s /bin/bash -c '$otherCommand'" ]
## CMD ["cron", "laravel-queue", "$otherCommand" ]
```

## 环境变量
### 基础变量（不可修改）

| 变量名称                              | 描述                                                         | 默认值 |
|:----------------------------------|:-----------------------------------------------------------|:----|
| TZ                                | 时区                                                         | `-` |
| ZZ_TOOLS                          | 本项目工具脚本目录                                                  | `/usr/local/zz-tools` |
| PHP_ETC                           | php配置文件所在的etc目录                                            | `-` |
| PHP_EXTRA_EXTENSIONS              | php安装的额外扩展                                                 | `-` |
| PHP_INI_D                         | php fpm ini配置文件目录                                          | `-` |
| PHP_CLI_INI_D                     | php cli ini配置文件目录                                          | `-` |
| PHP_FPM_CONF_D                    | php-fpm配置文件目录                                              | `-` |
| PHP_FPM_POOL_CONF                 | php-fpm项目自定义配置文件（**可覆盖此配置文件达到自定义设置**），有基础和优化的fpm配置项        | `-` |
| PHP_FPM_SOCK                      | php-fpm进程sock文件，nginx配置使用此变量 `fastcgi_pass $PHP_FPM_SOCK;` | `-` |
| NGINX_CONF_D                      | nginx的conf.d目录                                             | `/etc/nginx/conf.d` |
| NGINX_MAIN_CONF                   | nginx的主要配置文件(**可覆盖此配置文件达到自定义设置**)                          | `/etc/nginx/nginx.conf` |
| NGINX_DEFAULT_CONF                | nginx项目默认配置文件(**可覆盖此配置文件达到自定义设置**)                         | `/etc/nginx/conf.d/default.conf` |
| SUPERVISOR_CONF_DIR               | supervisor配置目录                                             | `/etc/supervisor/conf.d` |
| SUPERVISOR_MAIN_CONF              | supervisor配置主文件                                            | `/etc/supervisor/supervisord.conf` |
| SUPERVISOR_LOG_DIR                | 日志目录                                                       | `/var/log/supervisor` |
| CRON_D                            | 定时任务配置目录                                                   | `/etc/cron.d` |

### 可自定义变量
| 变量名称                       | 描述                                                                                                                                 | 默认值                  |
|:---------------------------|:-----------------------------------------------------------------------------------------------------------------------------------|:---------------------|
| UPLOAD_LIMIT               | 上传文件大小，会同时设置php-fpm的upload_max_filesize、post_max_size；nginx的 client_max_body_size                                                  | `1024m`              |
| PHP_INI_SET                | 设置[PHP]模块ini配置， 多个用`;`分割                                                                                                           | `memory_limit = -1;` |
| PHP_INI_SET_*module*       | 设置[*module*]模块ini配置，module为变量，如: `Pdo_mysql, bcmath, CLI Server`, 多个用`;`分割, 如： `PHP_INI_SET_'CLI Server'="cli_server.color = On;"` | `""`                 |
| PHP_FPM_SET                | 设置[www]的php-fpm配置，多个用`;`分割                                                                                                         | `clear_env = no;`    |
| CRON_LARAVEL_SCHEDULE      | 添加laravel调度定时任务，需开启`cron`, 定时任务语句：`* * * * * root $ZZ_TOOLS/cron-log.sh -u www-data /usr/bin/php /var/www/artisan schedule:run`    | `false`              |
| ENABLE_OPCACHE             | 开启opcache                                                                                                                          | `false`              |
| NGINX_OPTIONS_RETURN       | 配置`if ($request_method = 'OPTIONS' ) { return 200; }`                                                                              | `true`               |
| NGINX_HEADER_ALLOW_ORIGIN  | `Access-Control-Allow-Origin`的值,可填写多个，如：`http://127.0.0.1,https://127.0.0.1,*.domain.com`, 支持通配符：`*`                             | `""`                 |
| NGINX_HEADER_ALLOW_HEADERS | `Access-Control-Allow-Headers`的值                                                                                                   | `""`                 |
| NGINX_HEADER_ALLOW_METHODS | `Access-Control-Allow-Methods`的值                                                                                                   | `""`                 |
| NGINX_EXPIRES_IMG          | 图像等静态资源的缓存有效期                                                                                                                      | `"30d"`              |
| NGINX_EXPIRES_CSS_JS       | css、js资源的缓存有效期                                                                                                                     | `"7d"`               |
| NGINX_HEADER_SET_*header*  | 动态设置原生nginx header, 和`NGINX_HEADER_*`不冲突，会重复添加，如： `NGINX_HEADER_SET_Access-Control-Allow-Private-Network=True`                     | `""`                   |



## 内置命令
> Dockerfile
```shell
# 默认以root用户运行，若想以www-data运行，则写成这样：[ "su - www-data -s /bin/bash -c '$otherCommand'" ]
CMD [ "cron", "laravel-queue", "$otherCommand" ]
```

| command         | 描述                                                                                                                                                             | 
|:----------------|:---------------------------------------------------------------------------------------------------------------------------------------------------------------|
| cron            | 开启cron常驻进程                                                                                                                                                     |
| laravel-queue   | 开启常驻进程：`php /var/www/artisan queue:work --sleep=3 --tries=3 --timeout=120`, [参考](https://learnku.com/docs/laravel/9.x/queues/12236#supervisor-configuration) |
| $otherCommand   | 其他执行命令，Dockerfile示例： `CMD ["echo hello", "echo world"]`                                                                               |

## 自定义配置文件
> 在`Dockerfile`中添加以下语句

注意： `$your_conf` 为当前项目目录存在的配置文件,请替换为真实的文件名称
### nginx
- 覆盖默认nginx主配置文件
```dockerfile
# 
COPY $your_conf "$NGINX_MAIN_CONF"
```
- 覆盖默认nginx配置文件
> 需加上`include $NGINX_CUSTOM_CONF;`才能使`nginx UPLOAD_LIMIT`,`NGINX_OPTIONS_RETURN`等配置生效
```dockerfile
COPY $your_conf "$NGINX_DEFAULT_CONF"
```

- 添加新的配置文件(后缀`.conf`)
```dockerfile
#  php可以使用`fastcgi_pass $PHP_FPM_SOCK;`
COPY $your_conf "$NGINX_CONF_D"
```
### supervisor
- 添加新的配置文件(后缀`.conf`)
```dockerfile
COPY $your_conf "$SUPERVISOR_CONF_DIR"
```
示例：
```text
[program:cron]
command=cron -f
user=root
autostart=true
autorestart=true
numprocs=1
redirect_stderr=true
stdout_logfile=/var/log/supervisor/cron.log
```

### php
- 添加新的ini配置文件(后缀`.ini`)
```dockerfile
# fpm
COPY $your_conf "$PHP_INI_D"
# cli
COPY $your_conf "$PHP_CLI_INI_D"

```
- 使用环境变量设置（太长不推荐） `PHP_INI_SET_module` `PHP_INI_SET`
### php-fpm
- 添加新的配置文件(后缀`.conf`)
```dockerfile
COPY $your_conf "$PHP_FPM_CONF_D"
```
- 覆盖默认配置文件
```dockerfile
COPY $your_conf "$PHP_FPM_POOL_CONF"
```
- 使用环境变量设置（太长不推荐） `PHP_FPM_SET`

### cron
- 添加新的配置文件(后缀`无`)
```dockerfile
COPY $your_conf "$CRON_D"
```
推荐使用`/usr/local/zz-tools/cron-log.sh` 或 `/usr/local/bin/cron-log`来执行命令，通过此命令执行日志会记录到`/var/log/supervisor/cron.log`中，
示例：
```text
* * * * * root /usr/local/zz-tools/cron-log.sh -u www-data /usr/bin/php /var/www/artisan schedule:run
```
日志格式如下：
```text
--- [时间] [用户] [执行状态：SUCCESS|FAILURE] 执行的命令
命令输出
```
```text
--- [2020-12-24 17:30:01] [www-data] [FAILURE] /usr/bin/php /var/www/artisan schedule:run
Could not open input file: /var/www/artisan
--- [2020-12-24 17:31:01] [www-data] [FAILURE] /usr/bin/php /var/www/artisan schedule:run
Could not open input file: /var/www/artisan
...
```
## 日志

| 进程             | 输出方向                                     | 说明            |
|:---------------|:-----------------------------------------|:--------------|
| nginx          | `/dev/stdout`                            | -             |
| php            | `/dev/stdout`                            | -             |
| cron           | `/var/log/supervisor/cron.log`           | 需使用`cron-log` |
| supervisor     | `/var/log/supervisor/supervisord.log`    | -             |
| laravel-queue  | `/var/log/supervisor/laravel-queue.log`  | -             |

## 扩展
### 安装额外软件
> Dockerfile
- 使用脚本(推荐)
```dockerfile
RUN $ZZ_TOOLS/install.sh php${PHP_VERSION}-pgsql;
```
- 使用原生
```dockerfile
## 增加pgsql扩展
RUN apt-get update; \
    apt-get install -y --no-install-recommends --no-install-suggests \
        php${PHP_VERSION}-pgsql \
    ; \
    apt-get --purge -y autoremove; \
    apt-get -y clean; \
    rm -rf /var/lib/apt/lists/*;
```
- 使用原生 + 脚本
```dockerfile
## 增加pgsql扩展
RUN apt-get update; \
    apt-get install -y --no-install-recommends --no-install-suggests \
        php${PHP_VERSION}-pgsql \
    ; \
    $ZZ_TOOLS/install.sh --action clean; 
```
