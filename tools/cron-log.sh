#!/usr/bin/env bash

# 初始化变量
EXEC_USER='root'
CRON_PID=$(cat /var/run/crond.pid)
IS_LOGIN='--preserve-environment'

step_exec() {
    {
      RESULT=$(su $IS_LOGIN $EXEC_USER -s /bin/bash -c "$*" 2>&1);
      RESULT_CODE="$?";
      if [[ "$RESULT_CODE" == 0 ]]; then
        RESULT_TXT="SUCCESS"
      else
        RESULT_TXT="FAILURE"
      fi
      echo -e "--- [$(date '+%Y-%m-%d %H:%M:%S')] [$EXEC_USER] [$RESULT_TXT] $*";
      echo -e "$RESULT";
    } >> /proc/"${CRON_PID}"/fd/1 2>&1
    return "${PIPESTATUS[0]}"
}

usage() {
    #       -P, --plugin string           插件，可选：pam_mysql
    echo
    echo "Usage: cron-log [OPTIONS] COMMAND [ARG ...]

    Options:
      -h, --help                    帮助
      -u, --user string             执行用户
      -l, --login                   是否登录
    "
}

TEMP=$(getopt -o uhl --long help,user,login -- "$@" 2>/dev/null)
[ $? != 0 ]  && usage && exit 1

while :; do
  [ -z "$1" ] && break;
  case "$1" in
    -h|--help)
      usage; exit 0
      ;;
    -u|--user)
      EXEC_USER=$2; shift 2
      ;;
    -l|--login)
      IS_LOGIN="--login"; shift 1
      ;;
    --)
      break
      ;;
    *)
      break;;
  esac
done

[[ -z "$*" ]] && usage && exit 1
step_exec "$@"


