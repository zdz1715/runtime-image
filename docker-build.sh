#!/usr/bin/env bash

set -o errexit
set -o pipefail

readonly IMAGES_ROOT=$(dirname "${BASH_SOURCE[0]}")/images

source "${IMAGES_ROOT}/_func.sh"

if ! command_exists "docker" ; then
  logger fatal "缺少依赖: docker, 安装文档: https://docs.docker.com/get-docker/"
fi


# 镜像仓库
REGISTRY=${REGISTRY:-""}
# 镜像名称，没有则根据目录结构自动计算出名字，注意：适用于构建单个镜像的时候，多个镜像不生效
NAME=${NAME:-""}
# Dockerfile文件名字，默认：Dockerfile
Dockerfile=${Dockerfile:-"Dockerfile"}
# 从此目录搜索是$Dockerfile的文件，默认此脚本所处目录
SRC_DIR=${SRC_DIR:-${IMAGES_ROOT}}
# 是否强制更新, false若镜像已存在，则不重新构建,默认: false
FORCE=${FORCE:-"false"}
# context 默认 '.'
CONTEXT="${CONTEXT:-"."}"

# docker若存在则镜像则忽略,当FORCE != true 时生效
ignore_exists_paths=(
  basic/ubuntu/22.04
)

if [ ! -z $REGISTRY ]; then
  REGISTRY=${REGISTRY%*/}
  REGISTRY=${REGISTRY}/
fi

## 转换ubuntu:22.04为ubuntu/22.04，查找正确文件路径
SRC_DIR=${SRC_DIR//://}
SRC_DIR=${SRC_DIR%*/}
not_paths=""

## 删除要忽略的路径
if [ $FORCE != "true" ]; then
  for i in ${ignore_exists_paths[@]};do
    i=${i//://}
    name=$(echo $i | awk 'BEGIN {FS="/"} { printf "%s:%s", $(NF-1), $(NF) }')
    name=$REGISTRY$name
    if docker image inspect $name >>/dev/null 2>&1; then
      not_paths="$not_paths -not -path '*$i/*'"
    fi
  done
fi

dockerfile_paths=$(eval "find $SRC_DIR -type f -name $Dockerfile $not_paths")
dockerfile_count=$(echo $(echo $dockerfile_paths | wc -w))
# 多个镜像时不能指定名字
if [ $dockerfile_count -gt 1 ]; then
  NAME=""
fi

fail_count=0
extra_args="$*"
logger info "Found $dockerfile_count dockerfiles in $SRC_DIR"

for i in ${dockerfile_paths[@]};do
    echo x $i
done

logger info "Start build..."
failPath=()
successPath=()
for i in $dockerfile_paths; do
	dir=${path%/*}
	if [ ! -z "$NAME" ]; then
	  name=$NAME
	else
    name=$(echo $i | awk 'BEGIN {FS="/"} { printf "%s:%s", $(NF-2), $(NF-1) }')
    name=${name///:}
	fi

  name=$REGISTRY$name
  if ! logger cmd "docker build -t $name -f $i $extra_args $CONTEXT"; then
    fail_count=$(expr $fail_count + 1);
    failPath+=("$i")
  else
    successPath+=("${name}")
  fi
done

logger info "Total: $dockerfile_count success: $(expr $dockerfile_count - $fail_count) fail: $fail_count";
if [ ! -z $successPath ]; then
	logger info "Build success images:";
	for i in ${successPath[@]};do
    echo $i
  done
fi
if [ ! -z $failPath ]; then
	logger error "Build failed dockerfiles:";
	for i in ${failPath[@]};do
    echo $i
  done
fi