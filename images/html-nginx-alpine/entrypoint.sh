#!/usr/bin/env sh

. "$ZZ_TOOLS/helper.sh"

# 文件里的变量替换成实际文件路径
parse_nginx_env

# init nginx options
set_nginx_options_by_env "$NGINX_CUSTOM_CONF" "$NGINX_CUSTOM_VARS_CONF"

is_exec_cmd=0

# 循环参数
for i in "$@"
do

  echo "+ $i"

  if [ "$i" = 'sh' ] || [ "$i" = '/bin/bash' ] || [ "$i" = 'bash' ]; then
    is_exec_cmd=1
  else
    # 挂起运行，防止阻塞下面主要进程
    nohup /bin/sh -c "$i" >/dev/stdout 2>&1 &
  fi
done


# 只执行命令行
if [ "$is_exec_cmd" = 1 ]; then
  exec "sh"
  exit 0
fi

# 打印nginx配置文件
print_nginx_conf

# 启动nginx
exec nginx -g 'daemon off;';


