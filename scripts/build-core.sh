#!/bin/zsh
# Builds the qBittorrent core bridge (build/core/libqbtneocore.dylib):
# libtorrent (once), then qBittorrent's src/base + src/webui and the bridge.
# Usage: scripts/build-core.sh [Release|RelWithDebInfo|Debug]
set -euo pipefail

ROOT="${0:A:h:h}"
CONFIG="${1:-${QBTNEO_CORE_CONFIG:-Release}}"
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
# Xcode's environment must not leak into the CMake build.
unset SDKROOT MACOSX_DEPLOYMENT_TARGET ARCHS CC CXX LD LDFLAGS CFLAGS CXXFLAGS OTHER_LDFLAGS 2>/dev/null || true

"$ROOT/scripts/build-deps.sh"

BUILD="$ROOT/build/core"
if [[ ! -f "$BUILD/CMakeCache.txt" ]] || ! grep -q "CMAKE_BUILD_TYPE:STRING=$CONFIG" "$BUILD/CMakeCache.txt"; then
    cmake -S "$ROOT/core" -B "$BUILD" \
        -DCMAKE_BUILD_TYPE="$CONFIG" \
        -DCMAKE_OSX_ARCHITECTURES=arm64 \
        -DCMAKE_OSX_DEPLOYMENT_TARGET=27.0 \
        -DQT_NO_PRIVATE_MODULE_WARNING=ON \
        -DCMAKE_PREFIX_PATH="$ROOT/build/deps;/opt/homebrew/opt/qt;/opt/homebrew/opt/boost;/opt/homebrew/opt/openssl@3"
fi
nice -n 10 cmake --build "$BUILD" --target qbtneocore -j"${QBTNEO_JOBS:-4}"
