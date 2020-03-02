FROM openjdk:latest AS jdk

RUN jlink \
    --verbose \
    --compress 2 \
    --no-header-files \
    --no-man-pages \
    --strip-debug \
    --output /jdk \
    --module-path /opt/java/openjdk/jmods \
    --add-modules java.base,java.instrument,java.logging,java.management,java.naming,java.net.http,java.security.jgss,java.security.sasl,java.sql,jdk.crypto.cryptoki,jdk.crypto.ec,jdk.unsupported

FROM alpine:3.8 AS glibc

ENV GLIBC_VER="2.28-r0"
ENV ALPINE_GLIBC_REPO="https://github.com/sgerrand/alpine-pkg-glibc/releases/download"
ENV GCC_LIBS_URL="https://archive.archlinux.org/packages/g/gcc-libs/gcc-libs-8.3.0-1-x86_64.pkg.tar.xz"
ENV GCC_LIBS_SHA256=400e2ecb1b2dfb40e09cdb6805f0075cbc88e6fcef9b73f23c64a6e709dcd61b
ENV ZLIB_URL="https://archive.archlinux.org/packages/z/zlib/zlib-1%3A1.2.11-3-x86_64.pkg.tar.xz"
ENV ZLIB_SHA256=17aede0b9f8baa789c5aa3f358fbf8c68a5f1228c5e6cba1a5dd34102ef4d4e5

RUN apk --update add --no-cache ca-certificates curl openssl binutils xz

RUN curl -Ls https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub -o /etc/apk/keys/sgerrand.rsa.pub \
    && curl -Ls ${ALPINE_GLIBC_REPO}/${GLIBC_VER}/glibc-${GLIBC_VER}.apk > /tmp/${GLIBC_VER}.apk \
    && apk add /tmp/${GLIBC_VER}.apk

RUN curl -Ls ${GCC_LIBS_URL} -o /tmp/gcc-libs.tar.xz \
    && echo "${GCC_LIBS_SHA256}  /tmp/gcc-libs.tar.xz" | sha256sum -c - \
    && mkdir /tmp/gcc \
    && tar -xf /tmp/gcc-libs.tar.xz -C /tmp/gcc \
    && mv /tmp/gcc/usr/lib/libgcc* /tmp/gcc/usr/lib/libstdc++* /usr/glibc-compat/lib

RUN strip /usr/glibc-compat/lib/libgcc_s.so.* /usr/glibc-compat/lib/libstdc++.so*

RUN curl -Ls ${ZLIB_URL} -o /tmp/libz.tar.xz \
    && echo "${ZLIB_SHA256}  /tmp/libz.tar.xz" | sha256sum -c - \
    && mkdir /tmp/libz \
    && tar -xf /tmp/libz.tar.xz -C /tmp/libz \
    && mv /tmp/libz/usr/lib/libz.so* /usr/glibc-compat/lib

FROM alpine:3.8

ENV GLIBC_VER="2.28-r0"

RUN apk --update add --no-cache ca-certificates jq curl

COPY --from=glibc /tmp/${GLIBC_VER}.apk /tmp/${GLIBC_VER}.apk
COPY --from=glibc /etc/apk/keys/sgerrand.rsa.pub /etc/apk/keys/sgerrand.rsa.pub
RUN apk add /tmp/${GLIBC_VER}.apk && rm /tmp/${GLIBC_VER}.apk \
    && rm -rf /var/cache/apk/* && rm -rf /tmp/*

COPY --from=glibc /usr/glibc-compat/lib /usr/glibc-compat/lib
COPY --from=jdk /jdk /opt/jdk/

ENV PATH "/opt/jdk/bin:${PATH}"

RUN echo "PATH=/opt/jdk/bin:\$PATH" >> /etc/enviroment

EXPOSE 8443
HEALTHCHECK --interval=1s --timeout=1s --start-period=10s CMD /bin/sh -c '[[ "$(curl https://localhost:8443/actuator/health --header "X-Forwarded-Proto: https" --insecure | jq -r .status)" == "UP" ]]'

ADD assets/application/service1.jar /application/
ENTRYPOINT ["java", "-jar", "/application/service1.jar"]
