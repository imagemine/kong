ARG KONG_VERSION
FROM kong/kong-gateway:${KONG_VERSION}-debian

USER root

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# hadolint ignore=DL3008
RUN apt-get update \
    # Must be separate apt-get invocations because of this bug https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=1039472
    && apt-get install --no-install-recommends -y ca-certificates-java \
    && apt-get install --no-install-recommends -y openjdk-17-jre-headless \
    && apt-get remove -y openjdk-11-jre-headless \
    && rm -rf /var/lib/apt/lists/* \
    && ln -s java-17-openjdk-amd64 /usr/lib/jvm/default-jvm \
    && java -version 2>&1 | grep 'openjdk version "17\.' \
    && kong version

USER kong
