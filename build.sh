#!/usr/bin/env sh
# Script to install the openresty from source and to tidy up after...

set -eu
set -o pipefail

OPEN_RESTY_URL='http://openresty.org/download/openresty-1.11.2.4.tar.gz'
LUAROCKS_URL='http://luarocks.org/releases/luarocks-2.4.2.tar.gz'
NAXSI_URL='https://github.com/nbs-system/naxsi/archive/0.55.3.tar.gz'
STATSD_URL='https://github.com/UKHomeOffice/nginx-statsd/archive/0.0.1.tar.gz'
GEOIP_URL='https://github.com/maxmind/geoip-api-c/releases/download/v1.6.11/GeoIP-1.6.11.tar.gz'

# Install dependencies to build from source
apk update
apk add \
    g++ \
    gcc \
    make \
    openssl-dev \
    openssl \
    perl \
    pcre-dev \
    pcre \
    readline \
    readline-dev \
    tar \
    unzip \
    wget
#    pcre \

mkdir -p openresty luarocks naxsi nginx-statsd geoip

# Prepare
wget -qO - "$OPEN_RESTY_URL" | tar xzv --strip-components 1 -C openresty/
wget -qO - "$LUAROCKS_URL"   | tar xzv --strip-components 1 -C luarocks/
wget -qO - "$NAXSI_URL"      | tar xzv --strip-components 1 -C naxsi/
wget -qO - "$STATSD_URL"     | tar xzv --strip-components 1 -C nginx-statsd/
wget -qO - "$GEOIP_URL"      | tar xzv --strip-components 1 -C geoip/

# Build!
cd geoip
./configure
make
make check install
cd ..
rm -fr geoip

cd openresty
./configure --add-module="../naxsi/naxsi_src" \
            --add-module="../nginx-statsd" \
            --with-http_realip_module \
            --with-http_geoip_module \
            --with-http_stub_status_module
make
make install
cd ..

# Install NAXSI default rules...
mkdir -p /usr/local/openresty/naxsi/
cp "./naxsi/naxsi_config/naxsi_core.rules" /usr/local/openresty/naxsi/

rm -fr openresty naxsi nginx-statsd

cd luarocks
./configure --with-lua=/usr/local/openresty/luajit \
    --lua-suffix=jit-2.1.0-beta2 \
    --with-lua-include=/usr/local/openresty/luajit/include/luajit-2.1
make build install
cd ..
rm -fr luarocks

luarocks install uuid
luarocks install luasocket
luarocks install lua-geoip

# Remove the developer tooling
apk del \
    g++ \
    gcc \
    make \
    openssl-dev \
    perl \
    pcre-dev \
    readline \
    readline-dev
