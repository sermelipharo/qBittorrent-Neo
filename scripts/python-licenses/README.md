License texts for the Python that `scripts/embed-python.sh` bundles: CPython
and the libraries linked into python-build-standalone 3.13.16 (release
20261013, aarch64-apple-darwin), taken from `python/licenses` of the
release's `pgo+lto-full` archive (SHA-256
3497822d8bf4884bc79258f62668f985654d03d40ec74da4ca9ae7a5667c4362). The
build's `PYTHON.json` names the libraries; Tcl/Tk and the system libraries
(libedit, ncurses, zlib from macOS) are left out. Refresh them when the
pinned release changes.
