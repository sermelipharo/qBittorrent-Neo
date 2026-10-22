#!/bin/bash
# Signs a release for in-app updates: downloads the zip that the Release
# workflow attached to the (draft) GitHub release, checks its SHA-256, signs
# it with the Sparkle EdDSA key from this Mac's Keychain and uploads
# appcast.xml to the same release. The app reads the appcast of the latest
# published release (SUFeedURL), so publish the release afterwards.
#
# Usage: scripts/sign-update.sh v0.2.3
#
# Needs gh, and Sparkle's sign_update (SPARKLE_BIN, or the copy Xcode
# fetched with the Sparkle package). The private key never leaves the
# Keychain; back it up with `generate_keys --account qbittorrent-neo -x <file>`.
set -euo pipefail

REPO=sermelipharo/qBittorrent-Neo
ACCOUNT=qbittorrent-neo
TITLE="qBittorrent Neo"
TAG="${1:?usage: $0 vX.Y.Z}"
VERSION="${TAG#v}"
ZIP="qBittorrent-Neo-$VERSION-arm64.zip"

SIGN="${SPARKLE_BIN:-}/sign_update"
if [[ ! -x "$SIGN" ]]; then
    SIGN=$(find "$HOME/Library/Developer/Xcode/DerivedData" -path '*artifacts/sparkle/Sparkle/bin/sign_update' -type f 2>/dev/null | head -1)
fi
[[ -x "$SIGN" ]] || { echo "sign_update not found: set SPARKLE_BIN to Sparkle's bin folder" >&2; exit 1; }

WORK=$(mktemp -d "${TMPDIR:-/tmp}/sign-update.XXXXXX")
trap 'rm -rf "$WORK"' EXIT
cd "$WORK"

gh release download "$TAG" -R "$REPO" -p "$ZIP" -p "$ZIP.sha256"
shasum -a 256 -c "$ZIP.sha256"

# The bundle's own versions: Sparkle compares CFBundleVersion.
PLIST=$(unzip -Z1 "$ZIP" | grep -m1 '\.app/Contents/Info\.plist$')
unzip -p "$ZIP" "$PLIST" > Info.plist
BUILD=$(plutil -extract CFBundleVersion raw Info.plist)
SHORT=$(plutil -extract CFBundleShortVersionString raw Info.plist)
MINIMUM=$(plutil -extract LSMinimumSystemVersion raw Info.plist)
[[ "$SHORT" == "$VERSION" ]] || { echo "the zip holds $SHORT, not $VERSION" >&2; exit 1; }

# sparkle:edSignature="…" length="…"
SIGNATURE=$("$SIGN" --account "$ACCOUNT" "$ZIP")
[[ "$SIGNATURE" == *'sparkle:edSignature="'* ]] || { echo "signing failed: $SIGNATURE" >&2; exit 1; }

# "What's new" from the release notes, as Markdown.
gh release view "$TAG" -R "$REPO" --json body -q .body \
    | awk '/^## /{on=($0 ~ /^## What.s new/); next} on' > notes.md
NOTES=$(sed 's/]]>/]]]]><![CDATA[>/g' notes.md)
DATE=$(LC_ALL=C date -u '+%a, %d %b %Y %H:%M:%S +0000')
URL="https://github.com/$REPO/releases/download/$TAG/$ZIP"

cat > appcast.xml <<EOF
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>$TITLE</title>
    <item>
      <title>$TITLE $VERSION</title>
      <pubDate>$DATE</pubDate>
      <sparkle:version>$BUILD</sparkle:version>
      <sparkle:shortVersionString>$VERSION</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>$MINIMUM</sparkle:minimumSystemVersion>
      <sparkle:fullReleaseNotesLink>https://github.com/$REPO/releases/tag/$TAG</sparkle:fullReleaseNotesLink>
      <description sparkle:format="markdown"><![CDATA[$NOTES]]></description>
      <enclosure url="$URL" type="application/octet-stream" $SIGNATURE />
    </item>
  </channel>
</rss>
EOF
xmllint --noout appcast.xml
gh release upload "$TAG" -R "$REPO" --clobber appcast.xml
echo "appcast.xml uploaded to $TAG (build $BUILD)"
