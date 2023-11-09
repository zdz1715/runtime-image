# 工作目录
WORK_DIR=$(shell pwd)
# 镜像仓库地址
IMAGE_REGISTRY ?= ""
# 构建多平台
PLATFORM ?= "linux/amd64,linux/arm64"
# 构建器名称
BUILDER ?= "multi-platform"
# 使用的dockerfile文件名称
DOCKERFILE_FILENAME ?= "Dockerfile"

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

.PHONY: build
build: ## Build images.
	$(call docker-build,$(WORK_DIR),"--progress=plain")


.PHONY: build.arch
build.arch: builder ## Build multi-architecture images.
	$(call docker-build,$(WORK_DIR),"--progress=plain --builder=$(BUILDER) --platform=$(PLATFORM) --load")

.PHONY: %.build
%.build: ## Build specified image. e.g., sonar-scanner.build sonar-scanner:5-alpine.build or sonar-scanner/5-alpine.build
	$(call docker-build,"$(WORK_DIR)/$*","--progress=plain")

.PHONY: %.build.arch
%.build.arch: builder## Build specified multi-architecture image. e.g., sonar-scanner.build.arch sonar-scanner:5-alpine.build.arch or sonar-scanner/5-alpine.build.arch
	$(call docker-build,"$(WORK_DIR)/$*","--progress=plain --builder=$(BUILDER) --platform=$(PLATFORM) --load")

##@ Push image
.PHONY: push
push: ## Build and push images.
	$(call docker-build,$(WORK_DIR),"--progress=plain --push")

.PHONY: push
push.arch: ## Build and push multi-architecture images.
	$(call docker-build,$(WORK_DIR),"--progress=plain --push --builder=$(BUILDER) --platform=$(PLATFORM)")

.PHONY: %.push
%.push: ## Build and push specified image. e.g., sonar-scanner.push sonar-scanner:5-alpine.push or sonar-scanner/5-alpine.push
	$(call docker-build,"$(WORK_DIR)/$*","--progress=plain --push")

.PHONY: %.push.arch
%.push.arch: builder## Build and push specified multi-architecture image. e.g., sonar-scanner.push.arch sonar-scanner:5-alpine.push.arch or sonar-scanner/5-alpine.push.arch
	$(call docker-build,"$(WORK_DIR)/$*","--progress=plain --push  --builder=$(BUILDER) --platform=$(PLATFORM)")


define docker-build
@image_dir=$1; \
extra_args=$2; \
image_dir=$${image_dir//://}; \
if [ ! -d $$image_dir ]; then \
	echo "$$image_dir: No such file or directory"; \
	exit 1; \
fi; \
dockerfile_paths=$$(find $$image_dir -type f -name $(DOCKERFILE_FILENAME)); \
dockerfile_count=$$(echo $$(echo $$dockerfile_paths | wc -w)); \
fail_count=0; \
echo "> Found $$dockerfile_count dockerfiles in $$image_dir\n$$dockerfile_paths"; \
echo "> Start build..."; \
for path in $$dockerfile_paths; do \
	name=$$(echo $$path | awk 'BEGIN {FS="/"} { printf "%s:%s", $$(NF-2), $$(NF-1) }'); \
	name=$${name///:}; \
	name=$${name//./}; \
	if [ -n $(IMAGE_REGISTRY) ]; then \
		name="$(IMAGE_REGISTRY)/$$name"; \
	fi; \
	command="docker buildx build -t $$name -f $$path $$extra_args ."; \
	echo "[$$path] $$command"; \
	if ! eval $$command; then \
	  fail_count=$$(expr $$fail_count + 1); \
	  failPath="$$failPath\n$$path"; \
	fi; \
done; \
echo "> Total: $$dockerfile_count success: $$(expr $$dockerfile_count - $$fail_count) fail: $$fail_count"; \
if [ ! -z $$failPath ]; then \
	echo "> Failed dockerfiles$$failPath"; \
fi
endef
