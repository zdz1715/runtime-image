#!/usr/bin/env bash

# 加载助手函数
. "$ZZ_TOOLS/helper.sh"
. "$ZZ_TOOLS/helper_bash.sh"


# 创建目录
! [ -d "$SUPERVISOR_LOG_DIR" ] && mkdir "$SUPERVISOR_LOG_DIR"


is_exec_cmd=0

# 循环参数
for i in "$@"
do

  echo "+ $i"

  if [ "$i" = 'cron' ]; then
    cron_format "${CRON_D}"
    enable_supervisor_conf "cron" "$SUPERVISOR_CONF_DIR"
  elif [ "$i" = 'sh' ] || [ "$i" = '/bin/bash' ] || [ "$i" = 'bash' ]; then
    is_exec_cmd=1
  else
    # 挂起运行，防止阻塞下面主要进程
    nohup /bin/bash -c "$i" >/dev/stdout 2>&1 &
  fi
done


# 转换文件
parse_supervisor_env

# 只执行命令行
if [ "$is_exec_cmd" = 1 ]; then
  exec "/bin/bash"
  exit 0
fi


# 使用守护程序运行程序
exec supervisord -n -c /etc/supervisor/supervisord.conf