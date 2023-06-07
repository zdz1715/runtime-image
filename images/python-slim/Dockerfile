ARG PYTHON_VERSION=3.10

FROM python:${PYTHON_VERSION}-slim

ARG TZ=Asia/Shanghai
ARG MIRROR=Aliyun
ARG PIP_MIRROR="https://mirrors.aliyun.com/pypi/simple/"

COPY tools /usr/local/zz-tools
# 拷贝启动脚本
COPY images/python-slim/entrypoint.sh /entrypoint.sh

ENV TZ=$TZ
ENV ZZ_TOOLS="/usr/local/zz-tools"

### supervisor
ENV SUPERVISOR_CONF_DIR='/etc/supervisor/conf.d'
ENV SUPERVISOR_MAIN_CONF="/etc/supervisor/supervisord.conf"
ENV SUPERVISOR_LOG_DIR='/var/log/supervisor'

### cron
ENV CRON_D='/etc/cron.d'

## 换源 > 设置时区 > 安装基本软件
RUN chmod +x $ZZ_TOOLS/*.sh /entrypoint.sh; \
    $ZZ_TOOLS/install.sh --action init --mirror $MIRROR; \
    ln -sf $ZZ_TOOLS/cron-log.sh /usr/local/bin/cron-log;

RUN pip config set global.index-url $PIP_MIRROR;


## 安装基本软件
RUN $ZZ_TOOLS/install.sh ca-certificates supervisor cron curl;


ENTRYPOINT ["/entrypoint.sh"]




