#!/bin/zsh
# Builds libtorrent-rasterbar (RC_2_0 series) as a static library into
# build/deps. qBittorrent 5.2.4 supports libtorrent 1.2.19+ and 2.0.10+ but
# not the 2.1 series that Homebrew ships, so it is built from source.
set -euo pipefail

ROOT="${0:A:h:h}"
LT_TAG="${LT_TAG:-v2.0.15}"
SRC="$ROOT/build/src/libtorrent"
OBJ="$ROOT/build/obj/libtorrent"
PREFIX="$ROOT/build/deps"

if [[ -f "$PREFIX/lib/libtorrent-rasterbar.a" && "${1:-}" != "--force" ]]; then
    echo "libtorrent already built in $PREFIX (pass --force to rebuild)"
    exit 0
fi

if [[ ! -d "$SRC" ]]; then
    mkdir -p "${SRC:h}"
    git clone -q --depth 1 --branch "$LT_TAG" --recurse-submodules --shallow-submodules \
        https://github.com/arvidn/libtorrent.git "$SRC"
fi

cmake -S "$SRC" -B "$OBJ" \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_CXX_STANDARD=20 \
    -Ddeprecated-functions=OFF \
    -DCMAKE_OSX_ARCHITECTURES=arm64 \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=27.0 \
    -DCMAKE_INSTALL_PREFIX="$PREFIX" \
    -DOPENSSL_ROOT_DIR=/opt/homebrew/opt/openssl@3 \
    -DCMAKE_PREFIX_PATH="/opt/homebrew/opt/boost;/opt/homebrew/opt/openssl@3"
nice -n 10 cmake --build "$OBJ" -j"${QBTNEO_JOBS:-4}"
cmake --install "$OBJ"
# Intermediate objects are not needed once installed.
rm -rf "$OBJ"
