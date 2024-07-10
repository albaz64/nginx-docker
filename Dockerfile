FROM alpine AS build

ARG BUILD=07-10-2024
ARG NGX_PREFIX=/etc/nginx
ARG NGINX_VER=1.27.0

# lua-resty-* require
ARG LUAJIT_INC=/usr/include/luajit-2.1
ARG LUAJIT_LIB=/usr/lib

WORKDIR /src

# OpenResty need bash now
RUN apk update && apk add --no-cache ca-certificates linux-headers build-base patch cmake git libtool autoconf automake bash \
    libatomic_ops-dev zlib-dev luajit-dev pcre2-dev yajl-dev libxml2-dev libxslt-dev perl-dev curl-dev lmdb-dev libfuzzy2-dev lua5.4-dev geoip-dev libmaxminddb-dev gd-dev

# OpenSSL
RUN git clone --depth 1 https://github.com/quictls/openssl.git

# Lua
RUN mkdir lua && \
    git clone --depth 1 https://github.com/openresty/lua-resty-core.git lua/resty-core && \
    git clone --depth 1 https://github.com/openresty/lua-resty-lrucache.git lua/resty-lrucache

# Modules
RUN mkdir -p /src/nginx/src/module && cd /src/nginx/src/module && \
    # official
    git clone --depth 1 https://github.com/nginx/njs.git njs && \
    # brotli compress
    git clone --depth 1 --recurse-submodules -j8 https://github.com/google/ngx_brotli.git brotli && \
    git clone --depth 1 https://github.com/openresty/lua-nginx-module.git lua_http && \
    git clone --depth 1 https://github.com/openresty/stream-lua-nginx-module.git lua_stream && \
    git clone --depth 1 https://github.com/openresty/echo-nginx-module.git echo && \
    git clone --depth 1 https://github.com/openresty/headers-more-nginx-module.git headers && \
    # Virtual host Traffic Status
    git clone --depth 1 https://github.com/vozlt/nginx-module-vts.git vts && \
    git clone --depth 1 https://github.com/leev/ngx_http_geoip2_module.git geoip2 && \
    git clone --depth 1 https://github.com/aperezdc/ngx-fancyindex.git fancyindex && \
    git clone --depth 1 https://github.com/vision5/ngx_devel_kit.git devel_kit && \
    git clone --depth 1 https://github.com/owasp-modsecurity/ModSecurity-nginx.git modsecurity && \
    git clone --depth 1 https://github.com/yaoweibin/ngx_http_substitutions_filter_module.git substitutions_filter && \
    git clone --depth 1 https://github.com/arut/nginx-dav-ext-module.git dav_ext && \
    git clone --depth 1 https://github.com/arut/nginx-rtmp-module.git rtmp

# Build static brlib
RUN cd /src/nginx/src/module/brotli/deps/brotli && mkdir out && cd out && \
    cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF \
          -DCMAKE_C_FLAGS="-Ofast -m64 -march=native -mtune=native -flto -funroll-loops -ffunction-sections -fdata-sections -Wl,--gc-sections" \
          -DCMAKE_CXX_FLAGS="-Ofast -m64 -march=native -mtune=native -flto -funroll-loops -ffunction-sections -fdata-sections -Wl,--gc-sections" \
          -DCMAKE_INSTALL_PREFIX=./installed .. && \
    cmake --build . --config Release --target brotlienc

# WAF
RUN git clone --depth 1 --recurse-submodules https://github.com/owasp-modsecurity/ModSecurity.git && \
    cd /src/ModSecurity && \
    /src/ModSecurity/build.sh && /src/ModSecurity/configure --with-pcre2 --with-lmdb && \
    make -j"$(nproc)" && make install && \
    strip -s /usr/local/modsecurity/lib/libmodsecurity.so.3

