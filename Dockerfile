FROM alpine:3.18.5 AS build

ARG BUILD=quic
ARG NGINX_VER=1.25.3

ARG LUAJIT_INC=/usr/include/luajit-2.1
ARG LUAJIT_LIB=/usr/lib

WORKDIR /src
# src
# - openssl
# - ModSecurity
# - nginx
# - nginx/src/module/*
# - lua/*

# compile
# ModSecurity + nginx
# lua openssl module > nginx

RUN apk update && apk add --no-cache ca-certificates build-base patch cmake git libtool autoconf automake \
    libatomic_ops-dev zlib-dev luajit-dev pcre2-dev linux-headers yajl-dev libxml2-dev libxslt-dev perl-dev curl-dev lmdb-dev lua5.1-dev lmdb-dev geoip-dev libmaxminddb-dev gd-dev

# OpenSSL
RUN git clone --recursive https://github.com/quictls/openssl --branch openssl-3.1.4+quic /src/openssl

# lua
RUN mkdir lua && cd lua && \
git clone --recursive https://github.com/openresty/lua-resty-core && \
git clone --recursive https://github.com/openresty/lua-resty-lrucache && \
# modules
mkdir -p /src/nginx/src/module && cd /src/nginx/src/module && \
git clone --recursive https://github.com/google/ngx_brotli && \
git clone --recursive https://github.com/aperezdc/ngx-fancyindex && \
git clone --recursive https://github.com/openresty/headers-more-nginx-module && \
git clone --recursive https://github.com/nginx/njs && \
git clone --recursive https://github.com/vision5/ngx_devel_kit && \
git clone --recursive https://github.com/openresty/lua-nginx-module && \
git clone --recursive https://github.com/SpiderLabs/ModSecurity-nginx && \
git clone --recursive https://github.com/leev/ngx_http_geoip2_module && \
git clone --recursive https://github.com/arut/nginx-rtmp-module

# WAF & build
RUN git clone --recursive https://github.com/SpiderLabs/ModSecurity && \
cd /src/ModSecurity && \
/src/ModSecurity/build.sh && /src/ModSecurity/configure --with-pcre2 --with-lmdb && \
make -j"$(expr $(nproc) + 1)" && make install && \
strip -s /usr/local/modsecurity/lib/libmodsecurity.so.3

# nginx build
RUN cd /src/nginx && wget -O - https://nginx.org/download/nginx-$NGINX_VER.tar.gz | tar -zxf - --strip-components=1 && \
patch -p1 < <(curl -sSL https://raw.githubusercontent.com/nginx-modules/ngx_http_tls_dyn_size/master/nginx__dynamic_tls_records_1.25.1%2B.patch) && \
patch -p1 < <(curl -sSL https://raw.githubusercontent.com/openresty/openresty/master/patches/nginx-1.23.0-resolver_conf_parsing.patch) && \
/src/nginx/configure --with-debug --with-compat --build=${BUILD} \
# --user=http --group=http \
--prefix=/etc/nginx \
# --http-client-body-temp-path=temp/client_body_temp --http-proxy-temp-path=temp/proxy_temp --http-fastcgi-temp-path=temp/fastcgi_temp --http-scgi-temp-path=temp/scgi_temp --http-uwsgi-temp-path=temp/uwsgi_temp \
--with-threads --with-libatomic --with-file-aio --with-http_ssl_module --with-http_v2_module --with-http_v3_module --with-http_realip_module --with-http_addition_module --with-http_xslt_module --with-http_image_filter_module --with-http_sub_module \
--with-http_dav_module --with-http_flv_module --with-http_mp4_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_auth_request_module \
--with-http_random_index_module --with-http_secure_link_module --with-http_degradation_module --with-http_slice_module --with-http_stub_status_module --with-http_perl_module --with-http_geoip_module \
--with-mail --with-mail_ssl_module --with-stream --with-stream_ssl_module --with-stream_realip_module --with-stream_ssl_preread_module --with-compat --with-pcre --with-pcre-jit \
--with-openssl=../openssl \
# --with-cc-opt='-march=x86-64 -DNGX_QUIC_DEBUG_PACKETS -DNGX_QUIC_DEBUG_CRYPTO -mtune=generic -O2 -pipe -fno-plt -fexceptions -Wp,-D_FORTIFY_src=2 -Wformat -Werror=format-security -fstack-clash-protection -fcf-protection -flto=auto' \
# --with-ld-opt='-Wl,-O1,--sort-common,--as-needed,-z,relro,-z,now -flto=auto' \
--add-module=src/module/ngx_brotli \
--add-module=src/module/ngx_http_geoip2_module \
--add-module=src/module/headers-more-nginx-module \
--add-module=src/module/ngx-fancyindex \
--add-module=src/module/njs/nginx \
--add-module=src/module/ngx_devel_kit \
--add-module=src/module/ModSecurity-nginx \
--add-module=src/module/nginx-rtmp-module && \
make -j"$(expr $(nproc) + 1)" && make install && \
strip -s /etc/nginx/sbin/nginx && rm /etc/nginx/conf/*.default && \
cd /src/lua/lua-resty-core && make install PREFIX=/etc/nginx && \
cd /src/lua/lua-resty-lrucache && make install PREFIX=/etc/nginx

FROM python:3.12.0-alpine3.18
COPY --from=build /etc/nginx                                     /etc/nginx
COPY --from=build /usr/local/lib/perl5                           /usr/local/lib/perl5
COPY --from=build /usr/lib/perl5/core_perl/perllocal.pod         /usr/lib/perl5/core_perl/perllocal.pod
COPY --from=build /usr/local/modsecurity/lib/libmodsecurity.so.3 /usr/local/modsecurity/lib/libmodsecurity.so.3
RUN apk add --no-cache ca-certificates tzdata tini zlib luajit pcre2 libstdc++ yajl libxml2 libxslt perl libcurl lmdb lua5.1-libs geoip libmaxminddb-libs gd && ln -s /etc/nginx/sbin/nginx /usr/bin/nginx
ENTRYPOINT ["tini", "--", "nginx"]
CMD ["-g", "daemon off;"]
