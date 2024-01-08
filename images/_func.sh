#!/usr/bin/env sh

command_exists() {
  command -v "$@" > /dev/null 2>&1
}

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

version_gt() { test "$(echo "$@" | tr " " "\n" | sort -V | head -n 1)" != "$1"; }
version_gte() { test "$(echo "$@" | tr " " "\n" | sort -rV | head -n 1)" == "$1"; }
version_lt() { test "$(echo "$@" | tr " " "\n" | sort -rV | head -n 1)" != "$1"; }
version_lte() { test "$(echo "$@" | tr " " "\n" | sort -V | head -n 1)" == "$1"; }

# Logger
export OPT_NO_COLOR=${OPT_NO_COLOR:-0}
export OPT_LOG_MINIMAL=${OPT_LOG_MINIMAL:-0}
# examples:
#
# logger debug it is a debug log.
# logger info it is a info log.
# logger warn it is a warning log.
# logger error it is a error log.
# logger fatal it is a fatal log and then exit.
# logger cmd it is a command log and then sh -c "$*".
# logger exec it is a exec log and then exec "$*".
#
logger() {
  if [ $OPT_LOG_MINIMAL = true ] || [ $OPT_LOG_MINIMAL -eq 1 ]; then
    echo "$*"
    return
  fi

  local is_cmd=0
  local is_exec=0
  local is_exit=0
  local timestamp=$(date +'[%Y-%m-%d %H:%M:%S]')

  case "$1" in
  debug)
    local field="[DEBUG]"
    local color="\e[35m"
    shift
    ;;
  info)
    local field="[INFO]"
    local color="\e[34m"
    shift
    ;;
  warn)
    local field="[WARN]"
    local color="\e[33m"
    shift
    ;;
  error)
    local field="[ERROR]"
    local color="\e[31m"
    shift
    ;;
  fatal)
    local field="[FATAL]"
    local color="\e[1;31m"
    local is_exit=1
    shift
    ;;
  cmd)
    local field="[CMD]"
    local color="\e[1;34m"
    local is_cmd=1
    shift
    ;;
  exec)
    local field="[EXEC]"
    local color="\e[1;34m"
    local is_exec=1
    shift
    ;;
  *)
    local field="-"
    ;;
  esac

  if [ $OPT_NO_COLOR = true ] || [ $OPT_NO_COLOR -eq 1 ]; then
    printf "${timestamp} ${field} $*\n"
  else
    printf "\e[90m${timestamp}\e[0m ${color}${field}\e[0m $*\n"
  fi

  if [ ${is_cmd} -eq 1 ]; then
    sh -c "$*"
  elif [ ${is_exec} -eq 1 ]; then
    exec $*
  elif [ ${is_exit} -eq 1 ]; then
    exit 1
  fi
}