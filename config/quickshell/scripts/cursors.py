#!/usr/bin/env python3
"""JoeOS pointer (mouse cursor) helper for the Input tab.

  cursors.py list            JSON: current theme/size + every installed cursor theme with a preview picture
  cursors.py catalog         JSON: extra themes you can download, and which are already installed
  cursors.py set THEME SIZE  switch the pointer now (Hyprland, XWayland, GTK apps) and keep it after restarts
  cursors.py get KEY         download one of the catalog themes into ~/.local/share/icons

Previews are read straight from the theme's own cursor files (no extra tools needed) and
cached in ~/.cache/joeos-cursors.
"""
import json
import os
import re
import shutil
import struct
import subprocess
import sys
import tarfile
import tempfile
import urllib.request
import zipfile
import zlib

HOME = os.path.expanduser("~")
DATA_DIRS = [HOME + "/.local/share/icons", HOME + "/.icons", "/usr/share/icons"]
INSTALL_DIR = HOME + "/.local/share/icons"
CACHE = HOME + "/.cache/joeos-cursors"
PREVIEW_SIZE = 64
SHAPES = ["left_ptr", "default", "arrow", "top_left_arrow"]

# name shown, file to download, folder(s) it unpacks to (checked to see if it's installed)
CATALOG = [
    {"key": "bibata-classic", "name": "Bibata Modern", "note": "black, rounded",
     "url": "https://github.com/ful1e5/Bibata_Cursor/releases/latest/download/Bibata-Modern-Classic.tar.xz",
     "dirs": ["Bibata-Modern-Classic"]},
    {"key": "bibata-ice", "name": "Bibata Ice", "note": "white, rounded",
     "url": "https://github.com/ful1e5/Bibata_Cursor/releases/latest/download/Bibata-Modern-Ice.tar.xz",
     "dirs": ["Bibata-Modern-Ice"]},
    {"key": "catppuccin", "name": "Catppuccin Mocha", "note": "soft dark",
     "url": "https://github.com/catppuccin/cursors/releases/latest/download/catppuccin-mocha-dark-cursors.zip",
     "dirs": ["catppuccin-mocha-dark-cursors"]},
    {"key": "rosepine", "name": "Rosé Pine", "note": "warm and sharp",
     "url": "https://github.com/rose-pine/cursor/releases/latest/download/BreezeX-RosePine-Linux.tar.xz",
     "dirs": ["BreezeX-RosePine-Linux"]},
    {"key": "phinger", "name": "Phinger", "note": "dark and light",
     "url": "https://github.com/phisch/phinger-cursors/releases/latest/download/phinger-cursors-variants.tar.bz2",
     "dirs": ["phinger-cursors-dark", "phinger-cursors-light"]},
    {"key": "xcursor-pro", "name": "XCursor Pro", "note": "clean, dark",
     "url": "https://github.com/ful1e5/XCursor-pro/releases/latest/download/XCursor-Pro-Dark.tar.xz",
     "dirs": ["XCursor-Pro-Dark"]},
]


# ---------------------------------------------------------------- reading cursor files
def read_xcursor(path, want):
    """First frame of an Xcursor file at the size closest to `want`: (nominal, w, h, rgba bytes) or None."""
    try:
        with open(path, "rb") as f:
            data = f.read()
    except OSError:
        return None
    if data[:4] != b"Xcur" or len(data) < 16:
        return None
    ntoc = struct.unpack_from("<I", data, 12)[0]
    best = None
    for i in range(min(ntoc, 512)):
        off = 16 + i * 12
        if off + 12 > len(data):
            break
        ctype, subtype, pos = struct.unpack_from("<III", data, off)
        if ctype != 0xFFFD0002:
            continue
        if best is None or abs(subtype - want) < abs(best[0] - want):
            best = (subtype, pos)
    if best is None:
        return None
    nominal, pos = best
    if pos + 36 > len(data):
        return None
    w, h = struct.unpack_from("<II", data, pos + 16)
    if not (0 < w <= 512 and 0 < h <= 512) or pos + 36 + w * h * 4 > len(data):
        return None
    out = bytearray(w * h * 4)
    px = struct.unpack_from("<%dI" % (w * h), data, pos + 36)
    for i, p in enumerate(px):
        a = p >> 24
        r, g, b = (p >> 16) & 255, (p >> 8) & 255, p & 255
        if 0 < a < 255:                      # Xcursor stores premultiplied colour
            r, g, b = min(255, r * 255 // a), min(255, g * 255 // a), min(255, b * 255 // a)
        out[i * 4:i * 4 + 4] = bytes((r, g, b, a))
    return nominal, w, h, bytes(out)


def write_png(path, w, h, rgba):
    def chunk(tag, body):
        c = struct.pack(">I", len(body)) + tag + body
        return c + struct.pack(">I", zlib.crc32(tag + body) & 0xFFFFFFFF)
    rows = b"".join(b"\x00" + rgba[y * w * 4:(y + 1) * w * 4] for y in range(h))
    png = (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0))
           + chunk(b"IDAT", zlib.compress(rows, 9)) + chunk(b"IEND", b""))
    tmp = path + ".tmp"
    with open(tmp, "wb") as f:
        f.write(png)
    os.replace(tmp, path)


