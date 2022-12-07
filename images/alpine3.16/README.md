# alpine3.16

基于alpine3.16 , 更改镜像源和时区，安装了基本运行软件，可用于生产

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
RUN apk --no-cache add curl;
```