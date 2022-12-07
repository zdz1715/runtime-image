# golang-builder

用于构建golang二进制包的镜像，已配置系统镜像源、时区、goproxy等打包环境

## 软件包
> 这里只列出程序主要的软件包

| 依赖包    | 版本                                                                                  |
|:-------|:------------------------------------------------------------------------------------|
| golang | -                                                                                   |

## example
```dockerfile
FROM zdzserver/runtime:golang1.18-builder as build

WORKDIR /go/src

copy . .

RUN GOOS=linux CGO_ENABLED=0 GOARCH=amd64 go build -ldflags="-s -w" -installsuffix cgo -o /go/bin/main main.go

FROM zdzserver/runtime:ubuntu22.04

WORKDIR /go/bin

COPY --from=build /go/bin/main main


ENTRYPOINT  ["/go/bin/main"]


```