#!/usr/bin/env sh


step()
{
  echo "# ========================================================= #"
  echo "# $1 "
  echo "# ========================================================= #"
}

log()
{
  echo "$1：$2"
}

log_error()
{
  log "[error]" "$1"
}

log_info()
{
  log "[info]" "$1"
}

log_success()
{
  log "[success]" "$1"
}

log_command()
{
  log "[command]" "$*"
  sh -c "$*"
}








enable_supervisor_conf() {
  name="$1"
  conf_d="$2"
  if [ -f "${conf_d}/${name}.unused" ]; then
    mv "${conf_d}/${name}.unused" "${conf_d}/${name}.conf"
  fi

}

parse_nginx_env() {
  find "${NGINX_CONF_D}" -type f -exec sed -i "s~\$PHP_FPM_SOCK~$PHP_FPM_SOCK~g" {} +
  find "${NGINX_CONF_D}" -type f -exec sed -i "s~\$NGINX_CUSTOM_CONF~$NGINX_CUSTOM_CONF~g" {} +
}

parse_supervisor_env() {
  find "${SUPERVISOR_CONF_DIR}" -type f -exec sed -i "s~\${SUPERVISOR_LOG_DIR}~$SUPERVISOR_LOG_DIR~g" {} +
  find "${SUPERVISOR_CONF_DIR}" -type f -exec sed -i "s~\${PHP_VERSION}~$PHP_VERSION~g" {} +
  find "${SUPERVISOR_CONF_DIR}" -type f -exec sed -i "s~\${ZZ_TOOLS}~$ZZ_TOOLS~g" {} +
}

nginx_cors_var_name="allow_origin"


nginx_cors_var() {
  origin_value=$1
  default_origin="''"
  cors_name="# cors \nmap \$http_origin \$$nginx_cors_var_name"
  if [ -z "$origin_value" ]; then
    printf "$cors_name { \n    %s;\n}\n" "default $default_origin"
  else
    if [ "$origin_value" = "*" ]; then
      default_origin="'*'"
      origin_value='\*'
    fi

    # 去除空格
    origin_value=$(eval echo "$origin_value" | sed "s~ ~~g" )
    # 修改成正则的‘|’，并规范 ‘*’
    origin_value=$(echo "$origin_value" | sed "s~,~|~g" )
    origin_value=$(echo "$origin_value" | sed "s~\.\*~*~g" )
    origin_value=$(echo "$origin_value" | sed "s~*~\.\*~g" )

    printf "$cors_name { \n    %s;\n    %s;\n}\n" "~($origin_value) \$http_origin" "default $default_origin"
  fi
}

nginx_add_header() {
  if [ -n "$2" ]; then
    printf "$3add_header %s %s always; \n" "$1" "$2"
  fi
}

echo_nginx_header_set_by_env() {
  start_tabs="$1"
  tabs="$2"
  nginx_headers=$(env | grep NGINX_HEADER_SET_)
  i=1
  for h in $nginx_headers;
  do
    kval=${h#NGINX_HEADER_SET_}
    key=${kval%%=*}
    val=${kval#*=}

    if [ $i = 1 ]; then
      nginx_add_header "$key" "$val" "$start_tabs"
    else
      nginx_add_header "$key" "$val" "$tabs"
    fi
    i=$((i+1))
  done
}


set_nginx_options_by_env() {
  nginx_option_conf="$1"
  nginx_vars_conf="$2"

  # reset
  echo "## custom options" > "$nginx_option_conf"

cat > "$nginx_vars_conf" <<EOF
## custom vars

# Helper variable for proxying websockets.
map \$http_upgrade \$connection_upgrade {
    default upgrade;
    '' close;
}

EOF

  echo >> "$nginx_option_conf"

  if [ -n "${UPLOAD_LIMIT}" ]; then
    echo "client_max_body_size $UPLOAD_LIMIT;" >> "$nginx_option_conf"
  fi

  # options 快速请求
  if [ "$NGINX_OPTIONS_RETURN" = true ]; then
    echo "if (\$request_method = 'OPTIONS' ) { return 200; }" >> "$nginx_option_conf"
  fi

  nginx_cors_var "$NGINX_HEADER_ALLOW_ORIGIN" >> "$nginx_vars_conf"

  # header
  nginx_headers >> "$nginx_option_conf" ""

  # 静态资源缓存

  expires_img="30d"
  expires_css_js="7d"
  if [ -n "$NGINX_EXPIRES_IMG" ]; then
    expires_img=$NGINX_EXPIRES_IMG
  fi

  if [ -n "$NGINX_EXPIRES_CSS_JS" ]; then
    expires_css_js=$NGINX_EXPIRES_CSS_JS
  fi



cat >> "$nginx_option_conf" <<EOF

# static resource
location ~ .*\.(gif|jpg|jpeg|png|bmp|swf|flv|mp4|ico)$ {
  $(nginx_headers "  ")

  expires $expires_img;
  access_log off;
}

location ~ .*\.(js|css)?$ {
  $(nginx_headers "  ")

  expires $expires_css_js;
  access_log off;
}
EOF

}

nginx_headers() {
  echo
  echo "$1# header"
  nginx_add_header "Access-Control-Allow-Origin" "\$$nginx_cors_var_name" "$1"
  nginx_add_header "Access-Control-Allow-Headers" "${NGINX_HEADER_ALLOW_HEADERS}" "$1"
  nginx_add_header "Access-Control-Allow-Methods" "${NGINX_HEADER_ALLOW_METHODS}" "$1"
  echo_nginx_header_set_by_env "$1" "$1"
}

print_nginx_conf() {

  if [ -f "$NGINX_CUSTOM_VARS_CONF" ]; then
    log_info "$NGINX_CUSTOM_VARS_CONF"
    cat "$NGINX_CUSTOM_VARS_CONF"
  fi


  echo

  if [ -f "$NGINX_CUSTOM_CONF" ]; then
    log_info "$NGINX_CUSTOM_CONF"
    cat "$NGINX_CUSTOM_CONF"
  fi



  echo

  if [ -f "$NGINX_DEFAULT_CONF" ]; then
    log_info "$NGINX_DEFAULT_CONF"
    cat "$NGINX_DEFAULT_CONF"
  fi

  echo
}
