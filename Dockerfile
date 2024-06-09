FROM alpine AS build

ARG BUILD=20240606
ARG NGINX_VER=1.27.0

ARG LUAJIT_INC=/usr/include/luajit-2.1
ARG LUAJIT_LIB=/usr/lib

WORKDIR /src

RUN apk update && apk add --no-cache ca-certificates build-base patch cmake git libtool autoconf automake \
    libatomic_ops-dev zlib-dev luajit-dev pcre2-dev linux-headers yajl-dev libxml2-dev libxslt-dev perl-dev curl-dev lmdb-dev libfuzzy2-dev lua5.1-dev lmdb-dev geoip-dev libmaxminddb-dev gd-dev

# OpenSSL
RUN git clone --recursive https://github.com/quictls/openssl

# lua
RUN mkdir lua && \
    git clone --recursive https://github.com/openresty/lua-resty-core lua/lua-resty-core && \
    git clone --recursive https://github.com/openresty/lua-resty-lrucache lua/lua-resty-lrucache

# modules
RUN mkdir -p /src/nginx/src/module && cd /src/nginx/src/module && \
    git clone --recursive https://github.com/arut/nginx-rtmp-module && \
    git clone --recursive https://github.com/nginx/njs && \
    git clone --recursive https://github.com/leev/ngx_http_geoip2_module && \
    git clone --recursive https://github.com/aperezdc/ngx-fancyindex && \
    git clone --recursive https://github.com/vision5/ngx_devel_kit && \
    git clone --recursive https://github.com/google/ngx_brotli && \
    git clone --recursive https://github.com/SpiderLabs/ModSecurity-nginx && \
    git clone --recursive https://github.com/openresty/lua-nginx-module && \
    git clone --recursive https://github.com/openresty/headers-more-nginx-module && \
    git clone --recursive https://github.com/openresty/echo-nginx-module.git

# WAF
RUN git clone --recursive https://github.com/owasp-modsecurity/ModSecurity && \
    cd /src/ModSecurity && \
    /src/ModSecurity/build.sh && /src/ModSecurity/configure --with-pcre2 --with-lmdb && \
    make -j"$(expr $(nproc) + 1)" && make install && \
    strip -s /usr/local/modsecurity/lib/libmodsecurity.so.3

# build
RUN cd /src/nginx && wget -O - https://nginx.org/download/nginx-$NGINX_VER.tar.gz | tar -zxf - --strip-components=1 && \
    patch -p1 < <(curl -sSL https://raw.githubusercontent.com/nginx-modules/ngx_http_tls_dyn_size/master/nginx__dynamic_tls_records_1.25.1%2B.patch) && \
    patch -p1 < <(curl -sSL https://raw.githubusercontent.com/openresty/openresty/master/patches/nginx-1.25.3-resolver_conf_parsing.patch) && \
    /src/nginx/configure \
        --prefix=/etc/nginx \
        # --user=http --group=http \
        --build=$BUILD --builddir=build \
        --with-threads --with-file-aio \
        --with-http_ssl_module --with-http_v2_module --with-http_v3_module \
        --with-http_realip_module --with-http_addition_module --with-http_xslt_module --with-http_image_filter_module \
        --with-http_geoip_module --with-http_sub_module --with-http_dav_module --with-http_mp4_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_auth_request_module --with-http_secure_link_module --with-http_degradation_module --with-http_slice_module --with-http_stub_status_module \
        --with-http_perl_module \
        # --http-client-body-temp-path=temp/client_body_temp --http-proxy-temp-path=temp/proxy_temp --http-fastcgi-temp-path=temp/fastcgi_temp --http-uwsgi-temp-path=temp/uwsgi_temp --http-scgi-temp-path=temp/scgi_temp \
        --with-mail --with-mail_ssl_module \
        --with-stream --with-stream_ssl_module --with-stream_realip_module --with-stream_geoip_module --with-stream_ssl_preread_module \
        --add-module=src/module/nginx-rtmp-module \
        --add-module=src/module/njs/nginx \
        --add-module=src/module/ngx_http_geoip2_module \
        --add-module=src/module/ngx-fancyindex \
        --add-module=src/module/ngx_devel_kit \
        --add-module=src/module/ngx_brotli \
        --add-module=src/module/ModSecurity-nginx \
        --add-module=src/module/lua-nginx-module \
        --add-module=src/module/headers-more-nginx-module \
        --add-module=src/module/echo-nginx-module \
        --with-cc-opt='-march=x86-64 -O2 -pipe -fomit-frame-pointer -fno-plt -fexceptions -D_FORTIFY_src=2 -fstack-clash-protection -fcf-protection -Wformat -Werror=format-security -DNGX_QUIC_DEBUG_PACKETS -DNGX_QUIC_DEBUG_CRYPTO' \
        --with-ld-opt='-Wl,--as-needed,-z,relro,-z,now -flto=auto' \
        --with-pcre --with-pcre-jit \
        --with-libatomic \
        --with-openssl=../openssl \
        --with-debug && \
    make -j"$(expr $(nproc) + 1)" && make install && rm /etc/nginx/conf/*.default && strip -s /etc/nginx/sbin/nginx

# openresty need bash
RUN apk add bash && cd /src/lua/lua-resty-core && make install PREFIX=/etc/nginx && cd /src/lua/lua-resty-lrucache && make install PREFIX=/etc/nginx

FROM python:alpine
COPY --from=build /etc/nginx                                     /etc/nginx
COPY --from=build /usr/local/lib/perl5                           /usr/local/lib/perl5
COPY --from=build /usr/lib/perl5/core_perl/perllocal.pod         /usr/lib/perl5/core_perl/perllocal.pod
COPY --from=build /usr/local/modsecurity/lib/libmodsecurity.so.3 /usr/local/modsecurity/lib/libmodsecurity.so.3
COPY --from=build /src/ModSecurity/unicode.mapping               /etc/nginx/conf/conf.d/include/unicode.mapping
COPY --from=build /src/ModSecurity/modsecurity.conf-recommended  /etc/nginx/conf/conf.d/include/modsecurity.conf.example

RUN apk update && apk add --no-cache ca-certificates tzdata tini zlib luajit pcre2 libstdc++ yajl libxml2 libxslt perl libcurl lmdb libfuzzy2 lua5.1-libs geoip libmaxminddb-libs gd && ln -s /etc/nginx/sbin/nginx /usr/sbin/nginx
ENTRYPOINT ["tini", "--", "nginx"]
CMD ["-g", "daemon off;"]
