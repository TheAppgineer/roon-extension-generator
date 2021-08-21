ARG build_arch=amd64        # amd64, armv7, arm64

# Phase 1: Create the extension binary
FROM multiarch/alpine:${build_arch}-v3.12

ARG build_arch
ARG pkg_arch=x64            # x64,   armv6, arm64
ARG node_version=v12.18.1

WORKDIR /home/node

COPY app.js package.json /home/node/

RUN apk add --no-cache git npm && \
    npm install -g pkg@4.5.1 && \
    mkdir -p ~/.pkg-cache/v2.6 && \
    if [ "${pkg_arch}" != "x64" ]; then \
    wget https://github.com/yao-pkg/pkg-binaries/releases/download/node12/fetched-${node_version}-alpine-${pkg_arch} \
    -O ~/.pkg-cache/v2.6/fetched-${node_version}-alpine-${pkg_arch}; \
    fi && \
    chmod -R +x ~/.pkg-cache/v2.6/ && \
    npm install && \
    pkg -t node12-alpine-${pkg_arch} .


# Phase 2: Create the run time image containing the extension binary
FROM multiarch/alpine:${build_arch}-v3.12

RUN apk add --no-cache libgcc libstdc++ && \
    addgroup -g 1000 node && adduser -u 1000 -G node -s /bin/sh -D node

WORKDIR /home/node

COPY --from=0 /home/node/app ./

USER node

CMD [ "./app" ]
