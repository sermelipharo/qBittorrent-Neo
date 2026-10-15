#!/bin/zsh
# Captures the windows of a test instance started with QBT_VERIFY_* (whose
# windows are nearly transparent): makes them opaque for a moment through the
# capture-on flag in QBT_UI_DIR, captures them, and hides them again.
# Usage: scripts/capture.sh <pid> <out-prefix> <ui-dir>
set -eu
touch "$3/capture-on"
sleep 0.7
swift "${0:A:h}/window-shot.swift" "$1" "$2" || true
rm -f "$3/capture-on"
