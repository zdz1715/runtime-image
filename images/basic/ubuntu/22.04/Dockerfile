FROM ubuntu:22.04

ARG TZ
ARG MIRROR_URL

ENV TZ=${TZ} \
    MIRROR_URL=${MIRROR_URL}

COPY _*.sh /

RUN set -eux; \
    /_prepare.sh; \
    apt-get update; \
    DEBIAN_FRONTEND=noninteractive apt-get install -qqy --no-install-recommends --no-install-suggests \
        ca-certificates \
        tzdata \
    ; \
    rm -rf /tmp/* /var/lib/apt/lists/*

ENTRYPOINT ["/_prepare.sh"]