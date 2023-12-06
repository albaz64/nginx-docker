# nginx-docker

 Enhanced Nginx Alpine Dockerfile with Modules.
 Based on <https://github.com/ZoeyVid/nginx-quic/>

## build

```shell
docker buildx build --no-cache --build-arg "NGINX_VER=1.25.3" --build-arg "BUILD=nginx_build_version" -t nginx:docker .
```

## use

View version information

```shell
$ docker run -it --rm --entrypoint /bin/sh <user/image:tag> -c 'nginx -V'
nginx version: nginx/1.25.3 (quic)
built by gcc 12.2.1 20220924 (Alpine 12.2.1_git20220924-r10)
built with OpenSSL 3.1.4+quic 24 Oct 2023
TLS SNI support enabled
configure arguments: --with-debug --with-compat --build=quic --prefix=/etc/nginx --with-threads --with-libatomic --with-file-aio --with-http_ssl_module --with-http_v2_module --with-http_v3_module --with-http_realip_module --with-http_addition_module --with-http_xslt_module --with-http_image_filter_module --with-http_sub_module --with-http_dav_module --with-http_flv_module --with-http_mp4_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_auth_request_module --with-http_random_index_module --with-http_secure_link_module --with-http_degradation_module --with-http_slice_module --with-http_stub_status_module --with-http_perl_module --with-http_geoip_module --with-mail --with-mail_ssl_module --with-stream --with-stream_ssl_module --with-stream_realip_module --with-stream_ssl_preread_module --with-compat --with-pcre --with-pcre-jit --with-openssl=../openssl --add-module=src/module/ngx_brotli --add-module=src/module/ngx_http_geoip2_module --add-module=src/module/headers-more-nginx-module --add-module=src/module/ngx-fancyindex --add-module=src/module/njs/nginx --add-module=src/module/ngx_devel_kit --add-module=src/module/ModSecurity-nginx --add-module=src/module/nginx-rtmp-module
```

All files are in `/etc/nginx` (/etc/nginx/conf/nginx.conf)
