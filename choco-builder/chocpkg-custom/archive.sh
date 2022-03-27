#!/bin/bash

. buildenv.sh
DIST=chocolate-doom_${BUILD_VERSION:-${CHOCOLATE_DOOM_COMMIT}_${BUILD_HOST:-$(uname -m)}}

mv install "$DIST"
tar cvvfz "$DIST.tar.gz" "$DIST"