def safe_name(s):
    return re.sub(r"[^A-Za-z0-9._-]", "_", s)


def theme_preview(name, directory):
    """(png path, nominal size, png width, png height) for a theme, or ("", 0, 0, 0)."""
    cur = os.path.join(directory, "cursors")
    for shape in SHAPES:
        got = read_xcursor(os.path.join(cur, shape), PREVIEW_SIZE)
        if got:
            nominal, w, h, rgba = got
            os.makedirs(CACHE, exist_ok=True)
            png = os.path.join(CACHE, "%s_%d_%dx%d.png" % (safe_name(name), nominal, w, h))
            if not os.path.exists(png):
                for old in os.listdir(CACHE):          # drop older previews of this theme
                    if old.startswith(safe_name(name) + "_"):
                        try:
                            os.remove(os.path.join(CACHE, old))
                        except OSError:
                            pass
                write_png(png, w, h, rgba)
            return png, nominal, w, h
    return "", 0, 0, 0


# ---------------------------------------------------------------- what's installed / current
def installed_themes():
    seen, out = set(), []
    for base in DATA_DIRS:
        if not os.path.isdir(base):
            continue
        for name in sorted(os.listdir(base), key=str.lower):
            d = os.path.join(base, name)
            if name in seen or name == "default" or not os.path.isdir(d):
                continue
            has_x = os.path.isdir(os.path.join(d, "cursors"))
            has_hypr = os.path.exists(os.path.join(d, "manifest.hl")) or os.path.exists(os.path.join(d, "hyprcursor.theme"))
            if not (has_x or has_hypr):
                continue
            seen.add(name)
            png, nominal, w, h = theme_preview(name, d) if has_x else ("", 0, 0, 0)
            out.append({"name": name, "dir": d, "preview": png, "nominal": nominal, "pw": w, "ph": h})
    return out


def run(cmd, timeout=15):
    try:
        return subprocess.run(cmd, capture_output=True, text=True, timeout=timeout).stdout.strip()
    except (OSError, subprocess.SubprocessError):
        return ""


def current():
    theme = run(["gsettings", "get", "org.gnome.desktop.interface", "cursor-theme"]).strip("'") \
        or os.environ.get("XCURSOR_THEME", "")
    size = run(["gsettings", "get", "org.gnome.desktop.interface", "cursor-size"]) \
        or os.environ.get("XCURSOR_SIZE", "")
    if not theme:
        try:
            with open(HOME + "/.icons/default/index.theme") as f:
                m = re.search(r"^Inherits=(\S+)", f.read(), re.M)
                theme = m.group(1) if m else ""
        except OSError:
            pass
    try:
        size = int(size)
    except ValueError:
        size = 24
    return theme or "Adwaita", size


