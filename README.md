# nginx-docker

 Enhanced Nginx Alpine Dockerfile with Modules.
 Based on <https://github.com/ZoeyVid/nginx-quic/>

## build

```shell
docker build -t nginx:1.25.4 .
# or
docker buildx build --no-cache --build-arg "NGINX_VER=1.25.4" --build-arg "BUILD=docker-quic" -t nginx:1.25.4 .
```

## use

View version information

```shell
$ docker run -it --rm --entrypoint /bin/sh nginx:1.25.4 -c 'nginx -V'
nginx version: nginx/1.25.4 (quic)
built by gcc 13.2.1 20231014 (Alpine 13.2.1_git20231014)
built with OpenSSL 3.1.5+quic 30 Jan 2024
TLS SNI support enabled
configure arguments: --prefix=/etc/nginx --build=quic --builddir=build --with-threads --with-file-aio --with-http_ssl_module --with-http_v2_module --with-http_v3_module --with-http_realip_module --with-http_addition_module --with-http_xslt_module --with-http_image_filter_module --with-http_geoip_module --with-http_sub_module --with-http_dav_module --with-http_mp4_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_auth_request_module --with-http_secure_link_module --with-http_degradation_module --with-http_slice_module --with-http_stub_status_module --with-http_perl_module --with-mail --with-mail_ssl_module --with-stream --with-stream_ssl_module --with-stream_realip_module --with-stream_geoip_module --with-stream_ssl_preread_module --add-module=src/module/nginx-rtmp-module --add-module=src/module/njs/nginx --add-module=src/module/ngx_http_geoip2_module --add-module=src/module/ngx-fancyindex --add-module=src/module/ngx_devel_kit --add-module=src/module/ngx_brotli --add-module=src/module/ModSecurity-nginx --add-module=src/module/lua-nginx-module --add-module=src/module/headers-more-nginx-module --with-pcre --with-pcre-jit --with-libatomic --with-openssl=../openssl --with-debug
```

**All files are in `/etc/nginx` (/etc/nginx/conf/nginx.conf)**

## compose

```shell
vim compose.yaml

docker compose up -d
# For some distributions use this
docker-compose up -d
```