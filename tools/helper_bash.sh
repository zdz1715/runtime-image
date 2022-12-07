#!/usr/bin/env bash




cron_format() {
  mapfile -t file_list < <(find "$1" -type f)
  for f in "${file_list[@]}"
  do
    dos2unix "$f"
    # 插入新行
    echo '' >> "$f"
  done
}



set_ini () {
  local filepath="$1"
  local val="$2"
  local section="$3"
  local vals=()


  OLD_IFS="$IFS"
  IFS=";"
  read -r -a vals <<< "$val"
  IFS="$OLD_IFS"

  if [ -n "$section" ];then
    echo "[$section]" >> "$filepath"
  fi

  for v in "${vals[@]}"
  do
    eval echo "$v" >> "$filepath"
  done
}


load_php_ini() {
  local php_ini_section_sets=()

  if [ -n "${PHP_INI_SET}" ]; then
    php_ini_section_sets+=("PHP_INI_SET_PHP=${PHP_INI_SET}")
  fi

  for ini_dir in ${PHP_INI_D} ${PHP_CLI_INI_D}
  do
    echo "" > "${ini_dir}/zz.ini"
  done

  while IFS='' read -r line;do php_ini_section_sets+=("$line"); done < <(env | grep PHP_INI_SET_)

  for e in "${php_ini_section_sets[@]}"
  do
    local kval=${e#PHP_INI_SET_}
    local section=${kval%%=*}
    local val=${kval#*=}

    for ini_dir in ${PHP_INI_D} ${PHP_CLI_INI_D}
    do
      set_ini "${ini_dir}/zz.ini" "$val" "$section"
    done
  done
}

load_php_fpm() {
  if [ -z "${PHP_FPM_SET}" ]; then
    return
  fi
  # 清空
  echo "" > "${PHP_FPM_POOL_CONF}"
  set_ini "${PHP_FPM_POOL_CONF}" "${PHP_FPM_SET}" "www"
}
