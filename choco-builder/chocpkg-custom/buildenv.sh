#!/bin/bash

if [ "$BUILD_HOST" != "" ]; then
  IS_CROSS_COMPILE=true
else
  IS_CROSS_COMPILE=false
fi

# Necessary to respect the custom GIT above
LATEST_PACKAGES=$LATEST_PACKAGES
LATEST_PACKAGES+=(chocolate-doom)

if [[ "$BUILD_HOST" = "" ]] && [ $(uname) = "Darwin" ]; then
    LDFLAGS="-lobjc ${LDFLAGS:-}"
    MACOSX_DEPLOYMENT_TARGET=10.7
    export LDFLAGS MACOSX_DEPLOYMENT_TARGET
elif [[ "$BUILD_HOST" =~ mingw ]]; then
    # MingW builds need the -static-libgcc option, otherwise we
    # will depend on an unnecessary DLL, libgcc_s_sjlj-1.dll. Note that
    # this specifically needs to be done via the CC environment variable
    # rather than CFLAGS/LDFLAGS, otherwise libtool strips it out.
    CC="${BUILD_HOST}-gcc -static-libgcc"
    export CC
else
    # Include $INSTALL_DIR/lib in the list of paths that is searched
    # when looking for DLLs. This allows built binaries to be run
    # without needing to set LD_LIBRARY_PATH every time.
    LDFLAGS="-Wl,-rpath -Wl,$INSTALL_DIR/lib ${LDFLAGS:-}"
    export LDFLAGS
fi