FROM abyssviper/softethervpn:v4.39-9772-src as build

LABEL maintainer="iutx<root@viper.run>"

ENV VERSION="v5.02-5180"

RUN /bin/sed -i 's,https://dl-cdn.alpinelinux.org,https://mirrors.aliyun.com,g' /etc/apk/repositories

WORKDIR /opt

# COPY libsodium-1.0.18.tar.gz /opt
# RUN tar -zxvf libsodium-1.0.18.tar.gz \
RUN apk add --no-cache -U build-base ncurses-dev openssl-dev readline-dev zlib-dev cmake libsodium-dev
#    && cd libsodium-1.0.18 \
#    && ./configure \
#    && make \
#    && make install \
#    && cp -rf src/libsodium/.libs/libsodium.so.23.3.0 /opt

COPY softether-src.tar.gz /opt
RUN tar -zxvf softether-src.tar.gz \
    && cd ${VERSION} \
    && ./configure \
    && make -C build \
    && mv build /opt

FROM alpine:3.16

LABEL maintainer="iutx<root@viper.run>"

ENV LANG=en_US.UTF-8
ENV VERSION="v4.39-9772"

WORKDIR /opt/vpnserver
RUN mkdir -p /usr/local/lib
COPY --from=build /opt/build/*.so /usr/local/lib/
COPY --from=build /opt/build/vpn* /bin/
COPY --from=build /opt/build/vpn* ./
COPY --from=build /opt/build/hamcore.se2 .
COPY --from=build /opt/build/hamcore.se2 /bin/
# COPY --from=build /opt/libsodium.so.23.3.0 /usr/local/lib
RUN echo "kernel.dmesg_restrict=0" >> /etc/sysctl.conf
RUN /bin/sed -i 's,https://dl-cdn.alpinelinux.org,https://mirrors.aliyun.com,g' /etc/apk/repositories
RUN  apk add --no-cache -U bash iptables openssl-dev
RUN apk add --no-cache -U ncurses-dev openssl-dev readline-dev zlib-dev libsodium-dev

VOLUME ["/opt/vpnserver/server_log/", "/opt/vpnserver/packet_log/", "/opt/vpnserver/security_log/"]

EXPOSE 500 4500 1701 1194 5555 443 1723 1193

CMD ["./vpnserver", "execsvc"]
