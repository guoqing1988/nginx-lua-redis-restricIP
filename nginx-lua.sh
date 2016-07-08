#!/bin/bash
set -xe
BUILD_DIR=/opt/nginx
BUILD_SP=/tmp/nginx
NGINX_VER="1.10.1"
LUAJIT_VER="2.0.4"
	
# Install dependence packages for nginx-build
apt-get update && apt-get install -y wget \
    git \
    libpcre3-dev \
    libpcre++-dev \
    build-essential \
    libssl-dev \
#Create temp dir for build workspace
if [ ! -z "${BUILD_SP}" ] && [ ! -d "${BUILD_SP}" ]; then
   mkdir -p "${BUILD_SP}"
fi
cd ${BUILD_SP}
rm -rf *
# Download and untar source code
wget https://nginx.org/download/nginx-${NGINX_VER}.tar.gz -O  nginx-${NGINX_VER}.tar.gz 
wget http://luajit.org/download/LuaJIT-${LUAJIT_VER}.tar.gz -O  LuaJIT-${LUAJIT_VER}.tar.gz
git  clone  https://github.com/openresty/lua-resty-redis.git -b master lua-resty-redis
git  clone  https://github.com/simpl/ngx_devel_kit.git  -b  master  nginx-devel-kit 
git  clone  https://github.com/openresty/lua-nginx-module.git -b master lua-nginx-module


cp -r lua-resty-redis  /usr/local/lua-resty-redis
tar -vxzf LuaJIT-${LUAJIT_VER}.tar.gz  LuaJIT-${LUAJIT_VER}
tar -vxzf nginx-${NGINX_VER}.tar.gz    nginx-${NGINX_VER}

cd ${BUILD_SP}/LuaJIT-${LUAJIT_VER} && make PREFIX=/usr/local/jit  && make install PREFIX=/usr/local/jit
cd ${BUILD_SP}/lua-redis-parse && make LUA_INCLUDE_DIR=/usr/local/jit/include/luajit-2.0 && make install LUA_LIB_DIR=/usr/local/lualib

export LUAJIT_LIB=/usr/local/jit/lib
export LUAJIT_INC=/usr/local/jit/include/luajit-2.0


cd ${BUILD_SP}/nginx-${NGINX_VER}
./configure --prefix=${BUILD_DIR} \
    --with-ld-opt="-Wl,-rpath,${LUAJIT_LIB}" \
    --add-module=${BUILD_SP}/nginx-devel-kit \
    --add-module=${BUILD_SP}/lua-nginx-module \
    --user=nginx                          \
    --group=nginx                         \
    --pid-path=/var/run/nginx.pid         \
    --lock-path=/var/run/nginx.lock       \
    --with-http_gzip_static_module        \
    --with-http_stub_status_module        \
    --with-http_ssl_module                \
    --with-pcre                           \
    --with-file-aio                       \
    --with-http_realip_module             \
    --without-http_scgi_module            \
    --without-http_uwsgi_module           \
    --without-http_fastcgi_module

make
make install
