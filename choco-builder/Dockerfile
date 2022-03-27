ARG base=debian:bullseye
FROM ${base} AS system_builder

ARG CROSS_PACKAGES
RUN apt-get update && \
    apt-get install -y file git curl \
        gcc automake build-essential pkg-config \
        cross-config ${CROSS_PACKAGES}

FROM system_builder AS choco_builder

WORKDIR /chocpkg
RUN git clone --depth 1 https://github.com/chocolate-doom/chocpkg.git .

COPY chocpkg-custom/chocolate-doom.sh ./pkgdef/
COPY chocpkg-custom/buildenv.sh ./

ARG BUILD_VERSION
ARG CHOCOLATE_DOOM_GIT=https://github.com/chocolate-doom/chocolate-doom.git
ARG CHOCOLATE_DOOM_COMMIT=master
ARG BUILD_HOST
ARG MAKE_OPTS=-j4
ARG LATEST_PACKAGES=chocolate-doom
ARG CFLAGS=

ENV BUILD_VERSION=${BUILD_VERSION}
ENV CHOCOLATE_DOOM_GIT=${CHOCOLATE_DOOM_GIT}
ENV CHOCOLATE_DOOM_COMMIT=${CHOCOLATE_DOOM_COMMIT}
ENV BUILD_HOST=${BUILD_HOST}
ENV MAKE_OPTS=${MAKE_OPTS}
ENV LATEST_PACKAGES=${LATEST_PACKAGES}
ENV CFLAGS=${CFLAGS}

RUN printf "\
$(echo \#!/bin/bash)\n\
$(echo \# Buildenv header)\n\
\n\
$(bash -c 'declare -px BUILD_VERSION CHOCOLATE_DOOM_GIT CHOCOLATE_DOOM_COMMIT BUILD_HOST MAKE_OPTS LATEST_PACKAGES CFLAGS')\n\
\n\
$(echo \# Commence main buildenv.sh)\n\
\n\
$(cat buildenv.sh) \
" > buildenv.sh

RUN chocpkg/chocpkg install libpng 
RUN chocpkg/chocpkg install libsamplerate 
RUN chocpkg/chocpkg install SDL2 
RUN chocpkg/chocpkg install SDL2_mixer
RUN chocpkg/chocpkg install SDL2_net

RUN chocpkg/chocpkg install chocolate-doom

COPY chocpkg-custom/archive.sh .
RUN bash archive.sh

CMD echo Extract the chocolate-doom artifact from the image: $(ls chocolate-doom_*)

FROM scratch

COPY --from=choco_builder /chocpkg/chocolate-doom_*.tar.gz /