# html-nginx-alpine
基于alpine 3.16，适用于打包后的单页面应用

## 最低运行要求
### kubernetes
- cpu: "0.5"
- memory: "512Mi"

## 软件包
> 这里只列出程序主要的软件包

| 软件包               | 版本     |
|:------------------|:-------|
| ca-certificates   | -      |
| nginx             | 1.22.0 |
| curl              | 7.83.1 |
| BusyBox           | 1.35.0 |

### 软件管理
```shell
# 更新软件源
apk update

# 搜索软件是否存在
apk search vim

# 安装
apk add vim

# 卸载
apk del vim
```

## 使用
> `${IMAGE_REGISTRY}`  请修改成真实使用的值
### vite、webpack打包
```dockerfile
FROM ${IMAGE_REGISTRY}/runtime:html-nginx-alpine

## 切换目录
WORKDIR /var/www

# 拷贝代码
COPY ./dist .

## 修改权限
RUN chown -R www-data:www-data /var/www/

```
## 环境变量
### 基础变量（不可修改）

| 变量名称                              | 描述                                                          | 默认值                              |
|:----------------------------------|:------------------------------------------------------------|:---------------------------------|
| TZ                                | 时区                                                          | `-`                              |
| ZZ_TOOLS                          | 本项目工具脚本目录                                                   | `/usr/local/zz-tools`            |
| NGINX_CONF_D                      | nginx的conf.d目录                                              | `/etc/nginx/http.d`                 |
| NGINX_MAIN_CONF                   | nginx的主要配置文件(**可覆盖此配置文件达到自定义设置**)                           | `/etc/nginx/nginx.conf`          |
| NGINX_DEFAULT_CONF                | nginx项目默认配置文件(**可覆盖此配置文件达到自定义设置**)                          | `/etc/nginx/http.d/default.conf` |

### 可自定义变量
| 变量名称                       | 描述                                                                                                           | 默认值                  |
|:---------------------------|:-------------------------------------------------------------------------------------------------------------|:---------------------|
| UPLOAD_LIMIT               | 上传文件大小，会同时设置php-fpm的upload_max_filesize、post_max_size；nginx的 client_max_body_size                            | `1024m`              |
| NGINX_OPTIONS_RETURN       | 配置`if ($request_method = 'OPTIONS' ) { return 200; }`                                                        | `true`               |
| NGINX_HEADER_ALLOW_ORIGIN  | `Access-Control-Allow-Origin`的值,可填写多个，如：`http://127.0.0.1,https://127.0.0.1,*.domain.com`, 支持通配符：`*`                                  | `""`                 |
| NGINX_HEADER_ALLOW_HEADERS | `Access-Control-Allow-Headers`的值                                                                             | `""`                 |
| NGINX_HEADER_ALLOW_METHODS | `Access-Control-Allow-Methods`的值                                                                             | `""`                 |
| NGINX_EXPIRES_IMG          | 图像等静态资源的缓存有效期                                                                                                | `"30d"`              |
| NGINX_EXPIRES_CSS_JS       | css、js资源的缓存有效期                                                                                               | `"7d"`               |
| NGINX_HEADER_SET_*header*  | 动态设置原生nginx header, 和`NGINX_HEADER_*`不冲突，会重复添加，如：`NGINX_HEADER_SET_Access-Control-Allow-Private-Network=True`| `""`                   |
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
```dockerfile
COPY $your_conf "$NGINX_DEFAULT_CONF"
```

- 添加新的配置文件(后缀`.conf`)
```dockerfile
#  php可以使用`fastcgi_pass $PHP_FPM_SOCK;`
COPY $your_conf "$NGINX_CONF_D"
```

## 日志

| 进程             | 输出方向                        | 说明            |
|:---------------|:----------------------------|:--------------|
| nginx          | `/dev/stdout` `/dev/stderr` | -             |
