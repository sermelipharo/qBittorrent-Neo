#!/bin/zsh
# Notarizes a Release build of qBittorrent Neo and staples the ticket.
#
# Usage: scripts/notarize.sh <qBittorrent Neo.app> <notarytool keychain profile>
#
# Prerequisites (once, by the owner of the Apple ID):
#   * The app must be signed with a "Developer ID Application" certificate
#     (set CODE_SIGN_IDENTITY in apps/macos/Local.xcconfig and build the
#     Release configuration; scripts/deploy-qt.py then signs the embedded
#     Qt/OpenSSL libraries with the same identity, hardened runtime and a
#     secure timestamp). Apple Development certificates are rejected by the
#     notary service.
#   * Store the credentials in the keychain under a profile name:
#       xcrun notarytool store-credentials <profile> --apple-id <id> \
#           --team-id <team> --password <app-specific password>
#
# Steps: strict signature check, zip with ditto, submit and wait, staple,
# Gatekeeper assessment. Nothing is uploaded before the checks pass.
set -euo pipefail
[[ $# -eq 2 ]] || { echo "usage: $0 <App.app> <keychain-profile>" >&2; exit 2; }
APP="${1:A}"
PROFILE="$2"
[[ -d "$APP/Contents" ]] || { echo "not an app bundle: $APP" >&2; exit 1; }

echo "== Checking the signature"
codesign --verify --deep --strict --verbose=2 "$APP"
AUTHORITY=$(codesign -dvv "$APP" 2>&1 | awk -F= '/^Authority=/ { print $2; exit }')
echo "signed by: $AUTHORITY"
if [[ "$AUTHORITY" != "Developer ID Application:"* ]]; then
    echo "error: notarization needs a 'Developer ID Application' signature" >&2
    exit 1
fi
codesign -dvv "$APP" 2>&1 | grep -q "flags=.*runtime" || { echo "error: hardened runtime is off" >&2; exit 1; }
if find "$APP" -type f -perm +111 -print0 | xargs -0 otool -L 2>/dev/null | grep -q "/opt/homebrew\|/usr/local/"; then
    echo "error: the bundle still links libraries outside the app" >&2
    exit 1
fi

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
ZIP="$WORK/${APP:t:r}.zip"
echo "== Archiving"
ditto -c -k --keepParent "$APP" "$ZIP"

echo "== Submitting (waits for the result)"
xcrun notarytool submit "$ZIP" --keychain-profile "$PROFILE" --wait --output-format plist > "$WORK/result.plist" || true
STATUS=$(/usr/libexec/PlistBuddy -c 'Print :status' "$WORK/result.plist" 2>/dev/null || echo unknown)
ID=$(/usr/libexec/PlistBuddy -c 'Print :id' "$WORK/result.plist" 2>/dev/null || echo "")
echo "status: $STATUS (submission $ID)"
if [[ "$STATUS" != "Accepted" ]]; then
    [[ -n "$ID" ]] && xcrun notarytool log "$ID" --keychain-profile "$PROFILE" || true
    exit 1
fi

echo "== Stapling"
xcrun stapler staple "$APP"
xcrun stapler validate "$APP"
spctl --assess --type execute --verbose=2 "$APP"
