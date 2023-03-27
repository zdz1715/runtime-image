envFile := $(wildcard .env)

# 加载环境变量
ifneq ($(envFile),)
	include $(envFile)
endif

IMAGE_REGISTRY ?= "runtime"
TZ ?= "Asia/Shanghai"
MIRROR ?= "Huawei"
PHP_EXTRA_EXTENSIONS ?= "bcmath curl gd mbstring mongodb mysql redis zip"
COMPOSER_MIRROR ?= "https://mirrors.aliyun.com/composer/"
PIP_MIRROR ?= "https://mirrors.aliyun.com/pypi/simple/"

c_args = --build-arg TZ=$(TZ) \
	--build-arg MIRROR=$(MIRROR) \
	--build-arg COMPOSER_MIRROR=$(COMPOSER_MIRROR) \
	--build-arg PIP_MIRROR=$(PIP_MIRROR) \
	--build-arg NPM_MIRROR=$(NPM_MIRROR)


.PHONY: help
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+\.*[a-zA-Z_0-9-]*:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)


docker-build:
	chmod +x hack/docker-build.sh

##@ Build image


.PHONY: ubuntu22.04
ubuntu22.04:docker-build ## Build images/ubuntu22.04
	REGISTRY=$(IMAGE_REGISTRY) VERSION="ubuntu22.04" ARGS='$(c_args)' hack/docker-build.sh ubuntu22.04

.PHONY: alpine3.16
alpine3.16:docker-build ## Build images/alpine3.16
	REGISTRY=$(IMAGE_REGISTRY) VERSION="alpine3.16" ARGS='$(c_args)' hack/docker-build.sh alpine3.16

.PHONY: html-nginx-alpine
html-nginx-alpine:docker-build ## Build images/html-nginx-alpine
	REGISTRY=$(IMAGE_REGISTRY) VERSION="html-nginx-alpine" ARGS='$(c_args)' hack/docker-build.sh html-nginx-alpine

.PHONY: php-nginx-ubuntu
php-nginx-ubuntu:php7.4-nginx-ubuntu php8.1-nginx-ubuntu php7.4-nginx-ubuntu-oci8 php8.1-nginx-ubuntu-oci8 php7.4-nginx-ubuntu-puppeteer php8.1-nginx-ubuntu-puppeteer## Build images/php-nginx-ubuntu all images

php7.4_nginx_ubuntu_args = $(c_args) \
						 --build-arg PHP_VERSION=7.4 \
						 --build-arg PHP_EXTRA_EXTENSIONS=$(PHP_EXTRA_EXTENSIONS)



php8.1_nginx_ubuntu_args = $(c_args) \
						 --build-arg PHP_VERSION=8.1 \
						 --build-arg PHP_EXTRA_EXTENSIONS=$(PHP8.1_EXTRA_EXTENSIONS)

.PHONY: php7.4-nginx-ubuntu
php7.4-nginx-ubuntu:docker-build ## Build images/php-nginx-ubuntu by php version: 7.4
	REGISTRY=$(IMAGE_REGISTRY) VERSION="php7.4-nginx-ubuntu" ARGS='$(php7.4_nginx_ubuntu_args)' hack/docker-build.sh php-nginx-ubuntu


.PHONY: php8.1-nginx-ubuntu
php8.1-nginx-ubuntu:docker-build ## Build images/php-nginx-ubuntu by php version: 8.1
	REGISTRY=$(IMAGE_REGISTRY) VERSION="php8.1-nginx-ubuntu" ARGS='$(php8.1_nginx_ubuntu_args)' hack/docker-build.sh php-nginx-ubuntu

.PHONY: php7.4-nginx-ubuntu-oci8
php7.4-nginx-ubuntu-oci8:docker-build ## Build images/php-nginx-ubuntu-oci8 by php version: 7.4
	REGISTRY=$(IMAGE_REGISTRY) VERSION="php7.4-nginx-ubuntu-oci8" ARGS='--build-arg PHP_VERSION=7.4' hack/docker-build.sh php-nginx-ubuntu-oci8


.PHONY: php8-nginx-ubuntu-oci8
php8.1-nginx-ubuntu-oci8:docker-build ## Build images/php-nginx-ubuntu-oci8 by php version: 8.1
	REGISTRY=$(IMAGE_REGISTRY) VERSION="php8.1-nginx-ubuntu-oci8" ARGS='--build-arg PHP_VERSION=8.1' hack/docker-build.sh php-nginx-ubuntu-oci8

.PHONY: php7.4-nginx-ubuntu-puppeteer
php7.4-nginx-ubuntu-puppeteer:docker-build ## Build images/php-nginx-ubuntu-puppeteer by php version: 7.4
	REGISTRY=$(IMAGE_REGISTRY) VERSION="php7.4-nginx-ubuntu-puppeteer" ARGS='--build-arg PHP_VERSION=7.4' hack/docker-build.sh php-nginx-ubuntu-puppeteer


.PHONY: php8-nginx-ubuntu-puppeteer
php8.1-nginx-ubuntu-puppeteer:docker-build ## Build images/php-nginx-ubuntu-puppeteer by php version: 8.1
	REGISTRY=$(IMAGE_REGISTRY) VERSION="php8.1-nginx-ubuntu-puppeteer" ARGS='--build-arg PHP_VERSION=8.1' hack/docker-build.sh php-nginx-ubuntu-puppeteer

golang1_18_builder_args = --build-arg GO_VERSION=1.18
golang1_18_builder_args += $(c_args)

