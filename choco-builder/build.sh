#/bin/bash
set -ex

export BUILD_VERSION=${BUILD_VERSION:-latest_x86-64}

export BUILD_HOST=$BUILD_HOST
export CROSS_PACKAGES=$CROSS_PACKAGES
export MAKE_OPTS=${MAKE_OPTS:--j4}
export LATEST_PACKAGES=${LATEST_PACKAGES:-chocolate-doom}  # Default necessary to respect the custom git repo/branch
export CFLAGS=

export CHOCOLATE_DOOM_GIT=${CHOCOLATE_DOOM_GIT:-https://github.com/chocolate-doom/chocolate-doom.git}
export CHOCOLATE_DOOM_COMMIT=${CHOCOLATE_DOOM_COMMIT:-master}

export DOCKER_TAG=${DOCKER_TAG:-chocolate-doom_${BUILD_VERSION}}
env | sort
docker build -t $DOCKER_TAG \
    --build-arg BUILD_VERSION \
    --build-arg BUILD_HOST \
    --build-arg CROSS_PACKAGES \
    --build-arg MAKE_OPTS \
    --build-arg LATEST_PACKAGES \
    --build-arg CHOCOLATE_DOOM_GIT \
    --build-arg CHOCOLATE_DOOM_COMMIT \
    --build-arg CFLAGS \
    .
mkdir -p build
CONTAINER_ID=$(docker create $DOCKER_TAG sleep infinity)
docker cp $CONTAINER_ID:/chocolate-doom_${BUILD_VERSION}.tar.gz build/
docker rm -v $CONTAINER_ID