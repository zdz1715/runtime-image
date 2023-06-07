#!/usr/bin/env sh

set -e

root_d="./"
action=''
params=""
timezone="${TZ}"
php_version="${PHP_VERSION}"
php_ext="${PHP_EXTRA_EXTENSIONS}"
php_ext_d=""
php_ini_dirs="$PHP_INI_D;$PHP_CLI_INI_D"
mirror="Huawei"
composer_mirror=""
proxy=""
have_php_dev=0
while [ $# -gt 0 ]; do
	case "$1" in
		--action)
			action="$2"
			shift
			;;
	  --proxy)
      proxy="$2"
      shift
    ;;
    --php-ini-dirs)
      php_ini_dirs="$2"
      shift
    ;;
	  --timezone)
      timezone="$2"
      shift
      ;;
    --php-version)
      php_version="$2"
      shift
      ;;
    --php-ext)
      php_ext="$2"
      shift
      ;;
    --composer-mirror)
      composer_mirror="$2"
      shift
      ;;
     --php-ext-dir)
      php_ext_d="$2"
      shift
      ;;
    --root)
      root_d="$2"
      shift
      ;;
    --mirror)
      mirror="$2"
      shift
      ;;
		--*)
		  echo
			echo "[error]: Illegal option $1"
			echo
			exit 1
			;;
	  *)
	    if [ -n "$params" ]; then
	      params="$params $1"
	    else
	      params=$1
	    fi
    ;;
	esac
	shift $(( $# > 0 ? 1 : 0 ))
done


# 系统软件源
case "$mirror" in
	Aliyun)
		MIRROR_URL="mirrors.aliyun.com"
		;;
	Huawei)
		MIRROR_URL="repo.huaweicloud.com"
		;;
  *)
    MIRROR_URL="mirrors.aliyun.com"
    ;;
esac

get_distribution() {
	lsb_dist=""
	# Every system that we officially support has /etc/os-release
	if [ -r /etc/os-release ]; then
		lsb_dist="$(. /etc/os-release && echo "$ID")"
	fi
	# Returning an empty string here should be alright since the
	# case statements don't act unless you provide an actual value
	echo "$lsb_dist"
}

sh_c() {
  echo "+ $*"
  sh -c "$@"
}

install_init=""
install_tool=""
install_clean=""
install_remove=""

lsb_dist=$( get_distribution )
lsb_dist="$(echo "$lsb_dist" | tr '[:upper:]' '[:lower:]')"

case "$lsb_dist" in
  alpine)
    install_clean="rm -rf /var/cache/apk/*"
    install_init="apk update"
    install_tool="apk --no-cache add"
    install_t="apk --no-cache add"
    install_remove="apk del"

    switch_mirrors="cp -a /etc/apk/repositories /etc/apk/repositories.bak; \
      sed -i 's@//dl-cdn.alpinelinux.org@//${MIRROR_URL}@g' /etc/apk/repositories;"

    reset_mirrors="cp -a /etc/apk/repositories.bak /etc/apk/repositories"
  ;;
  debian)
    install_clean="apt-get --purge -y autoremove && apt-get -y clean && rm -rf /var/lib/apt/lists/*"
    install_init="apt-get -y update"
    install_tool="DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends --no-install-suggests"
    install_t="DEBIAN_FRONTEND=noninteractive apt-get install -y"
    install_remove="apt-get --purge -y remove"

    switch_mirrors="cp -a /etc/apt/sources.list /etc/apt/sources.list.bak; \
        sed -i -r 's@//.*(deb|snapshot|security).debian.org@//${MIRROR_URL}@g' /etc/apt/sources.list;"

    reset_mirrors="cp -a /etc/apt/sources.list.bak /etc/apt/sources.list"
  ;;
  ubuntu)
    install_clean="apt-get --purge -y autoremove && apt-get -y clean && rm -rf /var/lib/apt/lists/*"
    install_init="apt-get -y update"
    install_tool="DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends --no-install-suggests"
    install_t="DEBIAN_FRONTEND=noninteractive apt-get install -y"
    install_remove="apt-get --purge -y remove"

    switch_mirrors="cp -a /etc/apt/sources.list /etc/apt/sources.list.origin; \
    sed -i -r 's@//.*(archive|security).ubuntu.com@//${MIRROR_URL}@g' /etc/apt/sources.list;"

    reset_mirrors="cp -a /etc/apt/sources.list.origin /etc/apt/sources.list"

    case "$action" in
     php-fpm_nginx_composer)

        sh_c "$install_init"
        sh_c "$install_tool ca-certificates curl software-properties-common gpg-agent"
        # ppa ppa:ondrej/php
        ppa_php_file="/etc/apt/sources.list.d/ondrej-ubuntu-php-jammy.list"
        if [ ! -f "$ppa_php_file" ]; then
          sh_c "add-apt-repository -y ppa:ondrej/php"
        fi

        if [ -n "$proxy" ]; then
          sh_c "sed -i 's@https://ppa.launchpadcontent.net/@${proxy}/@g' $ppa_php_file"
          sh_c "$install_init"
        fi

        # microsoft
        sh_c "curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/microsoft.gpg"
        sh_c "curl https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/prod.list > /etc/apt/sources.list.d/mssql-release.list"


        sh_c "$install_remove software-properties-common gpg-agent"

      ;;
    esac
  ;;

  *)
    echo
    echo "error: Unsupported distribution '$lsb_dist'"
    echo
    exit 1
  ;;
