#!/usr/bin/env python3
"""Embeds the qBittorrent core library and its Qt/Homebrew dependencies in
the app bundle so it runs standalone (a small, scriptable macdeployqt).

Usage: deploy-qt.py <App.app> <libqbtneocore.dylib> <codesign identity|->

* Copies libqbtneocore.dylib to Contents/Frameworks (install name
  @rpath/libqbtneocore.dylib, found through the app's run path).
* Recursively copies every non-system dependency (Qt frameworks, OpenSSL,
  ICU, ...) to Contents/Frameworks and rewrites the references to
  @executable_path/../Frameworks/...
* Copies the Qt plug-ins the core needs (TLS backends, SQLite driver,
  network information) to Contents/PlugIns and writes Contents/Resources/qt.conf.
* Signs everything it copied with the given identity, innermost first.

The Qt part is skipped when the sources did not change since the last run.
"""
import hashlib
import os
import shutil
import subprocess
import sys

PLUGINS = [
    ("tls", "libqopensslbackend.dylib"),
    ("tls", "libqsecuretransportbackend.dylib"),
    ("tls", "libqcertonlybackend.dylib"),
    ("sqldrivers", "libqsqlite.dylib"),
    ("networkinformation", "libqapplenetworkinformation.dylib"),
]
SYSTEM_PREFIXES = ("/System/", "/usr/lib/")


def run(*args, check=True):
    return subprocess.run(args, check=check, capture_output=True, text=True).stdout


def qt_plugin_dir():
    for tool in ("/opt/homebrew/bin/qtpaths", "/opt/homebrew/bin/qmake"):
        if os.path.exists(tool):
            if tool.endswith("qtpaths"):
                out = run(tool, "--plugin-dir", check=False).strip()
            else:
                out = run(tool, "-query", "QT_INSTALL_PLUGINS", check=False).strip()
            if out and os.path.isdir(out):
                return out
    return "/opt/homebrew/share/qt/plugins"


def dependencies(binary):
    lines = run("otool", "-L", binary).splitlines()[1:]
    deps = []
    for line in lines:
        path = line.strip().split(" (compatibility")[0]
        deps.append(path)
    return deps


def is_external(path):
    return path.startswith("/") and not path.startswith(SYSTEM_PREFIXES)


def copy(source, dest):
    """Copies a (possibly read-only) file, replacing an older copy."""
    if os.path.lexists(dest):
        os.remove(dest)
    shutil.copy2(source, dest)
    os.chmod(dest, 0o755)


def framework_parts(path):
    """('/x/QtCore.framework', 'QtCore', 'Versions/A/QtCore') or None."""
    marker = ".framework/"
    if marker not in path:
        return None
    root = path[: path.index(marker) + len(marker) - 1]
    name = os.path.basename(root)[: -len(".framework")]
    inner = path[len(root) + 1:]
    return root, name, inner


class Deployer:
    def __init__(self, app, identity):
        self.app = app
        self.identity = identity
        self.frameworks = os.path.join(app, "Contents", "Frameworks")
        self.plugins = os.path.join(app, "Contents", "PlugIns")
        self.resources = os.path.join(app, "Contents", "Resources")
        self.copied = {}  # original reference -> (destination binary, new reference)
        self.to_sign = []
        self.framework_dirs = []

    def new_reference(self, original):
        if original in self.copied:
            return self.copied[original][1]
        real = os.path.realpath(original)
        parts = framework_parts(original)
        if parts:
            root, name, inner = parts
            real_root = os.path.realpath(root)
            dest_root = os.path.join(self.frameworks, name + ".framework")
            dest = os.path.join(dest_root, inner)
            os.makedirs(os.path.dirname(dest), exist_ok=True)
            copy(real, dest)
            version_dir = os.path.dirname(inner)  # Versions/A
            plist = os.path.join(real_root, version_dir, "Resources", "Info.plist")
            if os.path.exists(plist):
                os.makedirs(os.path.join(dest_root, version_dir, "Resources"), exist_ok=True)
                copy(plist, os.path.join(dest_root, version_dir, "Resources", "Info.plist"))
            self.link(os.path.join(dest_root, "Versions", "Current"), os.path.basename(version_dir))
            self.link(os.path.join(dest_root, name), os.path.join("Versions", "Current", name))
            self.link(os.path.join(dest_root, "Resources"), os.path.join("Versions", "Current", "Resources"))
            reference = "@executable_path/../Frameworks/%s.framework/%s" % (name, inner)
            self.framework_dirs.append(dest_root)
        else:
            dest = os.path.join(self.frameworks, os.path.basename(original))
            copy(real, dest)
            reference = "@executable_path/../Frameworks/" + os.path.basename(original)
            self.to_sign.append(dest)
        os.chmod(dest, 0o755)
        self.copied[original] = (dest, reference)
        run("install_name_tool", "-id", reference, dest, check=False)
        self.process(dest, os.path.dirname(real))
        return reference

    @staticmethod
    def link(path, target):
        if os.path.islink(path) or os.path.exists(path):
            return
        os.symlink(target, path)

    def process(self, binary, source_dir=None):
        for dep in dependencies(binary):
            target = dep
            if dep.startswith(("@rpath/", "@loader_path/")) and source_dir:
                # Homebrew libraries refer to siblings relatively.
                candidate = os.path.join(source_dir, dep.split("/", 1)[1])
                if not os.path.exists(candidate) or os.path.basename(binary) == os.path.basename(candidate):
                    continue
                target = candidate
            elif not is_external(dep):
                continue
            reference = self.new_reference(target)
            run("install_name_tool", "-change", dep, reference, binary, check=False)

    def sign(self, path):
        subprocess.run(["codesign", "--force", "--sign", self.identity, "--timestamp=none", path],
                       check=True, capture_output=True)


