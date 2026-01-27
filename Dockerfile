FROM alpine:latest AS build
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

# CORE
ARG BUILD=01-26-2026
ARG NGX_PREFIX=/etc/nginx
ARG NGINX_VER=release-1.29.4
ARG ARCH=x86-64-v3

WORKDIR /src

RUN apk add --no-cache \
    # --- Core toolchain ---
    ca-certificates linux-headers build-base git patch \
    clang lld llvm pkgconf \
    # ModSecurity
    autoconf automake libtool \
    # --- Nginx deps ---
    zlib-dev pcre2-dev openssl-dev \
    libxml2-dev libxslt-dev gd-dev libmaxminddb-dev brotli-dev \
    # --- ModSecurity deps ---
    yajl-dev curl-dev lmdb-dev libfuzzy2-dev

###### START BUILD

# Build libmodsecurity
RUN git clone --depth 1 --recurse-submodules https://github.com/owasp-modsecurity/ModSecurity.git && \
    cd /src/ModSecurity && \
    /src/ModSecurity/build.sh && \
    # Same with Nginx
    # export CFLAGS="-march=x86-64-v3 -O3 -pipe -flto=auto -fPIC -fstack-clash-protection -fcf-protection -D_FORTIFY_SOURCE=2" && \
    # export CXXFLAGS="-march=x86-64-v3 -O3 -pipe -flto=auto -fPIC -fstack-clash-protection -fcf-protection -D_FORTIFY_SOURCE=2" && \
    # export LDFLAGS="-fuse-ld=lld -flto=auto -Wl,-z,relro -Wl,-z,now -Wl,-z,pack-relative-relocs" && \
    /src/ModSecurity/configure \
    --prefix=/usr/local/modsecurity \
    --with-maxmind \
    --with-lmdb \
    --with-pcre2 \
    --with-pic \
    --disable-doxygen-doc \
    --disable-examples && \
    make -j"$(nproc)" && make install && strip -s /src/ModSecurity/src/.libs/libmodsecurity.so.3

###### END BUILD

# Modules
WORKDIR /src/submods
RUN git clone --depth 1 https://github.com/nginx/njs.git njs && \
    git clone --depth 1 --recurse-submodules -j8 https://github.com/google/ngx_brotli.git brotli && \
    git clone --depth 1 https://github.com/openresty/echo-nginx-module.git echo && \
    git clone --depth 1 https://github.com/openresty/headers-more-nginx-module.git headers && \
    # Virtual host Traffic Status
    git clone --depth 1 https://github.com/vozlt/nginx-module-vts.git vts && \
    git clone --depth 1 https://github.com/leev/ngx_http_geoip2_module.git geoip2 && \
    git clone --depth 1 https://github.com/aperezdc/ngx-fancyindex.git fancyindex && \
    git clone --depth 1 https://github.com/vision5/ngx_devel_kit.git ndk && \
    git clone --depth 1 https://github.com/owasp-modsecurity/ModSecurity-nginx.git modsecurity && \
    git clone --depth 1 https://github.com/yaoweibin/ngx_http_substitutions_filter_module.git substitutions_filter && \
    git clone --depth 1 https://github.com/arut/nginx-dav-ext-module.git dav_ext && \
    git clone --depth 1 https://github.com/arut/nginx-rtmp-module.git rtmp

WORKDIR /src

