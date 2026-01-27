# nginx-docker

 Enhanced Nginx (essentially OpenResty) Alpine Docker Image with Modules.
 Based on [ZoeyVid/nginx-quic](https://github.com/ZoeyVid/nginx-quic)

## Use

Build or pull

```bash
docker build -t nginx:latest .

docker pull albaz64/nginx:latest
```

Check version

```bash
$ docker run -it --rm --entrypoint /bin/sh docker.io/albaz64/nginx:latest -c 'nginx -V'
nginx version: nginx/1.29.4 (01-26-2026)
built by clang 21.1.2
built with OpenSSL 3.5.4 30 Sep 2025
TLS SNI support enabled
configure arguments: --prefix=/etc/nginx --build=01-26-2026 --with-threads --with-file-aio --with-http_realip_module --with-http_addition_module --with-http_xslt_module --with-http_image_filter_module --with-http_sub_module --with-http_dav_module --with-http_mp4_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_auth_request_module --with-http_random_index_module --with-http_secure_link_module --with-http_slice_module --with-http_stub_status_module --with-http_ssl_module --with-http_v2_module --with-http_v3_module --with-mail --with-mail_ssl_module --with-stream --with-stream_realip_module --with-stream_ssl_module --with-stream_ssl_preread_module --add-module=/src/submods/njs/nginx --add-module=/src/submods/brotli --add-module=/src/submods/echo --add-module=/src/submods/headers --add-module=/src/submods/vts --add-module=/src/submods/geoip2 --add-module=/src/submods/fancyindex --add-module=/src/submods/ndk --add-module=/src/submods/modsecurity --add-module=/src/submods/substitutions_filter --add-module=/src/submods/dav_ext --add-module=/src/submods/rtmp --with-cc-opt='-march=x86-64-v3 -O3 -pipe -flto=auto -fPIC -fno-plt -ffunction-sections -fdata-sections -fstack-clash-protection -fcf-protection -D_FORTIFY_SOURCE=2 -Wno-sign-compare -Wformat -Werror=format-security' --with-ld-opt='-fuse-ld=lld -flto=auto -Wl,-O1 -Wl,--sort-common -Wl,-s -Wl,--gc-sections -Wl,--as-needed -Wl,--no-copy-dt-needed-entries -Wl,-z,pack-relative-relocs -Wl,-z,nodlopen -Wl,-z,relro -Wl,-z,now -Wl,-z,noexecstack' --with-pcre-jit
```

**All files are in `/etc/nginx` (/etc/nginx/conf/nginx.conf)**

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
