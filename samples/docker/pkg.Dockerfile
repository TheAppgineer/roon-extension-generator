ARG build_arch=amd64        # amd64, armhf, arm64

# Phase 1: Create the extension binary
FROM multiarch/debian-debootstrap:${build_arch}-buster-slim

ARG build_arch
ARG pkg_arch=x64            # x64,   armv6, arm64
ARG node_version=v12.18.1

WORKDIR /home/node

COPY app.js package.json /home/node/

RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates git npm && \
    npm config set unsafe-perm true && \
    npm config set strict-ssl false && \
    npm install -g pkg@4.5.1 && \
    mkdir -p ~/.pkg-cache/v2.6 && \
    if [ "${pkg_arch}" != "x64" ]; then \
    wget https://github.com/yao-pkg/pkg-binaries/releases/download/node12/fetched-${node_version}-linux-${pkg_arch} \
    -O ~/.pkg-cache/v2.6/fetched-${node_version}-linux-${pkg_arch}; \
    fi && \
    chmod -R +x ~/.pkg-cache/v2.6/ && \
    npm install && \
    pkg -t node12-linux-${pkg_arch} .


# Phase 2: Create the run time image containing the extension binary
FROM multiarch/debian-debootstrap:${build_arch}-buster-slim

RUN useradd -ms /bin/sh node && \
    apt-get update && \
    apt-get install -y libatomic1

WORKDIR /home/node

COPY --from=0 /home/node/app ./

USER node

CMD [ "./app" ]
