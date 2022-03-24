ARG BUILD_FROM=ghcr.io/hassio-addons/base/amd64

# https://hub.docker.com/_/alpine
FROM alpine:3.15.2 as build
# https://github.com/eikek/sharry/releases
ENV SHARRY_VERSION=1.9.0

RUN set -eux; \
    apk update; \
    apk add --no-cache --virtual .build-deps \
        unzip=6.0-r9 \
        curl=7.80.0-r0 \
        ; \
    mkdir -p /opt; \
    curl -J -L -o /tmp/sharry.zip \
        "https://github.com/eikek/sharry/releases/download/v${SHARRY_VERSION}/sharry-restserver-${SHARRY_VERSION}.zip"; \
    unzip /tmp/sharry.zip -d /opt; \
    mv /opt/sharry-restserver-${SHARRY_VERSION} /opt/sharry; \
    rm /tmp/sharry.zip;


# https://github.com/hassio-addons/addon-base/releases
FROM ${BUILD_FROM}:11.0.1

RUN set -eux; \
    apk update; \
    apk add --no-cache \
        mariadb-client=10.6.4-r2 \
        netcat-openbsd=1.130-r3 \
        openjdk11-jre=11.0.14_p9-r0 \
        ; \
    java -version; \
    \
    echo "Add user for Sharry" \
    mkdir -p /data/sharry; \
    addgroup -S abc; \
    adduser -u 12345 -h /data/sharry -D -S abc -G abc;
    
# Add Sharry
COPY --from=build --chown=abc:abc /opt/sharry /opt/sharry

COPY rootfs /
WORKDIR /data/sharry

# Build arguments
ARG BUILD_ARCH
ARG BUILD_DATE
ARG BUILD_DESCRIPTION
ARG BUILD_NAME
ARG BUILD_REF
ARG BUILD_REPOSITORY
ARG BUILD_VERSION

# Labels
LABEL \
    io.hass.name="${BUILD_NAME}" \
    io.hass.description="${BUILD_DESCRIPTION}" \
    io.hass.arch="${BUILD_ARCH}" \
    io.hass.type="addon" \
    io.hass.version=${BUILD_VERSION} \
    maintainer="mdegat01" \
    org.opencontainers.image.title="${BUILD_NAME}" \
    org.opencontainers.image.description="${BUILD_DESCRIPTION}" \
    org.opencontainers.image.vendor="mdegat01's Home Assistant Add-ons" \
    org.opencontainers.image.authors="mdegat01" \
    org.opencontainers.image.licenses="MIT" \
    org.opencontainers.image.url="https://github.com/mdegat01/hassio-addons" \
    org.opencontainers.image.source="https://github.com/${BUILD_REPOSITORY}" \
    org.opencontainers.image.documentation="https://github.com/${BUILD_REPOSITORY}/blob/main/README.md" \
    org.opencontainers.image.created=${BUILD_DATE} \
    org.opencontainers.image.revision=${BUILD_REF} \
    org.opencontainers.image.version=${BUILD_VERSION}
