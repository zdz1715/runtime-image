envFile := $(wildcard .env)

# 加载环境变量
ifneq ($(envFile),)
	include $(envFile)
endif

# 镜像仓库地址,后缀必须有‘/’
IMAGE_REGISTRY ?= ""
# 构建多平台
PLATFORM ?= "linux/amd64,linux/arm64"
# 构建器名称
BUILDER ?= "multi-platform"
# 使用的dockerfile文件名称
DOCKERFILE_FILENAME ?= "Dockerfile"

# 工作目录
WORK_DIR=$(shell pwd)/images

# 时区
TZ ?= "Asia/Shanghai"
# 软件源
#MIRROR_URL ?= "mirrors.aliyun.com"
#NPM_REGISTRY ?= "http://registry.npmmirror.com"
MIRROR_URL ?= ""
NPM_REGISTRY ?= ""

build_args = --progress=plain \
	--build-arg IMAGE_REGISTRY=$(IMAGE_REGISTRY) \
	--build-arg TZ=$(TZ) \
	--build-arg MIRROR_URL=$(MIRROR_URL) \
	--build-arg NPM_REGISTRY=$(NPM_REGISTRY)

PLATFORM_ARRAY := $(shell echo $(PLATFORM) | awk 'BEGIN {RS=","} {print}')
.PHONY: help
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "Usage:\n  make \033[36m<target>\033[0m\n"} /^[%a-zA-Z_._0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Build image
.PHONY: builder
builder:
	@echo "> Print builder info: $(BUILDER)"; \
	if ! docker buildx inspect $(BUILDER); then \
		echo "> Create builder: $(BUILDER)"; \
  		docker buildx create --bootstrap --name=$(BUILDER) --platform=$(PLATFORM) --driver=docker-container; \
	fi

.PHONY: basic
basic: ## Build basic images.
	@REGISTRY=$(IMAGE_REGISTRY) CONTEXT=$(WORK_DIR) SRC_DIR=$(WORK_DIR)/basic/ubuntu FORCE=true ./docker-build.sh $(build_args)
	@REGISTRY=$(IMAGE_REGISTRY) CONTEXT=$(WORK_DIR) SRC_DIR=$(WORK_DIR)/basic ./docker-build.sh $(build_args)

.PHONY: build
build: basic ## Build all images.
	@REGISTRY=$(IMAGE_REGISTRY) CONTEXT=$(WORK_DIR) SRC_DIR=$(WORK_DIR)/main ./docker-build.sh $(build_args)


.PHONY: %.build
%.build: ## Build specified image. e.g., basic/ubuntu:22.04.build or basic/ubuntu/22.04.build
	@REGISTRY=$(IMAGE_REGISTRY) CONTEXT=$(WORK_DIR) SRC_DIR=$(WORK_DIR)/$* FORCE=true ./docker-build.sh $(build_args)

##@ Push image

.PHONY: basic.push
basic.push: ## Build and push multi-architecture basic images.
	@REGISTRY=$(IMAGE_REGISTRY) CONTEXT=$(WORK_DIR) SRC_DIR=$(WORK_DIR)/basic/ubuntu FORCE=true ./docker-build.sh $(build_args) --push --builder=$(BUILDER) --platform=$(PLATFORM)
	@REGISTRY=$(IMAGE_REGISTRY) CONTEXT=$(WORK_DIR) SRC_DIR=$(WORK_DIR)/basic ./docker-build.sh $(build_args) --push --builder=$(BUILDER) --platform=$(PLATFORM)

.PHONY: push
push: basic.push ## Build and push multi-architecture images.
	@REGISTRY=$(IMAGE_REGISTRY) CONTEXT=$(WORK_DIR) SRC_DIR=$(WORK_DIR)/main ./docker-build.sh $(build_args) --push --builder=$(BUILDER) --platform=$(PLATFORM)

.PHONY: %.push
%.push: ## Build and push specified multi-architecture image. e.g., basic/ubuntu:22.04.push or basic/ubuntu/22.04.push
	@REGISTRY=$(IMAGE_REGISTRY) CONTEXT=$(WORK_DIR) SRC_DIR=$(WORK_DIR)/$* FORCE=true ./docker-build.sh $(build_args) --push --builder=$(BUILDER) --platform=$(PLATFORM)

