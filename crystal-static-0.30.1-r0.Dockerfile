FROM pgeraghty/alpine-crystal:0.29 as builder

RUN apk update && \
    apk -U add alpine-sdk && \
    adduser -D packager && addgroup packager abuild
    
USER packager

WORKDIR /home/packager

RUN abuild-keygen -a -n

RUN mkdir crystal && cd crystal && \
    wget -O APKBUILD https://git.alpinelinux.org/aports/plain/community/crystal/APKBUILD?id=392da78032556dfc5ebcd6de9e9bc0718e959515 && \
    wget -O disable-specs-using-GB2312-encoding.patch https://git.alpinelinux.org/aports/plain/community/crystal/disable-specs-using-GB2312-encoding.patch?id=392da78032556dfc5ebcd6de9e9bc0718e959515 && \
    wget -O fix-spec-std-kernel-spec.cr.patch https://git.alpinelinux.org/aports/plain/community/crystal/fix-spec-std-kernel-spec.cr.patch?id=392da78032556dfc5ebcd6de9e9bc0718e959515 && \    
    BUILD_STATIC=1 abuild clean deps unpack prepare build check


USER root
RUN apk add git
RUN apk del crystal shards

USER packager
WORKDIR /home/packager

RUN echo $(llvm-config --host-target)

RUN mkdir shards && cd shards && \
    wget -O APKBUILD https://git.alpinelinux.org/aports/plain/community/shards/APKBUILD?h=3.9-stable && \
    abuild deps unpack prepare && \
    cd src/shards-0.8.1 && \    
    make CRYSTAL="/home/packager/crystal/src/crystal-0.30.1/bin/crystal" CRFLAGS="--verbose --release --static --target \"x86_64-alpine-linux-musl\"" && \
    cd ../.. && abuild check
    # EMAIL="Test User <user@example.com>" make -d test_integration


FROM alpine:edge
WORKDIR /

COPY --from=builder /home/packager/crystal/src/crystal-0.30.1/.build/crystal /bin
COPY --from=builder /home/packager/shards/src/shards-0.8.1/bin/shards /bin

RUN apk add --update --no-cache --force-overwrite \
        git \
        g++ \
        gc-dev \
        gcc \
        gmp-dev \
        libatomic_ops \
        libevent-dev \
        libevent-static \
        libxml2-dev \       
        make \
        musl-dev \ 
        openssl-dev \
        pcre-dev \
        readline-dev \
        tzdata \
        yaml-dev \
        zlib-dev