# ---------------------------------------------------------------- applying
def set_ini_key(path, key, value):
    """Change one key in the [Settings] section of a GTK settings.ini, leaving the rest alone."""
    try:
        text = open(path).read() if os.path.exists(path) else ""
    except OSError:
        return
    line = "%s=%s" % (key, value)
    if re.search(r"^%s\s*=" % re.escape(key), text, re.M):
        text = re.sub(r"^%s\s*=.*$" % re.escape(key), line, text, flags=re.M)
    elif "[Settings]" in text:
        text = text.replace("[Settings]", "[Settings]\n" + line, 1)
    else:
        text = (text.rstrip("\n") + "\n\n" if text.strip() else "") + "[Settings]\n" + line + "\n"
    try:
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w") as f:
            f.write(text)
    except OSError:
        pass


def apply_cursor(theme, size):
    if not re.fullmatch(r"[A-Za-z0-9._ +()-]+", theme) or not 8 <= size <= 256:
        print("bad theme or size")
        return 1
    run(["hyprctl", "setcursor", theme, str(size)], 10)
    if shutil.which("gsettings"):
        run(["gsettings", "set", "org.gnome.desktop.interface", "cursor-theme", theme])
        run(["gsettings", "set", "org.gnome.desktop.interface", "cursor-size", str(size)])
    # apps that don't ask the compositor (XWayland, Qt, Flatpak) read these
    os.makedirs(HOME + "/.icons/default", exist_ok=True)
    with open(HOME + "/.icons/default/index.theme", "w") as f:
        f.write("[Icon Theme]\nName=Default\nComment=Default cursor theme\nInherits=%s\n" % theme)
    for gtk in ("gtk-3.0", "gtk-4.0"):
        ini = HOME + "/.config/%s/settings.ini" % gtk
        set_ini_key(ini, "gtk-cursor-theme-name", theme)
        set_ini_key(ini, "gtk-cursor-theme-size", size)
    print("ok")
    return 0


# ---------------------------------------------------------------- downloading
def unpack(archive, dest):
    """Extract into an empty folder, refusing anything that would land outside it."""
    root = os.path.realpath(dest)
    if zipfile.is_zipfile(archive):
        with zipfile.ZipFile(archive) as z:
            for n in z.namelist():
                if not os.path.realpath(os.path.join(root, n)).startswith(root + os.sep):
                    raise RuntimeError("unsafe file in download")
            z.extractall(root)
    else:
        with tarfile.open(archive) as t:
            t.extractall(root, filter="data")


def get_theme(key):
    item = next((c for c in CATALOG if c["key"] == key), None)
    if not item:
        print("unknown theme")
        return 1
    work = tempfile.mkdtemp(prefix="joeos-cursor-")
    try:
        archive = os.path.join(work, "download")
        req = urllib.request.Request(item["url"], headers={"User-Agent": "JoeOS"})
        with urllib.request.urlopen(req, timeout=60) as r, open(archive, "wb") as f:
            shutil.copyfileobj(r, f)
        out = os.path.join(work, "out")
        os.makedirs(out)
        unpack(archive, out)
        os.makedirs(INSTALL_DIR, exist_ok=True)
        added = 0
        for root, dirs, _ in os.walk(out):        # any folder that holds a cursors/ folder is a theme
            if "cursors" in dirs:
                name = os.path.basename(root)
                target = os.path.join(INSTALL_DIR, name)
                if os.path.exists(target):
                    shutil.rmtree(target)
                shutil.copytree(root, target, symlinks=True)
                added += 1
        print("ok" if added else "nothing found in the download")
        return 0 if added else 1
    except Exception as e:                        # network down, bad archive, disk full...
        print("failed: %s" % e)
        return 1
    finally:
        shutil.rmtree(work, ignore_errors=True)


def catalog():
    have = {t["name"] for t in installed_themes()}
    return [{"key": c["key"], "name": c["name"], "note": c["note"],
             "installed": all(d in have for d in c["dirs"])} for c in CATALOG]


def main(argv):
    cmd = argv[1] if len(argv) > 1 else "list"
    if cmd == "list":
        theme, size = current()
        print(json.dumps({"theme": theme, "size": size, "themes": installed_themes()}))
    elif cmd == "catalog":
        print(json.dumps(catalog()))
    elif cmd == "set" and len(argv) >= 4:
        try:
            return apply_cursor(argv[2], int(argv[3]))
        except ValueError:
            print("bad size")
            return 1
    elif cmd == "get" and len(argv) >= 3:
        return get_theme(argv[2])
    else:
        print(__doc__)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
