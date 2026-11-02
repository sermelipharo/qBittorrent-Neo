#!/bin/bash
# Puts a trimmed Python 3.13 into the app, so search plugins work on a Mac
# without Homebrew (macOS's own /usr/bin/python3 is 3.9, older than the
# search scripts need).
#
# The interpreter is a python-build-standalone build, pinned by release and
# SHA-256 and kept in a cache outside the repository. It is trimmed (Tk,
# IDLE, pip, tests, headers), compiled to bytecode once, copied to
# DEST and signed with the app's identity, inside out.
#
# Usage: scripts/embed-python.sh DEST [SIGN_IDENTITY]
#   DEST           e.g. "qBit NeoRS.app/Contents/Resources/python"
#   SIGN_IDENTITY  codesign identity; "-" (default) signs ad hoc
#
# QBT_PYTHON_CACHE overrides the cache folder.
set -euo pipefail

RELEASE=20261013
VERSION=3.13.16
NAME="cpython-$VERSION+$RELEASE-aarch64-apple-darwin-install_only_stripped.tar.gz"
SHA256=16a5332fb0dcb77f163fc8f8cbccd95be1644cc53e68e5d2a79f50afd6680a0e
URL="https://github.com/astral-sh/python-build-standalone/releases/download/$RELEASE/${NAME//+/%2B}"

DEST="${1:?usage: $0 DEST [SIGN_IDENTITY]}"
IDENTITY="${2:--}"
CACHE="${QBT_PYTHON_CACHE:-$HOME/Library/Caches/qbt-neors-python}"
ARCHIVE="$CACHE/$NAME"
# Trimmed and compiled tree, rebuilt when this script changes.
STAMP="$(shasum -a 256 "$0" | cut -c1-16)"
TREE="$CACHE/$VERSION-$RELEASE-$STAMP"

mkdir -p "$CACHE"
if [[ ! -f "$ARCHIVE" ]] || [[ "$(shasum -a 256 "$ARCHIVE" | cut -d' ' -f1)" != "$SHA256" ]]; then
    curl --fail --location --silent --show-error --proto '=https' --tlsv1.2 -o "$ARCHIVE.part" "$URL"
    actual="$(shasum -a 256 "$ARCHIVE.part" | cut -d' ' -f1)"
    if [[ "$actual" != "$SHA256" ]]; then
        rm -f "$ARCHIVE.part"
        echo "error: $NAME has SHA-256 $actual, expected $SHA256" >&2
        exit 1
    fi
    mv "$ARCHIVE.part" "$ARCHIVE"
fi

if [[ ! -x "$TREE/bin/python3.13" ]]; then
    WORK="$(mktemp -d "$CACHE/build.XXXXXX")"
    trap 'rm -rf "$WORK"' EXIT
    tar -xzf "$ARCHIVE" -C "$WORK"
    P="$WORK/python"
    LIB="$P/lib/python3.13"
    # Only the interpreter itself; `python3` stays as a link to it. The
    # interpreter links Python statically, so libpython is for embedding only.
    find "$P/bin" -mindepth 1 ! -name python3.13 ! -name python3 -delete
    rm -rf "$P/include" "$P/share" "$P/lib/pkgconfig" "$P/lib"/itcl* "$P/lib"/tcl* "$P/lib"/tk* \
        "$P/lib"/thread* "$P/lib"/libtcl* "$P/lib"/libpython*
    # Tk, IDLE, pip, the test suite, the REPL and the build configuration.
    rm -rf "$LIB"/lib-dynload/_tkinter.* "$LIB"/{tkinter,idlelib,turtledemo,ensurepip,pydoc_data,test,_pyrepl} \
        "$LIB"/turtle.py "$LIB"/config-3.13-darwin "$LIB"/site-packages/*
    find "$P" -name __pycache__ -type d -prune -exec rm -rf {} +
    # Bytecode that never needs its source's timestamp, so the copy in the
    # signed bundle is used as is and never rewritten. The build
    # folder is stripped from the recorded source paths (they hold the home
    # folder); imports put the real path back.
    "$P/bin/python3.13" -I -B -m compileall -f -q -j 0 --invalidation-mode unchecked-hash -s "$P" -p / "$LIB" >/dev/null
    # Trees left by earlier versions of this script.
    find "$CACHE" -mindepth 1 -maxdepth 1 -type d -name "$VERSION-*" -exec rm -rf {} +
    mv "$P" "$TREE"
    rm -rf "$WORK"
    trap - EXIT
fi

mkdir -p "$DEST"
rsync -a --delete "$TREE/" "$DEST/"
# License texts of CPython and the libraries linked into this build (from
# the release's full archive; see scripts/python-licenses).
mkdir -p "$DEST/licenses"
cp "$(dirname "$0")"/python-licenses/LICENSE.*.txt "$DEST/licenses/"

# Inside out: extension modules, then the interpreter. Ad-hoc code has no
# team, so library validation would refuse the modules under the hardened
# runtime; only a team-signed interpreter gets the runtime.
# Release builds signed by a team get a secure timestamp (notarization).
runtime=(--options runtime)
timestamp=--timestamp=none
[[ "$IDENTITY" == "-" ]] && runtime=()
[[ "$IDENTITY" != "-" && "${CONFIGURATION:-}" == "Release" ]] && timestamp=--timestamp
find "$DEST/lib" -type f \( -name '*.so' -o -name '*.dylib' \) -print0 |
    xargs -0 codesign --force --sign "$IDENTITY" "$timestamp"
codesign --force --sign "$IDENTITY" "$timestamp" ${runtime[@]+"${runtime[@]}"} "$DEST/bin/python3.13"
