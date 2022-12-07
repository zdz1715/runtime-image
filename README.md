# runtime-image

程序运行镜像

## 初衷
为了解决冗余的镜像配置，提供基础的程序运行镜像

## 镜像tag

### 基础
- [ubuntu22.04](images/ubuntu22.04/README.md): 基于ubuntu 22.04 , 更改镜像源和时区，安装了基本运行软件，可用于生产
- [alpine3.16](images/alpine3.16/README.md): 基于alpine3.16 , 更改镜像源和时区，安装了基本运行软件，可用于生产

### php

- [php7.4-nginx-ubuntu](./images/php-nginx-ubuntu/README.md): 基于ubuntu 22.04，使用supervisor管理进程:php7-fpm、nginx等，适用于laravel、thinkphp等框架，，并优化了nginx和fpm配置
- [php7.4-nginx-ubuntu-oci8](./images/php-nginx-ubuntu/README.md): 增加oci8扩展
- [php7.4-nginx-ubuntu-puppeteer](./images/php-nginx-ubuntu/README.md): 包含`node,npm,puppeteer`
- [php8.1-nginx-ubuntu](./images/php-nginx-ubuntu/README.md): 基于ubuntu 22.04，使用supervisor管理进程:php8-fpm、nginx等，适用于laravel、thinkphp等框架，并优化了nginx和fpm配置
- [php8.1-nginx-ubuntu-oci8](./images/php-nginx-ubuntu/README.md): 增加oci8扩展
- [php8.1-nginx-ubuntu-puppeteer](./images/php-nginx-ubuntu/README.md): 包含`node,npm,puppeteer`

### html
- [html-nginx-alpine](./images/html-nginx-alpine/README.md): 基于alpine 3.16，适用于打包后的单页面应用

### golang

- [golang1.18-builder](./images/golang-builder/README.md): 用于构建golang二进制包的镜像，已配置系统镜像源、时区、goproxy等打包环境

### python
- [python3.8-slim](./images/python-slim/README.md)

## 构建
### 1. 拉取代码并配置构建参数
```shell
git clone https://github.com/zdz1715/runtime-image.git
cd ./runtime-image
cp .env.example .env
```

### 2. 构建

```shell
# make 上述镜像列表名称
make php7.4-nginx-ubuntu

make php8.1-nginx-ubuntu

make ubuntu-22.04
...
```

### 3. 查看帮助
```shell
make help
```

## example
- [lnmp](./example/compose/lnmp/README.md): 快速搭建一套php7.4 + php8.1 + mysql + redis的开发环境，也可用于生产（docker单机部署）

## 参考项
### 已构建好的仓库
- `zdzserver/runtime`：和`.env.example`构建参数一致
### 构建参数

| 参数                    | 适用镜像                                          | 描述                               | 默认值                                               |
|:----------------------|:----------------------------------------------|:---------------------------------|:--------------------------------------------------|
| IMAGE_REGISTRY        | `ALL`                                         | 镜像仓库                             | `runtime`                                         |
| TZ                    | `ALL`                                         | 系统时区                             | `Asia/Shanghai`                                   |
| MIRROR                | `ALL`                                         | 系统镜像源，默认华为源                      | `Huawei`                                          |
| PHP_EXTRA_EXTENSIONS  | `php7.4-nginx-ubuntu` `php8.1-nginx-ubuntu`   | [php额外扩展](#PHP_EXTRA_EXTENSIONS) | `bcmath,curl,gd,mbstring,mongodb,mysql,redis,zip` |
| COMPOSER_MIRROR  | `php7.4-nginx-ubuntu` `php8.1-nginx-ubuntu`   | composer源                        | `https://mirrors.aliyun.com/composer/` |

### <a id="PHP_EXTRA_EXTENSIONS">php额外扩展</a>
> 加载顺序： images/php-nginx-ubuntu/ext/$PHP_VERSION > 系统库

- 格式：`"扩展名称;扩展名称[:编译参数];扩展名称"`， 如： `"curl;gd:--prefix=/user/local/libpng;bcmath"`
- 原理：
  - `images/php-nginx-ubuntu/ext/$PHP_VERSION`: php扩展的tgz文件存放目录，会解压`扩展名称.tgz`若此文件存在，然后进行编译安装，可配置编译参数
  - `系统库`: 匹配不到扩展目录的文件后，会执行`apt-get install -y php(7.4|8.1)-扩展名称`，忽略编译参数

