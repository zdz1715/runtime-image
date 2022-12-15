#!/usr/bin/env bash

# 加载助手函数
. "$ZZ_TOOLS/helper.sh"
. "$ZZ_TOOLS/helper_bash.sh"

# 文件里的变量替换成实际文件路径
parse_supervisor_env
parse_nginx_env

# init nginx options
set_nginx_options_by_env "$NGINX_CUSTOM_CONF" "$NGINX_CUSTOM_VARS_CONF"

# 处理预定义变量
## 文件上传限制
if [ -n "${UPLOAD_LIMIT}" ]; then
  # 更改php ini
  PHP_INI_SET+=";upload_max_filesize = $UPLOAD_LIMIT;post_max_size = $UPLOAD_LIMIT;"
fi


## 开启opcache
if [ "$ENABLE_OPCACHE" = true ]; then
  for ini_dir in ${PHP_INI_D} ${PHP_CLI_INI_D}
  do
    {
      echo "[opcache]"
      echo "opcache.enable=1"
      echo "opcache.enable_cli=0"
      echo "opcache.memory_consumption=128"
      echo "opcache.interned_strings_buffer=16"
      echo "opcache.max_accelerated_files=4000"
      echo "opcache.max_wasted_percentage=15"
      echo "opcache.use_cwd=1"
      echo "opcache.validate_timestamps=0"
      echo "opcache.revalidate_freq=0"
      echo "opcache.consistency_checks=0"
    } > "${ini_dir}/98-opcache.ini"
  done
fi

if [ "$CRON_LARAVEL_SCHEDULE" = true ]; then
  {
    echo "* * * * * root $ZZ_TOOLS/cron-log.sh -u www-data /usr/bin/php /var/www/artisan schedule:run"
  } > "${CRON_D}/laravel-schedule"
fi

# 加载环境变量

load_php_ini

load_php_fpm

# 创建目录
! [ -d "$SUPERVISOR_LOG_DIR" ] && mkdir "$SUPERVISOR_LOG_DIR"
! [ -d "/run/php" ] && mkdir "/run/php"


is_exec_cmd=0

# 循环参数
for i in "$@"
do

  echo "+ $i"

  if [ "$i" = 'cron' ]; then
    cron_format "${CRON_D}"
    enable_supervisor_conf "cron" "$SUPERVISOR_CONF_DIR"
  elif [ "$i" = 'laravel-queue' ]; then
    enable_supervisor_conf "laravel-queue" "$SUPERVISOR_CONF_DIR"
  elif [ "$i" = 'sh' ] || [ "$i" = '/bin/bash' ] || [ "$i" = 'bash' ]; then
    is_exec_cmd=1
  else
    # 挂起运行，防止阻塞下面主要进程
    nohup /bin/bash -c "$i" >/dev/stdout 2>&1 &
  fi
done

# 修改权限
chown -R www-data:www-data /var/lib/nginx
chown -R www-data:www-data /var/www

# 只执行命令行
if [ "$is_exec_cmd" = 1 ]; then
  exec "/bin/bash"
  exit 0
fi

# 打印nginx配置文件
print_nginx_conf

# 使用守护程序运行程序
exec supervisord -n -c /etc/supervisor/supervisord.conf