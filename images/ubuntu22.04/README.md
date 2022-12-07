# ubuntu22.04

基于ubuntu 22.04 , 更改镜像源和时区，安装了基本运行软件，可用于生产

## 软件包
> 这里只列出程序主要的软件包

| 依赖包                           | 版本                                                                                  |
|:------------------------------|:------------------------------------------------------------------------------------|
| ca-certificates               | -                                                                                   |


## 扩展
### 安装额外软件
> Dockerfile
- 使用脚本(推荐)
```dockerfile
RUN $ZZ_TOOLS/install.sh curl;
```
- 使用原生
```dockerfile
RUN apt-get update; \
    apt-get install -y --no-install-recommends --no-install-suggests \
        curl \
    ; \
    apt-get --purge -y autoremove; \
    apt-get -y clean; \
    rm -rf /var/lib/apt/lists/*;
```
- 使用原生 + 脚本
```dockerfile
RUN apt-get update; \
    apt-get install -y --no-install-recommends --no-install-suggests \
        curl \
    ; \
    $ZZ_TOOLS/install.sh --action clean; 
```