#!/usr/bin/env sh

set -e

. "/_func.sh"

lsb_dist=$( get_distribution )
lsb_dist="$(echo "$lsb_dist" | tr '[:upper:]' '[:lower:]')"

case "$lsb_dist" in
  ubuntu)
    mirror_file="/etc/apt/sources.list"
    ;;
  debian)
    mirror_file="/etc/apt/sources.list"
    if [ ! -f "/etc/apt/sources.list" ]; then
      # debian 12 +
      mirror_file="/etc/apt/sources.list.d/debian.sources"
    fi
    ;;
esac

# 系统相关
## 软件镜像源
if [ -n "$MIRROR_URL" ] && [ -f $mirror_file ]; then
  echo "* Apply MIRROR_URL=$MIRROR_URL"
  cp -a $mirror_file "${mirror_file}.bak"
  sed -i -r "s@://([A-Za-z0-9_\.\-])+/@://$MIRROR_URL/@g" $mirror_file
fi

## 时区
if [ -n "$TZ" ]; then
  echo "* Apply TZ=$TZ"
  ln -sf /usr/share/zoneinfo/$TZ /etc/localtime
fi

exec "$@"

