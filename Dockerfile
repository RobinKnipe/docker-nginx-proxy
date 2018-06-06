FROM quay.io/ukhomeofficedigital/alpine-glibc

WORKDIR /root
ADD ./build.sh /root/
RUN ./build.sh

RUN apk update && \
    apk add --no-cache openssl && \
    mkdir -p /etc/keys && \
    openssl req -x509 -newkey rsa:2048 -keyout /etc/keys/key -out /etc/keys/crt -days 360 -nodes -subj '/CN=test'

# This takes a while so best to do it during build
RUN openssl dhparam -out /usr/local/openresty/nginx/conf/dhparam.pem 2048

RUN apk add bind-libs bind-dev dnsmasq

ADD ./naxsi/location.rules /usr/local/openresty/naxsi/location.template

ADD ./nginx*.conf /usr/local/openresty/nginx/conf/
RUN mkdir /usr/local/openresty/nginx/conf/locations
RUN mkdir -p /usr/local/openresty/nginx/lua
ADD ./lua/* /usr/local/openresty/nginx/lua/
RUN md5sum /usr/local/openresty/nginx/conf/nginx.conf | cut -d' ' -f 1 > /container_default_ngx
ADD ./defaults.sh ./go.sh ./enable_location.sh ./location_template.conf ./readyness.sh ./helper.sh ./refresh_GeoIP.sh /
ADD ./logging.conf /usr/local/openresty/nginx/conf/
ADD ./html/ /usr/local/openresty/nginx/html/

RUN apk add shadow && \
    useradd -u 1000 nginx

RUN install -o nginx -g nginx -d /usr/local/openresty/naxsi/locations \
                                 /usr/local/openresty/nginx/{client_body,fastcgi,proxy,scgi,uwsgi}_temp && \
    chown -R nginx:nginx /usr/local/openresty/nginx/{conf,logs} /usr/share/GeoIP

RUN apk del shadow

WORKDIR /usr/local/openresty

ENTRYPOINT ["/bin/sh"]

EXPOSE 10080
EXPOSE 10443
USER 1000
