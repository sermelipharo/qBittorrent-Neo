#!/bin/sh
# Installs the build dependencies on a GitHub-hosted runner (Homebrew bottles:
# prebuilt, so nothing here compiles) and names the libtorrent cache key.
set -eu
export HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_INSTALL_CLEANUP=1
brew install --quiet qtbase qttools boost openssl@3 cmake ccache xcodegen swiftlint
# libtorrent is linked statically against these headers: rebuild it when they change.
echo "deps-key=$(brew list --versions boost openssl@3 | tr ' \n' '-_')" >> "$GITHUB_OUTPUT"
echo "CCACHE_DIR=$HOME/.ccache" >> "$GITHUB_ENV"
echo "CMAKE_C_COMPILER_LAUNCHER=ccache" >> "$GITHUB_ENV"
echo "CMAKE_CXX_COMPILER_LAUNCHER=ccache" >> "$GITHUB_ENV"
echo "QBTNEO_JOBS=3" >> "$GITHUB_ENV"
