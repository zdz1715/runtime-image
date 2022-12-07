FROM ubuntu:22.04

ARG TZ=Asia/Shanghai
ARG MIRROR=Huawei


# 设置时区环境变量， 或者 `/usr/local/zz-tools/install.sh --action timezone --timezone $TZ`
ENV TZ=$TZ
ENV ZZ_TOOLS="/usr/local/zz-tools"

COPY tools $ZZ_TOOLS

## 换源 > 设置时区 > 安装基本软件
RUN chmod +x $ZZ_TOOLS/*.sh; \
    $ZZ_TOOLS/install.sh --action init --mirror $MIRROR;


RUN $ZZ_TOOLS/install.sh ca-certificates

