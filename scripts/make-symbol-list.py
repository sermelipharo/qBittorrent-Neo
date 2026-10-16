#!/usr/bin/env python3
"""Writes the SF Symbol names offered by the category/tag icon picker.

Reads the installed SF Symbols catalogue (CoreGlyphs.bundle) and keeps every
symbol available on macOS 27, minus the symbols Apple restricts to its own
products and the per-script localized variants (".ar", ".hi", ".ja", ...).

Usage: scripts/make-symbol-list.py [output]
       (default apps/macos/QBTNeo/Resources/SFSymbolNames.txt)
"""

import os
import plistlib
import re
import sys

BUNDLE = "/System/Library/CoreServices/CoreGlyphs.bundle/Contents/Resources"
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEFAULT_OUT = os.path.join(ROOT, "apps/macos/QBTNeo/Resources/SFSymbolNames.txt")
LOCALE_SUFFIX = re.compile(r"\.(ar|he|hi|ja|ko|th|zh(\.traditional)?|rtl|bn|gu|kn|ml|mr|or|pa|ta|te|km|my|sat|mni|si|el|ru|uk|bg|sr|kk|ky|mn|tg|be|mk|ss|fa|ur|ps|sd|ks|dv|ug|am|ti|lo|bo|dz|ne|sa|kok|mai|sv|da|nb|pl|cs|sk|hu|ro|hr|sl|lt|lv|et|fi|tr|vi|id|ms|ca|eu|gl|pt|es|fr|de|it|nl|en)$")


def main() -> int:
    out = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_OUT
    with open(os.path.join(BUNDLE, "name_availability.plist"), "rb") as f:
        availability = plistlib.load(f)
    with open(os.path.join(BUNDLE, "symbol_restrictions.strings"), "rb") as f:
        restricted = set(plistlib.load(f))
    releases = availability["year_to_release"]

    def macos(year: str) -> tuple:
        version = releases.get(year, {}).get("macOS", "99")
        return tuple(int(part) for part in version.split("."))

    names = sorted(
        name for name, year in availability["symbols"].items()
        if name not in restricted and not LOCALE_SUFFIX.search(name) and macos(year) <= (27, 0)
    )
    with open(out, "w", encoding="utf-8") as f:
        f.write("\n".join(names) + "\n")
    print(f"{len(names)} symbols -> {out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
