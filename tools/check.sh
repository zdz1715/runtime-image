#!/usr/bin/env sh

set -e

item="$1"

check_php_install() {
  if ! php -v 2> /dev/null ;then
    echo "error: php is not installed!"
    exit 1
  fi
}

check_php_module() {
  php_modules=$(php -m > /dev/stdout)

  echo "$php_modules"

  php_warnings=$(php -v 2>/dev/stdout | grep Warning)
  php_errors=$(php -v 2>/dev/stdout | grep Error)
  if [ "$php_warnings" ] || [ "$php_errors" ] ; then
    echo
    echo "error: php is not working properly"
    [ "$php_warnings" ] && echo "$php_warnings"
    [ "$php_errors" ] && echo "$php_errors"
    echo
    exit 1
  fi
}

do_check() {
  case "$item" in
    php)
      check_php_install
      check_php_module
    ;;
    *)
      echo
      echo "error: Unsupported '$item', supported:(php)"
      echo
      exit 1
    ;;
  esac
}

do_check