# Build
RUN cd /src/nginx && wget -O - https://nginx.org/download/nginx-$NGINX_VER.tar.gz | tar -zxf - --strip-components=1 && \
    patch -p1 < <(curl -sSL https://raw.githubusercontent.com/nginx-modules/ngx_http_tls_dyn_size/master/nginx__dynamic_tls_records_1.25.1%2B.patch) && \
    patch -p1 < <(curl -sSL https://raw.githubusercontent.com/openresty/openresty/master/patches/nginx-1.27.0-resolver_conf_parsing.patch) && \
    /src/nginx/configure \
        --prefix=$NGX_PREFIX \
        # --user=http --group=http \
        --build=$BUILD --builddir=build \
        --with-threads --with-file-aio \
        # HTTP
        --with-http_addition_module \
        --with-http_auth_request_module \
        --with-http_dav_module \
        # libmaxminddb
        --with-http_geoip_module \
        --with-http_gunzip_module \
        --with-http_gzip_static_module \
        # libgd
        --with-http_image_filter_module \
        --with-http_mp4_module \
        # perl
        --with-http_perl_module \
        --with-http_random_index_module \
        --with-http_realip_module \
        --with-http_secure_link_module \
        --with-http_slice_module \
        # OpenSSL
        --with-http_ssl_module \
        --with-http_stub_status_module \
        --with-http_sub_module \
        --with-http_v2_module \
        --with-http_v3_module \
        # libxml2 libxslt
        --with-http_xslt_module \
        # --http-client-body-temp-path=temp/client_body_temp --http-proxy-temp-path=temp/proxy_temp --http-fastcgi-temp-path=temp/fastcgi_temp --http-uwsgi-temp-path=temp/uwsgi_temp --http-scgi-temp-path=temp/scgi_temp \
        # MAIL
        --with-mail \
        --with-mail_ssl_module \
        # STREAM
        --with-stream \
        --with-stream_geoip_module \
        --with-stream_realip_module \
        --with-stream_ssl_module \
        --with-stream_ssl_preread_module \
        # OTHER
        # --with-google_perftools_module \
        # --with-http_degradation_module \
        # Third-party modules
        --add-module=src/module/njs/nginx \
        --add-module=src/module/brotli \
        --add-module=src/module/lua_http \
        --add-module=src/module/lua_stream \
        --add-module=src/module/echo \
        --add-module=src/module/headers \
        --add-module=src/module/vts \
        --add-module=src/module/geoip2 \
        --add-module=src/module/fancyindex \
        --add-module=src/module/devel_kit \
        --add-module=src/module/modsecurity \
        --add-module=src/module/substitutions_filter \
        --add-module=src/module/dav_ext \
        --add-module=src/module/rtmp \
        # `-m64 -march=native -mtune=native -Ofast` is better than `-march=x86-64 -O2`
        --with-cc-opt='-m64 -march=native -mtune=native -Ofast -pipe -fomit-frame-pointer -fno-plt -fexceptions -flto -funroll-loops -ffunction-sections -fdata-sections -D_FORTIFY_src=2 -fstack-clash-protection -fcf-protection -Wformat -Werror=format-security -DNGX_QUIC_DEBUG_PACKETS -DNGX_QUIC_DEBUG_CRYPTO' \
        --with-ld-opt='-Wl,-s -Wl,-Bsymbolic -Wl,--gc-sections,--as-needed,-z,relro,-z,now -flto=auto' \
        --with-pcre-jit \
        --with-openssl=/src/openssl \
        --with-debug && \
    make -j"$(nproc)" && make install && rm $NGX_PREFIX/conf/*.default && strip -s $NGX_PREFIX/sbin/nginx

RUN cd /src/lua/resty-core && make install PREFIX=$NGX_PREFIX && \
    cd /src/lua/resty-lrucache && make install PREFIX=$NGX_PREFIX && \
    perl /src/openssl/configdata.pm --dump

FROM alpine

VOLUME ["/etc/nginx"]

ARG NGX_PREFIX=/etc/nginx

COPY --from=build $NGX_PREFIX                                     $NGX_PREFIX
COPY --from=build /usr/local/lib/perl5                           /usr/local/lib/perl5
COPY --from=build /usr/lib/perl5/core_perl/perllocal.pod         /usr/lib/perl5/core_perl/perllocal.pod
COPY --from=build /usr/local/modsecurity/lib/libmodsecurity.so.3 /usr/local/modsecurity/lib/libmodsecurity.so.3
COPY --from=build /src/ModSecurity/unicode.mapping               $NGX_PREFIX/conf/conf.d/include/unicode.mapping
COPY --from=build /src/ModSecurity/modsecurity.conf-recommended  $NGX_PREFIX/conf/conf.d/include/modsecurity.conf.example

RUN apk update && apk add --no-cache ca-certificates tzdata tini zlib luajit pcre2 libstdc++ yajl libxml2 libxslt perl libcurl lmdb libfuzzy2 lua5.4-libs geoip libmaxminddb-libs gd && \
    ln -s $NGX_PREFIX/sbin/nginx /usr/sbin/nginx
ENTRYPOINT ["tini", "--", "nginx"]
CMD ["-g", "daemon off;"]
