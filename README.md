# runtime-image

可用于生产的镜像合集，支持构建多平台镜像

## 构建工具
-  Make
-  Docker Desktop

## 项目结构
```
├── Makefile  
├── README.md
├── images // 镜像构建源码，构建顺序: basic -> main
│   ├── basic // 基础镜像目录
│   │   ├── ubuntu // 镜像名称
│   │   │   ├── 22.04 // 镜像tag
│   │   │   │   └── Dockerfile
│   │   │   │── ...
│   │   │── ...
│   └── main // 主要镜像目录
│       ├── go-builder 
│       │   │── 1.21
│       │   │   └── Dockerfile
│       │   │── ...
│       │── ...
```
## 构建
