# nginx-docker

 Enhanced Nginx Alpine Docker Image with Modules.
 Based on [ZoeyVid/nginx-quic](https://github.com/ZoeyVid/nginx-quic)

## Use

Build or pull

```bash
docker build -t nginx:1.27.0 .

docker pull albaz64/nginx:1.27.0
```

Check version

```bash
$ docker run -it --rm --entrypoint /bin/sh nginx:1.27.0 -c 'nginx -V'
nginx version: nginx/1.27.0 (20240630)
built by gcc 13.2.1 20240309 (Alpine 13.2.1_git20240309) 
built with OpenSSL 3.1.5+quic 30 Jan 2024
TLS SNI support enabled
configure arguments: --prefix=/etc/nginx --build=20240630 --builddir=build --with-threads --with-file-aio --with-http_ssl_module --with-http_v2_module --with-http_v3_module --with-http_realip_module --with-http_addition_module --with-http_xslt_module --with-http_image_filter_module --with-http_geoip_module --with-http_sub_module --with-http_dav_module --with-http_mp4_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_auth_request_module --with-http_secure_link_module --with-http_degradation_module --with-http_slice_module --with-http_stub_status_module --with-http_perl_module --with-mail --with-mail_ssl_module --with-stream --with-stream_ssl_module --with-stream_realip_module --with-stream_geoip_module --with-stream_ssl_preread_module --add-module=src/module/nginx-rtmp-module --add-module=src/module/njs/nginx --add-module=src/module/ngx_http_geoip2_module --add-module=src/module/ngx-fancyindex --add-module=src/module/ngx_devel_kit --add-module=src/module/ngx_brotli --add-module=src/module/ModSecurity-nginx --add-module=src/module/lua-nginx-module --add-module=src/module/headers-more-nginx-module --add-module=src/module/echo-nginx-module --add-module=src/module/nginx-module-vts --with-cc-opt='-march=x86-64 -O2 -pipe -fomit-frame-pointer -fno-plt -fexceptions -D_FORTIFY_src=2 -fstack-clash-protection -fcf-protection -Wformat -Werror=format-security -DNGX_QUIC_DEBUG_PACKETS -DNGX_QUIC_DEBUG_CRYPTO' --with-ld-opt='-Wl,--as-needed,-z,relro,-z,now -flto=auto' --with-pcre --with-pcre-jit --with-libatomic --with-openssl=../openssl --with-debug
```

**All files are in `/etc/nginx` (/etc/nginx/conf/nginx.conf)**

> nginx.conf `http` add
`lua_package_path "/etc/nginx/lib/lua/?.lua;;";`

### Modules

- [RTMP](https://github.com/arut/nginx-rtmp-module)
- [NJS](https://github.com/nginx/njs)
- [GeoIP2](https://github.com/leev/ngx_http_geoip2_module)
- [Fancyindex](https://github.com/aperezdc/ngx-fancyindex)
- [Devel Kit](https://github.com/vision5/ngx_devel_kit)
- [Brotli](https://github.com/google/ngx_brotli)
- [ModSecurity](https://github.com/SpiderLabs/ModSecurity-nginx)
- [Lua](https://github.com/openresty/lua-nginx-module)
- [Headers More](https://github.com/openresty/headers-more-nginx-module)
- [Echo](https://github.com/openresty/echo-nginx-module)
- [Virtual host Traffic Status](https://github.com/vozlt/nginx-module-vts)

## Compose

```bash
vim compose.yaml

docker compose up -d
# For some distributions use this
docker-compose up -d
```
