#!/bin/zsh
# Runs one scripted UI scenario (Debug builds, see App/UIScenarios.swift)
# against a scratch profile and captures the app's own windows whenever the
# scenario asks for it (shot-<name>.req -> window-shot.swift -> .ack).
#
# Usage: scripts/ui-scenario.sh <App.app> <profile-dir> <ui-dir> <scenario> [VAR=value ...]
#   VAR=value pairs are passed to the app (QBT_UI_TORRENT, QBT_UI_MAGNET, ...).
# The app is launched with `open -g -n` (never activated); its windows stay
# nearly transparent and click-through while the scenario runs. The script
# returns when the app exits (or after QBT_UI_TIMEOUT seconds, default 900,
# when it quits the app). UIDRIVER lines are printed to stdout.
set -eu
APP="${1:A}"; PROFILE="${2:A}"; UIDIR="$3"; SCENARIO="$4"; shift 4
SHOT="${0:A:h}/window-shot.swift"
TIMEOUT="${QBT_UI_TIMEOUT:-900}"
mkdir -p "$PROFILE" "$UIDIR"
LOG="$UIDIR/$SCENARIO.log"
: > "$LOG"
ENVS=(--env "QBT_UI_SCRIPT=$SCENARIO" --env "QBT_UI_DIR=$UIDIR")
for pair in "$@"; do ENVS+=(--env "$pair"); done

open -g -n "${ENVS[@]}" --stderr "$LOG" --stdout /dev/null "$APP" --args --profile "$PROFILE"
BIN="$APP/Contents/MacOS/qBittorrent Neo"
PID=""
for _ in {1..240}; do
    PID=$(pgrep -nf "^$BIN --profile $PROFILE" || true)
    [[ -n "$PID" ]] && break
    sleep 0.25
done
[[ -n "$PID" ]] || { echo "app did not start"; exit 1; }
echo "pid $PID, log $LOG"

START=$SECONDS
while kill -0 "$PID" 2>/dev/null; do
    for req in "$UIDIR"/shot-*.req(N); do
        name="${${req:t}%.req}"
        sleep 0.6
        swift "$SHOT" "$PID" "$UIDIR/$name" >/dev/null 2>&1 || true
        rm -f "$req"
        touch "$UIDIR/$name.ack"
    done
    if (( SECONDS - START > TIMEOUT )); then
        echo "timeout after $TIMEOUT s; quitting the app"
        kill -TERM "$PID" 2>/dev/null || true
        sleep 15
        kill -KILL "$PID" 2>/dev/null || true
        break
    fi
    sleep 0.5
done
grep "UIDRIVER" "$LOG" || true
echo "passed: $(grep -c 'UIDRIVER: PASS' "$LOG" || true), failed: $(grep -c 'UIDRIVER: FAIL' "$LOG" || true)"
