ARG base=debian:bullseye
FROM ${base} AS choco_builder

ARG CROSS_PACKAGES

RUN apt-get update && \
    apt-get install -y file git curl \
        gcc automake build-essential pkg-config \
        cross-config ${CROSS_PACKAGES}

WORKDIR /chocpkg
RUN git clone --depth 1 https://github.com/chocolate-doom/chocpkg.git .

COPY chocpkg-custom/chocolate-doom.sh ./pkgdef/
COPY chocpkg-custom/buildenv.sh ./

ARG CHOCOLATE_DOOM_GIT=https://github.com/chocolate-doom/chocolate-doom.git
ARG CHOCOLATE_DOOM_COMMIT=master
ARG BUILD_HOST
ARG MAKE_OPTS=-j4
ARG LATEST_PACKAGES=chocolate-doom
RUN printf " \
#!/bin/bash \
# Buildenv header \
CHOCOLATE_DOOM_GIT=${CHOCOLATE_DOOM_GIT} \
CHOCOLATE_DOOM_COMMIT=${CHOCOLATE_DOOM_COMMIT} \
BUILD_HOST=${BUILD_HOST} \
MAKE_OPTS=${MAKE_OPTS} \
LATEST_PACKAGES=${LATEST_PACKAGES} \
\
$(cat buildenv.sh) \
" > buildenv.sh

RUN chocpkg/chocpkg install libpng 
RUN chocpkg/chocpkg install libsamplerate 
RUN chocpkg/chocpkg install SDL2 
RUN chocpkg/chocpkg install SDL2_mixer
RUN chocpkg/chocpkg install SDL2_net

RUN chocpkg/chocpkg install chocolate-doom

ARG BUILD_VERSION
ENV BUILD_VERSION ${BUILD_VERSION}
RUN mv install chocolate-doom
RUN bash -c '. buildenv.sh && tar cvvfz chocolate-doom_${BUILD_VERSION:-${CHOCOLATE_DOOM_COMMIT}_${BUILD_HOST:-$(uname -m)}}.tar.gz chocolate-doom'

CMD echo Extract the chocolate-doom artifact from the image: $(ls chocolate-doom_*)

FROM scratch

COPY --from=choco_builder /chocpkg/chocolate-doom_*.tar.gz /