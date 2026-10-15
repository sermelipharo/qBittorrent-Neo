#!/bin/zsh
# Launches the app in the background (`open -g -n`) with a scratch profile,
# lets it settle, then reports idle CPU (ms of CPU time per second, from the
# process' cumulative CPU time), wake-ups per second and
# the physical memory footprint (what Activity Monitor calls "Memory").
# Quits the app afterwards.
#
# Footprint is read after <settle> seconds, CPU and wake-ups (interrupt
# wake-ups from proc_pid_rusage, see rusage.swift) over the next <window>.
#
# Usage: scripts/measure-idle.sh <App.app> <profile-dir> [settle-s=25] [window-s=30] [app args...]
# e.g. `... 25 30 --assume-visible` keeps the 1.5 s refresh of a visible window.
# APP_ENV="VAR=value ..." passes environment variables to the app.
set -eu
APP="${1:A}"; PROFILE="${2:A}"; SETTLE="${3:-25}"; WINDOW="${4:-30}"
shift $(( $# < 4 ? $# : 4 ))
EXE=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$APP/Contents/Info.plist")
BIN="$APP/Contents/MacOS/$EXE"
mkdir -p "$PROFILE"
ENVS=()
for pair in ${=APP_ENV:-}; do ENVS+=(--env "$pair"); done
open -g -n "${ENVS[@]}" "$APP" --args --profile "$PROFILE" "$@"
PID=""
for _ in {1..240}; do
    PID=$(pgrep -nf "^$BIN --profile $PROFILE" || true)
    [[ -n "$PID" ]] && break
    sleep 0.25
done
[[ -n "$PID" ]] || { echo "app did not start" >&2; exit 1; }
quit() {
    kill -TERM "$PID" 2>/dev/null || true
    for _ in {1..60}; do kill -0 "$PID" 2>/dev/null || return 0; sleep 0.5; done
    kill -KILL "$PID" 2>/dev/null || true
}
trap quit EXIT

RUSAGE="${TMPDIR:-/tmp}/qbtneo-rusage"
[[ -x "$RUSAGE" && "$RUSAGE" -nt "${0:A:h}/rusage.swift" ]] || swiftc -O "${0:A:h}/rusage.swift" -o "$RUSAGE"

sleep "$SETTLE"
read C0 W0 I0 F0 < <("$RUSAGE" "$PID")
sleep "$WINDOW"
read C1 W1 I1 F1 < <("$RUSAGE" "$PID")
PEAK=$(vmmap --summary "$PID" 2>/dev/null | awk '/Physical footprint \(peak\):/ { print $4 }')
printf "pid=%s footprint=%.1fM peak=%s cpu_ms_per_s=%.1f wakeups_per_s=%.1f\n" "$PID" \
    $(( F0 / 1048576.0 )) "$PEAK" $(( (C1 - C0) / (WINDOW * 1.0) )) $(( (W1 - W0) / (WINDOW * 1.0) ))