# Build Nginx from github source
RUN git clone https://github.com/nginx/nginx.git --branch "$NGINX_VER" && \
    cd nginx && \
    git diff && \
    git apply < <(wget -qO- https://raw.githubusercontent.com/nginx-modules/ngx_http_tls_dyn_size/refs/heads/master/nginx__dynamic_tls_records_1.29.2%2B.patch)

RUN export CC=clang && export CXX=clang++ && \
    cd nginx && \
    ./auto/configure \
    --prefix=$NGX_PREFIX \
    --build=$BUILD \
    --with-threads --with-file-aio \
    # HTTP
    --with-http_realip_module \
    --with-http_addition_module \
    # libxml2 libxslt
    --with-http_xslt_module \
    # libgd
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
    # perl
    # --with-http_perl_module \
    # OpenSSL
    --with-http_ssl_module \
    --with-http_v2_module \
    --with-http_v3_module \
    # MAIL
    --with-mail \
    --with-mail_ssl_module \
    # STREAM
    --with-stream \
    --with-stream_realip_module \
    # OpenSSL
    --with-stream_ssl_module \
    --with-stream_ssl_preread_module \
    # 3rd-party modules
    --add-module=/src/submods/njs/nginx \
    --add-module=/src/submods/brotli \
    --add-module=/src/submods/echo \
    --add-module=/src/submods/headers \
    --add-module=/src/submods/vts \
    # libmaxminddb
    --add-module=/src/submods/geoip2 \
    --add-module=/src/submods/fancyindex \
    --add-module=/src/submods/ndk \
    --add-module=/src/submods/modsecurity \
    --add-module=/src/submods/substitutions_filter \
    --add-module=/src/submods/dav_ext \
    --add-module=/src/submods/rtmp \
    # --with-cc-opt='-march=x86-64-v3 -O3 -pipe -flto=auto -fPIC -fno-plt -fstack-clash-protection -fcf-protection -D_FORTIFY_SOURCE=2 -Wno-sign-compare -Wformat -Werror=format-security -ffunction-sections -fdata-sections' \
    # --with-ld-opt='-fuse-ld=lld -flto=auto -Wl,-s -Wl,-O1 -Wl,--gc-sections -Wl,--as-needed -Wl,-z,relro -Wl,-z,now -Wl,-z,pack-relative-relocs -Wl,-z,noexecstack -Wl,-z,nodlopen -Wl,--no-copy-dt-needed-entries -Wl,--sort-common' \
    --with-cc-opt="-march=$ARCH -O3 -pipe -flto=auto -fPIC -fno-plt -ffunction-sections -fdata-sections -fstack-clash-protection -fcf-protection -D_FORTIFY_SOURCE=2 -Wno-sign-compare -Wformat -Werror=format-security" \
    --with-ld-opt="-fuse-ld=lld -flto=auto -Wl,-O1 -Wl,--sort-common -Wl,-s -Wl,--gc-sections -Wl,--as-needed -Wl,--no-copy-dt-needed-entries -Wl,-z,pack-relative-relocs -Wl,-z,nodlopen -Wl,-z,relro -Wl,-z,now -Wl,-z,noexecstack" \
    --with-pcre-jit && \
    make -j"$(nproc)" && make install && \
    rm $NGX_PREFIX/conf/*.default && \
    $NGX_PREFIX/sbin/nginx -V

FROM alpine:latest
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

RUN apk add --no-cache \
    ca-certificates tzdata tini \
    # Nginx
    pcre2 zlib brotli-libs libssl3 libxml2 libxslt libgd libmaxminddb-libs \
    # ModSecurity
    libstdc++ libgcc libcurl yajl lmdb libfuzzy2

ARG NGX_PREFIX=/etc/nginx
WORKDIR $NGX_PREFIX

COPY --from=build $NGX_PREFIX                                     $NGX_PREFIX
COPY --from=build /src/ModSecurity/src/.libs/libmodsecurity.so.3 /usr/local/lib/libmodsecurity.so.3
COPY --from=build /src/ModSecurity/unicode.mapping               $NGX_PREFIX/conf/include/unicode.mapping
COPY --from=build /src/ModSecurity/modsecurity.conf-recommended  $NGX_PREFIX/conf/include/modsecurity.conf-recommended

RUN ln -s $NGX_PREFIX/sbin/nginx /usr/sbin/nginx && ldconfig /usr/local/lib

ENTRYPOINT ["tini", "--", "nginx"]
CMD ["-g", "daemon off;"]
