# lnmp
快速搭建一套php7.4 + php8.1 + mysql + redis的开发环境，也可用于生产（docker单机部署）


## 依赖项
- docker: 20.10.7以上版本
- docker-compose

## 使用

```shell
# 拉取代码
git clone https://github.com/zdz1715/runtime-image.git

# 进入工作目录
cd ./example/compose/lnmp

# 配置文件
cp .env.example .env

# 启动
docker-compose up -d

# 卸载
docker-compose down
```

### 配置项（.env）

| 配置项                    | 说明                                                                                                  | 默认值                                         |
|:-----------------------|:----------------------------------------------------------------------------------------------------|:--------------------------------------------|
| PHP7_WEB_ROOT          | 使用php7.4的项目目录，可多个项目放一个目录(需配置nginx 配置文件)，也可以是一个项目的根目录(不用额外配置nginx，端口：80)                             | `./`                                        |
| PHP8_WEB_ROOT          | 使用php8.1的项目目录，可多个项目放一个目录(需配置nginx 配置文件)，也可以是一个项目的根目录(不用额外配置nginx， 端口：80)                            | `./`                                        | 
| PHP7_NGINX_CONF_D      | php7.4的nginx虚拟主机配置目录                                                                                | `./nginx/conf.d/php74/`                     | 
| PHP8_NGINX_CONF_D      | php8.1的nginx虚拟主机配置目录                                                                                | `./nginx/conf.d/php81/`                     | 
| MYSQL57_DATA           | mysql5.7版本的数据存储目录                                                                                   | `./mysql/data`                              |
| REDIS6_DATA            | redis6版本数据存储目录                                                                                      | `./redis/data`                              | 
| REDIS6_CONFIG          | redis6配置文件路径                                                                                        | `./redis/redis.config`                      | 