.PHONY: golang1.18-builder
golang1.18-builder:docker-build ## Build images/golang-builder by golang version: 1.18
	REGISTRY=$(IMAGE_REGISTRY) VERSION="golang1.18-builder" ARGS='$(golang1_18_builder_args)' hack/docker-build.sh golang-builder


python38_args = --build-arg PYTHON_VERSION=3.8
python38_args += $(c_args)

.PHONY: python3.8-slim
python3.8-slim:docker-build ## Build images/python-slim by python version: 3.8
	REGISTRY=$(IMAGE_REGISTRY) VERSION="python3.8-slim" ARGS='$(python38_args)' hack/docker-build.sh python-slim

##@ Run
.PHONY: php7.4-nginx-ubuntu_run
php7.4-nginx-ubuntu_run: ## Run php7.4-nginx-ubuntu. port: 30080:80
	docker rm -f php7.4-nginx-ubuntu \
	&& docker run --rm -it --name php7.4-nginx-ubuntu -p 30080:80 $(IMAGE_REGISTRY):php7.4-nginx-ubuntu

.PHONY: php8.1-nginx-ubuntu_run
php8.1-nginx-ubuntu_run: ## Run images/php8-nginx-ubuntu. port: 30081:80
	docker rm -f php8.1-nginx-ubuntu \
	&& docker run --rm -it --name php8.1-nginx-ubuntu -p 30081:80 $(IMAGE_REGISTRY):php8.1-nginx-ubuntu



##@ Development


i ?= ubuntu22.04



.PHONY: bash
bash: ## Run image in bash, default: i=ubuntu22.04 eg: 'make bash i=php7.4-nginx-ubuntu', 'make bash i=php8.1-nginx-ubuntu'
	docker run --rm -it $(IMAGE_REGISTRY):$(i) bash


id ?= ubuntu22.04-dev

.PHONY: dev_bash
dev_bash: ## Copy the development file and develop in image, and Run image in bash, default: id=ubuntu22.04-dev eg: 'make dev_bash id=alpine3.16-dev'
	docker-compose up -d $(id) && docker-compose exec -it $(id) sh -c "clear; (bash || ash || sh)"


debug_php_info=mkdir /var/www/public; echo "<?php \n phpinfo();"  > /var/www/public/info.php

.PHONY: php7.4-nginx-ubuntu_debug
php7.4-nginx-ubuntu_debug: ## Exec php7.4-nginx-ubuntu bash. visit: 127.0.0.1:30080/info.php
	docker exec -it php7.4-nginx-ubuntu sh -c '$(debug_php_info); bash'

.PHONY: php8.1-nginx-ubuntu_debug
php8.1-nginx-ubuntu_debug: ## Exec php8.1-nginx-ubuntu bash. visit: 127.0.0.1:30081/info.php
	docker exec -it php8.1-nginx-ubuntu sh -c '$(debug_php_info); bash'



##@ Push image

.PHONY: push
push:ubuntu22.04_push php7.4-nginx-ubuntu_push php8.1-nginx-ubuntu_push php7.4-nginx-ubuntu-oci8_push php8.1-nginx-ubuntu-oci8_push html-nginx-alpine_push ## Push images/*

.PHONY: ubuntu22.04_push
ubuntu22.04_push: ## Push images/ubuntu22.04
	docker push $(IMAGE_REGISTRY):ubuntu22.04


.PHONY: html-nginx-alpine_push
html-nginx-alpine_push: ## Push images/html-nginx-alpine
	docker push $(IMAGE_REGISTRY):html-nginx-alpine

.PHONY: php-nginx-ubuntu_push
php-nginx-ubuntu_push: php7.4-nginx-ubuntu_push php8.1-nginx-ubuntu_push php7.4-nginx-ubuntu-oci8_push php8.1-nginx-ubuntu-oci8_push php7.4-nginx-ubuntu-puppeteer_push php8.1-nginx-ubuntu-puppeteer_push## Push images/php-nginx-ubuntu all images

.PHONY: php7.4-nginx-ubuntu_push
php7.4-nginx-ubuntu_push: ## Push php7.4-nginx-ubuntu
	docker push $(IMAGE_REGISTRY):php7.4-nginx-ubuntu

.PHONY: php8.1-nginx-ubuntu_push
php8.1-nginx-ubuntu_push: ## Push php8.1-nginx-ubuntu
	docker push $(IMAGE_REGISTRY):php8.1-nginx-ubuntu

.PHONY: php7.4-nginx-ubuntu-oci8_push
php7.4-nginx-ubuntu-oci8_push: ## Push php7.4-nginx-ubuntu-oci8
	docker push $(IMAGE_REGISTRY):php7.4-nginx-ubuntu-oci8

.PHONY: php8.1-nginx-ubuntu-oci8_push
php8.1-nginx-ubuntu-oci8_push: ## Push php8.1-nginx-ubuntu-oci8
	docker push $(IMAGE_REGISTRY):php8.1-nginx-ubuntu-oci8

.PHONY: php7.4-nginx-ubuntu-puppeteer_push
php7.4-nginx-ubuntu-puppeteer_push: ## Push php7.4-nginx-ubuntu-puppeteer
	docker push $(IMAGE_REGISTRY):php7.4-nginx-ubuntu-puppeteer

.PHONY: php8.1-nginx-ubuntu-puppeteer_push
php8.1-nginx-ubuntu-puppeteer_push: ## Push php8.1-nginx-ubuntu-puppeteer
	docker push $(IMAGE_REGISTRY):php8.1-nginx-ubuntu-puppeteer


test1:
	echo $(php7.4_nginx_ubuntu_args)