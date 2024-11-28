# nginx-docker

 Enhanced Nginx (essentially OpenResty) Alpine Docker Image with Modules.
 Based on [ZoeyVid/nginx-quic](https://github.com/ZoeyVid/nginx-quic)

## Use

Build or pull

```bash
docker build -t nginx:1.27.3 .

docker pull albaz64/nginx:1.27.3
```

Check version

```bash
$ docker run -it --rm --entrypoint /bin/sh albaz64/nginx:devel -c 'nginx -V'
nginx version: nginx/1.27.3 (11-29-2024)
built by gcc 13.2.1 20240309 (Alpine 13.2.1_git20240309) 
built with OpenSSL 3.1.7+quic 3 Sep 2024
TLS SNI support enabled
configure arguments: --prefix=/etc/nginx --build=11-29-2024 --builddir=build --with-threads --with-file-aio --with-http_addition_module --with-http_auth_request_module --with-http_dav_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_image_filter_module --with-http_mp4_module --with-http_perl_module --with-http_random_index_module --with-http_realip_module --with-http_secure_link_module --with-http_slice_module --with-http_ssl_module --with-http_stub_status_module --with-http_sub_module --with-http_v2_module --with-http_v3_module --with-http_xslt_module --with-mail --with-mail_ssl_module --with-stream --with-stream_realip_module --with-stream_ssl_module --with-stream_ssl_preread_module --add-module=/3rd/njs/nginx --add-module=/3rd/brotli --add-module=/3rd/lua_http --add-module=/3rd/lua_stream --add-module=/3rd/echo --add-module=/3rd/headers --add-module=/3rd/vts --add-module=/3rd/geoip2 --add-module=/3rd/fancyindex --add-module=/3rd/ndk --add-module=/3rd/modsecurity --add-module=/3rd/substitutions_filter --add-module=/3rd/dav_ext --add-module=/3rd/rtmp --with-cc-opt='-m64 -march=native -mtune=native -Ofast -pipe -fomit-frame-pointer -fno-plt -fexceptions -flto -funroll-loops -ffunction-sections -fdata-sections -D_FORTIFY_src=2 -fstack-clash-protection -fcf-protection -Wformat -Werror=format-security -fPIC -DNGX_QUIC_DEBUG_PACKETS -DNGX_QUIC_DEBUG_CRYPTO' --with-ld-opt='-Wl,-s -Wl,-Bsymbolic -Wl,--gc-sections,--as-needed,-z,relro,-z,now -flto=auto' --with-pcre-jit --with-openssl=/src/openssl --with-debug
```

**All files are in `/etc/nginx` (/etc/nginx/conf/nginx.conf)**

> nginx.conf `http` need `lua_package_path "/etc/nginx/lib/lua/?.lua;;";`

If warn this↓ add `variables_hash_max_size 2048;` to `http`
`nginx: [warn] could not build optimal variables_hash, you should increase either ariables_hash_max_size: 1024 or variables_hash_bucket_size: 64; ignoring variables_hash_bucket_size`

### Modules

- [NJS](https://github.com/nginx/njs)
- [Brotli](https://github.com/google/ngx_brotli)
- [Lua(http)](https://github.com/openresty/lua-nginx-module)
- [Lua(stream)](https://github.com/openresty/stream-lua-nginx-module)
- [Echo](https://github.com/openresty/echo-nginx-module)
- [Headers More](https://github.com/openresty/headers-more-nginx-module)
- [Virtual host Traffic Status](https://github.com/vozlt/nginx-module-vts)
- [GeoIP2](https://github.com/leev/ngx_http_geoip2_module)
- [Fancyindex](https://github.com/aperezdc/ngx-fancyindex)
- [NDK](https://github.com/vision5/ngx_devel_kit)
- [ModSecurity](https://github.com/SpiderLabs/ModSecurity-nginx)
- [Regex Substitutions](https://github.com/yaoweibin/ngx_http_substitutions_filter_module)
- [WebDav](https://github.com/arut/nginx-dav-ext-module)
- [RTMP](https://github.com/arut/nginx-rtmp-module)

## Compose

You can try this and check if everything works.It listen on port 211.

```bash
vim compose.yaml

docker compose up -d
# For some distributions use this
docker-compose up -d
```

## Test

### HTTP/3

HTTP/3 QUIC work on the **TLS**.

Ensure that your curl supports HTTP3.

```bash
curl --resolve <domain.tld>:<port>:<IP> --http3 -IL https://domain.tld
```

## Maybe add

- <https://github.com/masterzen/nginx-upload-progress-module>
- <https://github.com/evanmiller/mod_zip>
- <https://github.com/tokers/zstd-nginx-module>
- <https://github.com/onnimonni/redis-nginx-module>
- <https://github.com/openresty/redis2-nginx-module>
- <https://github.com/wargio/naxsi/>