esac

check_php_ext_so() {
  php_so_dir="$(get_php_ext_dir)"

  if [ -f "$php_so_dir/$1.so" ];then
    return 0
  fi
  return 1
}

get_php_ext_dir() {
  php -d 'display_errors=stderr' -r 'echo ini_get("extension_dir");'
}

enable_php_ext() {

  if [ -z "$php_ini_dirs" ]; then
    echo >&2 "error: '--php-ini-dirs' not configured"
    echo >&2
    return 1
  fi

  for module in "$@"
  do

    echo "info: enable ext: $module ..."

    if ! check_php_ext_so "$module"; then
      echo >&2 "error: '$module.so' does not exist"
      echo >&2
      return 1
    fi


    php_module_so_dir=$(get_php_ext_dir)
    php_module_so="$php_module_so_dir/$module.so"

    if readelf --wide --syms "$php_module_so" | grep -q ' zend_extension_entry$'; then
      line="zend_extension=$module"
    else
      line="extension=$module"
    fi


    if php -d 'display_errors=stderr' -r 'exit(extension_loaded("'"$module"'") ? 0 : 1);'; then
      # this isn't perfect, but it's better than nothing
      # (for example, 'opcache.so' presents inside PHP as 'Zend OPcache', not 'opcache')
      echo >&2
      echo >&2 "warning: $module is already loaded!"
      echo >&2
      continue
    fi

    for ini_dir in $php_ini_dirs
    do
       ini="$ini_dir/$module.ini"
       if ! grep -qFx -e "$line" -e "$line.so" "$ini" 2>/dev/null; then
          sh_c "echo $line >> $ini"
       fi
    done

  done

  echo
}

install_composer() {
  sh_c "curl -k -o /usr/bin/composer https://mirrors.aliyun.com/composer/composer.phar"
  sh_c "chmod +x /usr/bin/composer"
  sh_c "composer config -g repo.packagist composer $composer_mirror"
}

php_ext_format_name() {
  php_ext_name="${1##*/}"
  php_ext_name="${php_ext_name%.tgz}"
  php_ext_name="${php_ext_name%%:*}"
  php_ext_name="${php_ext_name%%-*}"


  echo "$php_ext_name"
}

php_ext_configure_name() {
  echo "${1%%:*}"
}


php_ext_configure() {
  php_ext_cfg="${1##*:}"

  if [ "$php_ext_cfg" = "$1" ]; then
    echo ""
  else
    eval echo "$php_ext_cfg"
  fi
}

install_php_ext_from_tgz() {
  php_ext_tgz_file="$1"

  if check_php_ext_so "$ext_name"; then
    echo >&2
    echo >&2 "warning: $ext_name.so is already exists!"
    echo >&2
    return 0
  fi

  if [ ! -f "$php_ext_tgz_file" ]; then
  	echo >&2 "error: $php_ext_tgz_file does not exist"
  	return 1
  fi

  shift

  if [ $have_php_dev = 0 ]; then
    sh_c "$install_t $php_pkg_prefix-dev"
    have_php_dev=1
  fi

  php_ext_dir="${php_ext_tgz_file%/*}"
  php_ext_name=$(php_ext_format_name "$php_ext_tgz_file")


   # 安装依赖项
  case "$php_ext_name" in
    rdkafka)
      sh_c "$install_tool librdkafka1 librdkafka-dev"
    ;;
    pdo_sqlsrv|sqlsrv)
        sh_c "ACCEPT_EULA=Y $install_tool unixodbc-dev msodbcsql18"
      ;;
    xlswriter)
      sh_c "$install_tool zlib1g-dev"
    ;;
  esac


  if [ "$php_ext_dir" = "$php_ext_tgz_file" ]; then
  	php_ext_dir="."
  fi



  php_ext_install_dir="${php_ext_dir}/${php_ext_name}"



  if [ ! -d "$php_ext_install_dir" ]; then
  	 sh_c "mkdir $php_ext_install_dir"
  else
    sh_c "rm -rf $php_ext_install_dir"
    sh_c "mkdir $php_ext_install_dir"
  fi


  sh_c "tar -xf $php_ext_tgz_file -C $php_ext_install_dir --strip-components=1"

  cd "$php_ext_install_dir"


  mc=$(nproc)
  sh_c "phpize"
  sh_c "./configure --enable-option-checking=fatal $*"
  sh_c "make -j$mc"
  sh_c "make -j$mc install"
  sh_c "make -j$mc clean"

  if [ ! $? = 0 ]; then
    return 1
  fi

  # 卸载无用依赖项
  case "$php_ext_name" in
    rdkafka)
      sh_c "$install_remove librdkafka-dev"
    ;;
    xlswriter)
      sh_c "$install_remove zlib1g-dev"
    ;;
  esac

  return 0
}

