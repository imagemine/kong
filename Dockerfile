FROM kong/kong-gateway:3.4.0.0-debian@sha256:3fc33cb788c1a1722a51c603115f8625380d4700861f1d20866fcaaa26efe895

USER root

RUN apt-get update \
    # Must be separate apt-get invocations because of this bug https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=1039472
    && apt-get install -y ca-certificates-java \
    && apt-get install -y openjdk-17-jre-headless \
    && apt-get remove -y openjdk-11-jre-headless \
    && rm -rf /var/lib/apt/lists/* \
    && java -version 2>&1 | grep 'openjdk version "17\.' \
    && kong version

USER kong