def digest(paths):
    h = hashlib.sha256()
    for path in paths:
        st = os.stat(path)
        h.update(("%s:%d:%d\n" % (path, st.st_size, int(st.st_mtime))).encode())
    return h.hexdigest()


def main():
    app, core, identity = sys.argv[1], sys.argv[2], sys.argv[3]
    deployer = Deployer(app, identity)
    os.makedirs(deployer.frameworks, exist_ok=True)

    plugin_dir = qt_plugin_dir()
    plugin_sources = [os.path.join(plugin_dir, c, n) for c, n in PLUGINS
                      if os.path.exists(os.path.join(plugin_dir, c, n))]
    # Kept outside the bundle (nothing unsigned may live in Frameworks).
    stamp_dir = os.environ.get("DERIVED_FILE_DIR") or os.path.dirname(os.path.abspath(app))
    os.makedirs(stamp_dir, exist_ok=True)
    stamp_path = os.path.join(stamp_dir, "qt-deploy-stamp-" + hashlib.sha1(app.encode()).hexdigest()[:8])
    stamp = digest(plugin_sources + [os.path.realpath(d) for d in dependencies(core) if is_external(d)]) + identity
    qt_done = os.path.exists(stamp_path) and open(stamp_path).read() == stamp

    # The core library: refreshed on every build.
    core_dest = os.path.join(deployer.frameworks, "libqbtneocore.dylib")
    copy(core, core_dest)
    os.chmod(core_dest, 0o755)
    run("install_name_tool", "-id", "@rpath/libqbtneocore.dylib", core_dest, check=False)

    if qt_done:
        # Only rewrite the references of the fresh core library.
        for dep in dependencies(core_dest):
            if is_external(dep):
                parts = framework_parts(dep)
                if parts:
                    ref = "@executable_path/../Frameworks/%s.framework/%s" % (parts[1], parts[2])
                else:
                    ref = "@executable_path/../Frameworks/" + os.path.basename(dep)
                run("install_name_tool", "-change", dep, ref, core_dest, check=False)
        deployer.sign(core_dest)
        return

    deployer.process(core_dest)
    for source in plugin_sources:
        category = os.path.basename(os.path.dirname(source))
        dest = os.path.join(deployer.plugins, category, os.path.basename(source))
        os.makedirs(os.path.dirname(dest), exist_ok=True)
        copy(source, dest)
        os.chmod(dest, 0o755)
        deployer.process(dest)
        deployer.to_sign.append(dest)

    os.makedirs(deployer.resources, exist_ok=True)
    with open(os.path.join(deployer.resources, "qt.conf"), "w") as conf:
        conf.write("[Paths]\nPlugins = PlugIns\n")

    for path in deployer.to_sign:
        deployer.sign(path)
    for path in dict.fromkeys(deployer.framework_dirs):
        deployer.sign(path)
    deployer.sign(core_dest)
    with open(stamp_path, "w") as f:
        f.write(stamp)


if __name__ == "__main__":
    main()