install_php_ext() {
  php_ext_suc_list=""
  php_ext_err_list=""

  php_pkg_prefix="php${php_version}"


  exts=$*
  OLD_IFS="$IFS"
  IFS=';'
  for ex in $exts
  do
    # 清除空格
    v=$(eval echo "$ex")
    echo
    echo "> $v "
    is_suc=0



    configure_name=$(php_ext_configure_name "$v")
    ext_name=$(php_ext_format_name "$configure_name")


    if [ -d "${php_ext_d}" ]; then
      local_ext_tgz="${php_ext_d}/$configure_name.tgz"
      if [ -f "$local_ext_tgz" ]; then
        echo "Loading in $local_ext_tgz ..."

        cg=$(php_ext_configure "$v")


        if install_php_ext_from_tgz "$local_ext_tgz" $cg; then
          if enable_php_ext "$ext_name" ; then
            is_suc=1
          fi
       fi

      fi
    fi

    if [ ! $is_suc = 1 ]; then
      echo "Install $php_pkg_prefix-$v ..."

      if sh_c "$install_tool $php_pkg_prefix-$v"; then
        is_suc=1
      fi

    fi

    if [ $is_suc = 1 ]; then
      php_ext_suc_list="$php_ext_suc_list $v"
      echo
      echo "info: $v successfully installed"
      echo
    else
      php_ext_err_list="$php_ext_err_list $v"
      echo
      echo "error: $v installation failed"
      echo
    fi

  done

  if [ $have_php_dev = 1 ]; then
    sh_c "$install_remove $php_pkg_prefix-dev"
  fi

  IFS="$OLD_IFS"

  echo
  echo "========================================================================================"
  echo "PHP version: $php_version"
  echo "Extra Extensions: $*"
  echo "Work directory: $(pwd)"
  echo "Extra Extensions directory: ${php_ext_d}"
  echo "================== result =============================================================="
  echo "install successfully: ${php_ext_suc_list}"
  echo "install failed: ${php_ext_err_list}"
  echo "========================================================================================"
  echo

  if [ -n "${php_ext_err_list}" ]; then
    echo "install failed: ${php_ext_err_list}"
    exit 1
  fi
}

exit_miss_param() {
  echo
  echo "error: missing parameter: $1"
  echo
  exit 1
}

do_install() {
  case "$action" in
    init)
      if [ -n "$MIRROR_URL" ]; then
        sh_c "$switch_mirrors"
      fi
      if [ -n "$timezone" ]; then
        sh_c "$install_init"
        sh_c "ln -sf /usr/share/zoneinfo/${timezone} /etc/localtime"
        sh_c "$install_tool tzdata"
        sh_c "$install_clean"
      fi
    ;;
    reset-mirror)
      sh_c "$reset_mirrors"
    ;;
    php-fpm_nginx_composer)
      if [ -z "$php_version" ];then
        exit_miss_param "--php-version"
      fi
      sh_c "$install_init"
      sh_c "$install_tool supervisor nginx unzip cron dos2unix lsb-release"
      sh_c "$install_tool php${php_version}-fpm"
      install_composer
      sh_c "$install_clean"
    ;;
    php-ext)
      if [ -z "$php_version" ] || [ -z "$php_ext" ] ;then
        exit_miss_param "--php-version , --php-ext"
      fi
      sh_c "$install_init"
      echo "info: install php${php_version} extra extensions: ${php_ext}"
      install_php_ext "$php_ext"
      sh_c "$install_clean"
      sh_c "rm -rf $php_ext_d"
    ;;
    clean)
      sh_c "$install_clean"
    ;;
    remove)
      if [ -z "$params" ];then
          exit_miss_param " , eg: $0 --action remove curl"
      fi
      sh_c "$install_remove $params"
      sh_c "$install_clean"
    ;;
    *)
      if [ -z "$params" ];then
        exit_miss_param " , eg: $0 curl"
      fi
      sh_c "$install_init"
      sh_c "$install_tool $params"
      sh_c "$install_clean"
    ;;
  esac
}

do_install


