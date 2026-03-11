FROM alpine:3.23 AS base
ARG ARCH=x86-64

FROM base AS deps
RUN apk add --no-cache \
    ca-certificates linux-headers build-base git patch wget \
    clang lld llvm pkgconf \
    autoconf automake libtool \
    zlib-dev pcre2-dev openssl-dev \
    libxml2-dev libxslt-dev gd-dev libmaxminddb-dev brotli-dev \
    yajl-dev curl-dev lmdb-dev libfuzzy2-dev

FROM deps AS modsecurity
ARG ARCH
WORKDIR /src
RUN git clone --depth 1 --recurse-submodules https://github.com/owasp-modsecurity/ModSecurity.git
WORKDIR /src/ModSecurity
RUN ./build.sh && \
    export CC=clang CXX=clang++ && \
    export CFLAGS="-march=$ARCH -O3 -pipe -flto=auto -fPIC -fstack-clash-protection -fcf-protection -D_FORTIFY_SOURCE=2" && \
    export CXXFLAGS="$CFLAGS" && \
    export LDFLAGS="-fuse-ld=lld -flto=auto -Wl,-z,relro -Wl,-z,now -Wl,-z,pack-relative-relocs" && \
    ./configure \
        --prefix=/usr/local/modsecurity \
        --with-maxmind --with-lmdb --with-pcre2 --with-pic \
        --disable-doxygen-doc --disable-examples && \
    make -j"$(nproc)" && make install && \
    strip -s src/.libs/libmodsecurity.so.3

FROM deps AS modules
WORKDIR /src/submods
RUN git clone --depth 1 https://github.com/nginx/njs.git && \
    git clone --depth 1 --recurse-submodules -j8 https://github.com/google/ngx_brotli.git brotli && \
    git clone --depth 1 https://github.com/openresty/echo-nginx-module.git echo && \
    git clone --depth 1 https://github.com/openresty/headers-more-nginx-module.git headers && \
    git clone --depth 1 https://github.com/vozlt/nginx-module-vts.git vts && \
    git clone --depth 1 https://github.com/leev/ngx_http_geoip2_module.git geoip2 && \
    git clone --depth 1 https://github.com/aperezdc/ngx-fancyindex.git fancyindex && \
    git clone --depth 1 https://github.com/vision5/ngx_devel_kit.git ndk && \
    git clone --depth 1 https://github.com/owasp-modsecurity/ModSecurity-nginx.git modsecurity && \
    git clone --depth 1 https://github.com/yaoweibin/ngx_http_substitutions_filter_module.git substitutions_filter && \
    git clone --depth 1 https://github.com/arut/nginx-dav-ext-module.git dav_ext && \
    git clone --depth 1 https://github.com/arut/nginx-rtmp-module.git rtmp

FROM deps AS nginx-src
ARG NGINX_VER=release-1.29.5
WORKDIR /src
RUN git clone --depth 1 --branch "$NGINX_VER" https://github.com/nginx/nginx.git
RUN cd nginx && \
    wget -qO- https://raw.githubusercontent.com/nginx-modules/ngx_http_tls_dyn_size/master/nginx__dynamic_tls_records_1.29.2%2B.patch | git apply

FROM nginx-src AS build
ARG BUILD=03-09-2026
ARG NGX_PREFIX=/etc/nginx
ARG ARCH
COPY --from=modsecurity /usr/local/modsecurity /usr/local/modsecurity
COPY --from=modsecurity /src/ModSecurity/src/.libs/libmodsecurity.so.3 /usr/local/lib/
COPY --from=modules /src/submods /src/submods
RUN ldconfig /usr/local/lib
WORKDIR /src/nginx
RUN export CC=clang CXX=clang++ && \
    ./auto/configure \
        --prefix=$NGX_PREFIX \
        --build=$BUILD \
        --with-threads --with-file-aio \
        --with-http_realip_module \
        --with-http_addition_module \
        --with-http_xslt_module \
        --with-http_image_filter_module \
        --with-http_sub_module \
        --with-http_dav_module \
        --with-http_mp4_module \
        --with-http_gunzip_module \
        --with-http_gzip_static_module \
        --with-http_auth_request_module \
        --with-http_random_index_module \
        --with-http_secure_link_module \
        --with-http_slice_module \
        --with-http_stub_status_module \
        --with-http_ssl_module \
        --with-http_v2_module \
        --with-http_v3_module \
        --with-mail \
        --with-mail_ssl_module \
        --with-stream \
        --with-stream_realip_module \
        --with-stream_ssl_module \
        --with-stream_ssl_preread_module \
        --add-module=/src/submods/njs/nginx \
        --add-module=/src/submods/brotli \
        --add-module=/src/submods/echo \
        --add-module=/src/submods/headers \
        --add-module=/src/submods/vts \
        --add-module=/src/submods/geoip2 \
        --add-module=/src/submods/fancyindex \
        --add-module=/src/submods/ndk \
        --add-module=/src/submods/modsecurity \
        --add-module=/src/submods/substitutions_filter \
        --add-module=/src/submods/dav_ext \
        --add-module=/src/submods/rtmp \
        --with-cc-opt="-march=$ARCH -O3 -pipe -flto=auto -fPIC -fno-plt -ffunction-sections -fdata-sections -fstack-clash-protection -fcf-protection -D_FORTIFY_SOURCE=2 -Wno-sign-compare -Wformat -Werror=format-security" \
        --with-ld-opt="-fuse-ld=lld -flto=auto -Wl,-O1 -Wl,--sort-common -Wl,-s -Wl,--gc-sections -Wl,--as-needed -Wl,--no-copy-dt-needed-entries -Wl,-z,pack-relative-relocs -Wl,-z,nodlopen -Wl,-z,relro -Wl,-z,now -Wl,-z,noexecstack" \
        --with-pcre-jit && \
    make -j"$(nproc)" && make install && \
    rm $NGX_PREFIX/conf/*.default && \
    $NGX_PREFIX/sbin/nginx -V

FROM alpine:3.23
RUN apk add --no-cache \
    ca-certificates tzdata tini \
    pcre2 zlib brotli-libs libssl3 libxml2 libxslt libgd libmaxminddb-libs \
    libstdc++ libgcc libcurl yajl lmdb libfuzzy2

ARG NGX_PREFIX=/etc/nginx
WORKDIR $NGX_PREFIX

COPY --from=build $NGX_PREFIX $NGX_PREFIX
COPY --from=modsecurity /src/ModSecurity/src/.libs/libmodsecurity.so.3 /usr/local/lib/
COPY --from=modsecurity /src/ModSecurity/unicode.mapping $NGX_PREFIX/conf/include/
COPY --from=modsecurity /src/ModSecurity/modsecurity.conf-recommended $NGX_PREFIX/conf/include/

RUN ln -s $NGX_PREFIX/sbin/nginx /usr/sbin/nginx && ldconfig /usr/local/lib

ENTRYPOINT ["tini", "--", "nginx"]
CMD ["-g", "daemon off;"]
