FROM zdzserver/runtime:html-nginx-alpine

# nginx 设置多个header值

ENV NGINX_HEADER_ALLOW_ORIGIN="*"
ENV NGINX_HEADER_ALLOW_HEADERS="*"
ENV NGINX_HEADER_ALLOW_METHODS="GET,POST,OPTIONS"

ENV NGINX_HEADER_SET_Access-Control-Allow-Private-Network=True
ENV NGINX_HEADER_SET_Access-Control-Allow-Methods="GET,POST"