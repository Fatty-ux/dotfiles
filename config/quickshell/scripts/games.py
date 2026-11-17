#!/usr/bin/env python3
"""JoeOS game library for the bar's Games view.

    games.py            print every game as JSON (Steam, Heroic, Recomp)
    games.py --names    also look up names of Steam games that aren't installed
                        (Steam store, a few each run, saved in ~/.cache/joeos/steam-names.json)

Only reads launcher files; it never changes anything.
"""
import glob, json, os, re, shutil, subprocess, sys, time, urllib.parse, urllib.request

HOME = os.path.expanduser("~")
CACHE = os.path.join(HOME, ".cache/joeos")
NAMES = os.path.join(CACHE, "steam-names.json")

# ---------------------------------------------------------------- helpers
def vdf_parse(text):
    """Tiny parser for Steam's text VDF files -> nested dicts (keys lower-cased)."""
    toks = re.findall(r'"((?:[^"\\]|\\.)*)"|([{}])', text)
    pos = 0
    def block():
        nonlocal pos
        out = {}
        while pos < len(toks):
            s, br = toks[pos]
            if br == "}":
                pos += 1
                return out
            if br == "{":          # stray brace
                pos += 1
                continue
            key = s.lower()
            pos += 1
            if pos >= len(toks):
                break
            s2, br2 = toks[pos]
            if br2 == "{":
                pos += 1
                out[key] = block()
            else:
                out[key] = s2.replace('\\"', '"').replace("\\\\", "\\")
                pos += 1
        return out
    return block()

def read(path):
    try:
        with open(path, encoding="utf-8", errors="replace") as f:
            return f.read()
    except OSError:
        return None

def load_json(path, default):
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    except (OSError, ValueError):
        return default

def first(*paths):
    for p in paths:
        if p and os.path.exists(p):
            return p
    return ""

NOT_GAMES = re.compile(r"proton|steam linux runtime|steamworks|steamvr|redistributable|soundtrack|dedicated server|sdk$", re.I)

# ---------------------------------------------------------------- Steam
def steam_root():
    for p in ("~/.local/share/Steam", "~/.steam/steam", "~/.var/app/com.valvesoftware.Steam/.local/share/Steam"):
        p = os.path.expanduser(p)
        if os.path.isdir(os.path.join(p, "steamapps")):
            return p
    return ""

def steam_art(root, appid):
    lc = os.path.join(root, "appcache/librarycache")
    local = first(
        os.path.join(lc, appid, "library_600x900.jpg"),
        os.path.join(lc, appid + "_library_600x900.jpg"),
        *glob.glob(os.path.join(lc, appid, "*", "library_600x900.jpg")),
        *glob.glob(os.path.join(lc, appid, "*", "library_capsule.jpg")),
    )
    web = "https://cdn.cloudflare.steamstatic.com/steam/apps/%s/library_600x900.jpg" % appid
    head = first(os.path.join(lc, appid, "header.jpg"), os.path.join(lc, appid + "_header.jpg"),
                 *glob.glob(os.path.join(lc, appid, "*", "header.jpg")))
    return ("file://" + local) if local else web, ("file://" + head) if head else \
        "https://cdn.cloudflare.steamstatic.com/steam/apps/%s/header.jpg" % appid

def steam_user(root):
    best, best_t = "", -1
    for d in glob.glob(os.path.join(root, "userdata", "*")):
        name = os.path.basename(d)
        if not name.isdigit() or name == "0":
            continue
        f = os.path.join(d, "config", "localconfig.vdf")
        t = os.path.getmtime(f) if os.path.exists(f) else 0
        if t > best_t:
            best, best_t = d, t
    return best

def steam_collections(userdir):
    """Your Steam collections (from Steam's cloud-storage cache). [{id, name, apps:[...]}]"""
    out = []
    for f in glob.glob(os.path.join(userdir, "config", "cloudstorage", "cloud-storage-namespace-*.json")):
        data = load_json(f, [])
        for item in data if isinstance(data, list) else []:
            try:
                key, val = item[0], item[1]
            except (IndexError, TypeError, KeyError):
                continue
            if not str(key).startswith("user-collections.") or not isinstance(val, dict):
                continue
            if val.get("is_deleted") or not val.get("value"):
                continue
            try:
                c = json.loads(val["value"])
            except ValueError:
                continue
            if "filterSpec" in c and not c.get("added"):
                continue            # "dynamic" collections are rules, not lists
            apps = [str(a) for a in c.get("added", [])]
            if c.get("name") and apps:
                out.append({"id": c.get("id", key), "name": c["name"], "apps": apps})
    out.sort(key=lambda c: c["name"].lower())
    return out

def steam_games():
    root = steam_root()
    if not root:
        return [], [], []
    games = {}
    # installed: appmanifest files in every library folder
    libs = [root]
    lf = vdf_parse(read(os.path.join(root, "steamapps", "libraryfolders.vdf")) or "")
    for v in lf.get("libraryfolders", {}).values():
        if isinstance(v, dict) and v.get("path"):
            libs.append(v["path"])
    for lib in dict.fromkeys(libs):
        for m in glob.glob(os.path.join(lib, "steamapps", "appmanifest_*.acf")):
            st = vdf_parse(read(m) or "").get("appstate", {})
            appid, name = st.get("appid"), st.get("name", "")
            if not appid or not name or NOT_GAMES.search(name):
                continue
            games[appid] = {"name": name, "installed": True,
                            "last": int(st.get("lastplayed", "0") or 0), "size": int(st.get("sizeondisk", "0") or 0)}
    # played but not installed: localconfig.vdf, plus everything in your collections
    user = steam_user(root)
    played = {}
    if user:
        lc = vdf_parse(read(os.path.join(user, "config", "localconfig.vdf")) or "")
        apps = lc.get("userlocalconfigstore", {}).get("software", {}).get("valve", {}).get("steam", {}).get("apps", {})
        for appid, info in apps.items():
            if appid.isdigit() and isinstance(info, dict):
                played[appid] = int(info.get("lastplayed", "0") or 0)
    cols = steam_collections(user) if user else []
    names = load_json(NAMES, {})
    known = set(played) | {a for c in cols for a in c["apps"]}
    missing = []
    for appid in known:
        if appid in games:
            games[appid]["last"] = max(games[appid]["last"], played.get(appid, 0))
            continue
        n = names.get(appid)
        if n is None:
            missing.append(appid)
            continue
        if not n or n.startswith("!"):        # "!" = not a game (DLC, tool...)
            continue
        games[appid] = {"name": n, "installed": False, "last": played.get(appid, 0), "size": 0}
    out = []
    for appid, g in games.items():
        cover, header = steam_art(root, appid)
        out.append({
            "key": "steam:" + appid, "id": appid, "name": g["name"], "src": "steam", "installed": g["installed"],
            "cover": cover, "header": header, "last": g["last"],
            "play": ["steam", "steam://rungameid/" + appid],
            "install": ["steam", "steam://install/" + appid],
            "cols": [c["id"] for c in cols if appid in c["apps"]],
        })
    return out, [{"id": c["id"], "name": c["name"]} for c in cols], missing

def fetch_names(missing, limit=40):
    names = load_json(NAMES, {})
    done = 0
    for appid in missing[:limit]:
        try:
            url = "https://store.steampowered.com/api/appdetails?appids=%s&filters=basic" % appid
            with urllib.request.urlopen(url, timeout=8) as r:
                d = json.load(r).get(appid, {})
            if d.get("success") and d.get("data"):
                data = d["data"]
                names[appid] = data.get("name", "") if data.get("type") == "game" else "!" + data.get("type", "")
            else:
                names[appid] = "!gone"
            done += 1
        except Exception:
            break
        time.sleep(1.2)
    os.makedirs(CACHE, exist_ok=True)
    with open(NAMES, "w") as f:
        json.dump(names, f)
    return done

# ---------------------------------------------------------------- Heroic
def heroic_games():
    base = first(os.path.join(HOME, ".config/heroic"), os.path.join(HOME, ".var/app/com.heroicgameslauncher.hgl/config/heroic"))
    if not base:
        return []
    out = []
    installed = set()
    leg = load_json(os.path.join(base, "legendaryConfig/legendary/installed.json"), {})
    installed |= {("legendary", k) for k in leg} if isinstance(leg, dict) else set()
    gog = load_json(os.path.join(base, "gog_store/installed.json"), {})
    for g in gog.get("installed", []) if isinstance(gog, dict) else []:
        installed.add(("gog", str(g.get("appName", ""))))
    nile = load_json(os.path.join(base, "nile_config/nile/installed.json"), [])
    for g in nile if isinstance(nile, list) else []:
        installed.add(("nile", str(g.get("id", ""))))
    sources = [("legendary", "store_cache/legendary_library.json", "library"),
               ("gog", "store_cache/gog_library.json", "games"),
               ("nile", "store_cache/nile_library.json", "library"),
               ("sideload", "sideload_apps/library.json", "games")]
    seen = set()
    for runner, f, key in sources:
        data = load_json(os.path.join(base, f), {})
        items = data.get(key, []) if isinstance(data, dict) else []
        for g in items:
            app = str(g.get("app_name") or g.get("appName") or "")
            title = g.get("title") or ""
            if not app or not title or (runner, app) in seen:
                continue
            if g.get("is_dlc") or g.get("install", {}).get("is_dlc"):
                continue
            seen.add((runner, app))
            r = g.get("runner") or runner
            inst = bool(g.get("is_installed")) or (r, app) in installed or runner == "sideload"
            link = "heroic://launch?appName=%s&runner=%s" % (app, r)
            out.append({
                "key": "heroic:%s:%s" % (r, app), "id": app, "name": title, "src": "heroic", "installed": inst,
                "cover": g.get("art_square") or g.get("art_cover") or "", "header": g.get("art_cover") or "",
                "last": 0, "store": {"legendary": "Epic", "gog": "GOG", "nile": "Amazon"}.get(r, "Heroic"),
                "play": ["xdg-open", link],
                "install": ["xdg-open", "heroic://"],
                "cols": [],
            })
    return out

# ---------------------------------------------------------------- Recomp ports
def recomp_games():
    """Recompiled console games: programs (often AppImages) found in your games and RecompLauncher folders."""
    roots = [os.path.join(HOME, d) for d in ("Games", "Applications", "Downloads")]
    for pat in ("~/.local/share/*", "~/.config/*", "~/*"):
        roots += [d for d in glob.glob(os.path.expanduser(pat)) if os.path.isdir(d) and "recomp" in os.path.basename(d).lower()]
    out, seen = [], set()
    skip = re.compile(r"(^|/)(roms?|saves?|shaders?|cache|caches|lib|libs|assets|\.git|node_modules|steamapps|compatdata)(/|$)", re.I)
    for root in dict.fromkeys(roots):
        if not os.path.isdir(root):
            continue
        for dirpath, dirs, files in os.walk(root):
            rel = os.path.relpath(dirpath, root)
            depth = 0 if rel == "." else rel.count(os.sep) + 1
            if depth > 4 or skip.search(rel.replace(os.sep, "/")):
                dirs[:] = []
                continue
            in_recomp_dir = "recomp" in dirpath.lower()
            for fn in files:
                p = os.path.join(dirpath, fn)
                low = fn.lower()
                if low.startswith("recomplauncher") or low.endswith((".so", ".txt", ".json", ".ini", ".cfg", ".sh", ".log",
                                                                     ".png", ".jpg", ".zip", ".rar", ".7z", ".z64", ".n64", ".iso", ".nsp", ".xci")):
                    continue
                is_appimage = low.endswith(".appimage")
                if not ("recomp" in low or (is_appimage and in_recomp_dir) or (in_recomp_dir and os.access(p, os.X_OK) and "." not in fn)):
                    continue
                if not os.path.isfile(p) or (not is_appimage and not os.access(p, os.X_OK)):
                    continue
                real = os.path.realpath(p)
                if real in seen:
                    continue
                seen.add(real)
                base = fn[:-9] if is_appimage else fn
                name = re.sub(r"(?i)[._ -]?(x86_64|amd64|x64|linux|release)$", "", base)
                name = re.sub(r"(?i)[._ -]?(x86_64|amd64|x64|linux|release)$", "", name)
                name = re.sub(r"(?i)recomp(iled)?$", " Recompiled", name)
                name = re.sub(r"([a-z])([A-Z])", r"\1 \2", name).replace("_", " ").replace("-", " ")
                name = re.sub(r"\s+", " ", name).strip()
                icon = first(*[os.path.join(dirpath, n) for n in ("icon.png", "icon.jpg", "cover.png", "cover.jpg", "logo.png")])
                if is_appimage and not os.access(p, os.X_OK):
                    play = ["sh", "-c", 'chmod +x "$1"; cd "$(dirname "$1")" && exec "$1"', "sh", p]
                else:
                    play = ["sh", "-c", 'cd "$(dirname "$1")" && exec "$1"', "sh", p]
                out.append({
                    "key": "recomp:" + game_slug(p), "id": p, "name": name, "src": "recomp", "installed": True,
                    "cover": ("file://" + icon) if icon else "", "header": "", "last": int(os.path.getatime(p)),
                    "play": play, "install": [], "cols": [],
                })
    return one_per_key(out)


# ---------------------------------------------------------------- Switch emulators
# Eden plays Switch 1 games, Eglantine (built on Eden) plays Switch 2 games.
EMU_EXT = (".xci", ".nsp", ".xcz", ".nsz", ".nro", ".nca")
EMULATORS = [
    # src, label, program names, config folder names, does a folder name look like this console?
    ("switch2", "Switch 2", ("eglantine",), ("eglantine",), re.compile(r"switch[ _-]?2", re.I)),
    ("switch1", "Switch", ("eden",), ("eden",), re.compile(r"switch(?![ _-]?2)|\bnx\b|\bns\b", re.I)),
]
EXE_DIRS = (".local/bin", "Applications", "Games", "Downloads", "Emulators", "Games/Emulators")

def emu_exe(names):
    """The emulator program: an AppImage, an extracted build folder, or one on your PATH."""
    hits = []
    dirs = [os.path.join(HOME, x) for x in EXE_DIRS] + os.environ.get("PATH", "").split(":")
    for d in dirs:
        if not os.path.isdir(d):
            continue
        for n in names:
            cap = "[%s%s]%s" % (n[0].upper(), n[0], n[1:])
            hits += glob.glob(os.path.join(d, cap + "*.AppImage")) + glob.glob(os.path.join(d, n))
            hits += glob.glob(os.path.join(d, "*%s*" % cap, n)) + glob.glob(os.path.join(d, "*%s*" % cap, "*.AppImage"))
    hits = [h for h in hits if os.path.isfile(h) and os.access(h, os.X_OK) or h.endswith(".AppImage")]
    # "eden" alone must not match Eglantine's own files (its tar.gz ships eden-cli)
    hits = [h for h in hits if not ("eden" in names and "eglantine" in h.lower())]
    hits.sort(key=lambda h: os.path.getmtime(h))       # newest build wins
    if hits:
        return hits[-1]
    # installed as a Flatpak (e.g. dev.eden_emu.eden)
    if shutil.which("flatpak"):
        try:
            apps = subprocess.run(["flatpak", "list", "--app", "--columns=application"], capture_output=True, text=True, timeout=10).stdout.split()
        except Exception:
            apps = []
        for a in apps:
            if any(n in a.lower() for n in names):
                return "flatpak:" + a
    return ""

def emu_command(exe, path):
    """How to start a game: a Flatpak emulator is also given access to the game's folder."""
    if exe.startswith("flatpak:"):
        folder = os.path.dirname(os.path.dirname(path)) if path.endswith("/exefs/main") else os.path.dirname(path)
        return ["flatpak", "run", "--filesystem=" + folder, exe[8:], "-g", path]
    return [exe, "-g", path]

def emu_open(exe):
    return ["flatpak", "run", exe[8:]] if exe.startswith("flatpak:") else [exe]

def emu_config_dirs(cfgnames):
    dirs = []
    for n in cfgnames:
        for cfg in glob.glob(os.path.join(HOME, ".config", n, "qt-config.ini")) + \
                   glob.glob(os.path.join(HOME, ".config", n.capitalize(), "qt-config.ini")) + \
                   glob.glob(os.path.join(HOME, ".var/app", "*", "config", n, "qt-config.ini")):
            for line in (read(cfg) or "").splitlines():
                m = re.match(r"^Paths\\gamedirs\\\d+\\path=(.+)$", line.strip())
                if m and not m.group(1).startswith(("SDMC", "UserNAND", "SysNAND")):
                    dirs.append(os.path.expanduser(m.group(1).strip()))
    return dirs

def guess_dirs(looks_like):
    """Folders named like 'Switch Roms' / 'Switch 2 Roms' in the usual places."""
    out = []
    for pat in ("~/Games/*", "~/Games/*/*", "~/Games/*/Roms/*", "~/Roms/*", "~/ROMs/*", "~/Emulation/roms/*", "~/Emulation/*"):
        for d in glob.glob(os.path.expanduser(pat)):
            if os.path.isdir(d) and looks_like.search(os.path.basename(d)):
                out.append(d)
    return out


# Games found by their file (Recomp, Switch) get a key from the file's NAME with versions and
# platform tags stripped, not from its full path. So when a game updates to a new file
# (Zelda64Recompiled-1.2.AppImage -> Zelda64Recompiled-1.3.AppImage, "Game [v2].nsp"), it keeps
# its key, and your collections, covers and names stay attached to it.
# (The bar does the same in gamesSlug() in shell.qml; keep the two the same.)
def game_slug(path):
    if path.endswith("/exefs/main"):
        base = os.path.basename(os.path.dirname(os.path.dirname(path)))
    else:
        base = os.path.basename(path)
    b = base.lower()
    b = re.sub(r"\.(appimage|xci|nsp|xcz|nsz|nro|nca)$", "", b)
    b = re.sub(r"\[[^\]]*\]|\([^)]*\)", "", b)
    b = re.sub(r"x86_64|amd64|x64|linux|release|portable", "", b)
    b = re.sub(r"v?\d+(\.\d+)+[a-z0-9]*", "", b)
    b = re.sub(r"[^a-z0-9]", "", b)
    return b or base.lower()

def is_update_file(path):
    low = os.path.basename(path).lower()
    return bool(re.search(r"\bupdate\b|\bdlc\b|\[v[1-9]\d*\]|\[[0-9a-f]{13}800\]", low))

def one_per_key(games):
    """Two files can now share a key (an old and a new build, or a game and its update file).
    Keep one: the real game over an update/DLC file, then the newest file."""
    best = {}
    for g in games:
        k = g["key"]
        try:
            t = os.path.getmtime(g["id"])
        except OSError:
            t = 0
        rank = (0 if g.get("_upd") else 1, t)
        if k not in best or rank > best[k][0]:
            best[k] = (rank, g)
    out = []
    for g in games:
        if best[g["key"]][1] is g:
            g.pop("_upd", None)
            out.append(g)
    return out

def clean_title(s):
    s = re.sub(r"\[[^\]]*\]|\([^)]*\)", "", s)            # [0100...] (v1.0) tags
    s = re.sub(r"(?i)\b(switch ?2|nsp|xci|base game|update|dlc)\b", "", s)
    return re.sub(r"\s+", " ", s.replace("_", " ")).strip(" -._") or s

def emu_games():
    out, exes, seen = [], {}, set()
    for src, label, names, cfgs, looks in EMULATORS:
        exe = emu_exe(names)
        exes[src] = exe
        roots = [d for d in dict.fromkeys(emu_config_dirs(cfgs) + guess_dirs(looks)) if os.path.isdir(d)]
        for root in roots:
            for dirpath, dirs, files in os.walk(root):
                rel = os.path.relpath(dirpath, root)
                if rel != "." and rel.count(os.sep) >= 3:
                    dirs[:] = []
                    continue
                cands = []
                # a dumped game left as folders: <Game>/exefs/main + romfs
                if os.path.isfile(os.path.join(dirpath, "exefs", "main")):
                    cands.append((os.path.join(dirpath, "exefs", "main"), clean_title(os.path.basename(dirpath))))
                    dirs[:] = []
                for fn in files:
                    if fn.lower().endswith(EMU_EXT):
                        cands.append((os.path.join(dirpath, fn), clean_title(os.path.splitext(fn)[0])))
                for p, n in cands:
                    real = os.path.realpath(p)
                    if real in seen:
                        continue
                    seen.add(real)
                    d = os.path.dirname(os.path.dirname(p)) if p.endswith("/exefs/main") else os.path.dirname(p)
                    icon = first(*[os.path.join(d, x) for x in ("cover.png", "cover.jpg", "icon.png", "icon.jpg")])
                    out.append({
                        "key": "%s:%s" % (src, game_slug(p)), "_upd": is_update_file(p), "id": p, "name": n, "src": src, "store": label,
                        "installed": bool(exe), "cover": ("file://" + icon) if icon else "",
                        "header": "", "last": int(os.path.getatime(p)),
                        "play": emu_command(exe, p) if exe else [], "install": [], "cols": [],
                    })
    return one_per_key(out), exes


# ---------------------------------------------------------------- cover art finder
ART_DIR = os.path.join(HOME, ".local/share/joeos/game-art")
COVERS = os.path.join(CACHE, "game-covers.json")     # game key -> picture file we found for it
UA = {"User-Agent": "JoeOS-games/1.0 (personal game library)"}

def fetch_json(url, headers=None, timeout=10):
    req = urllib.request.Request(url, headers=dict(UA, **(headers or {})))
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.load(r)

def search_name(name):
    """Tidy a game name for searching: drop 'Recompiled', version tags, and so on."""
    n = re.sub(r"(?i)\brecomp(iled)?\b", "", name)
    n = re.sub(r"(?i)\b(remaster(ed)?|definitive edition|goty|game of the year)\b", "", n)
    n = re.sub(r"[™®©]", "", n)
    return re.sub(r"\s+", " ", n).strip()

def find_covers(name, limit=8):
    """Cover pictures for a game from SteamGridDB (with your key), Steam and Wikipedia."""
    q = search_name(name)
    out = []
    key = os.environ.get("SGDB_KEY", "").strip()
    if key:
        try:
            auth = {"Authorization": "Bearer " + key}
            hits = fetch_json("https://www.steamgriddb.com/api/v2/search/autocomplete/" + urllib.parse.quote(q), auth).get("data", [])
            for h in hits[:2]:
                grids = fetch_json("https://www.steamgriddb.com/api/v2/grids/game/%s?dimensions=600x900,342x482,660x930" % h["id"], auth).get("data", [])
                for g in grids[:6]:
                    out.append({"url": g["url"], "thumb": g.get("thumb", g["url"]), "from": "SteamGridDB"})
        except Exception:
            pass
    try:
        items = fetch_json("https://store.steampowered.com/api/storesearch/?term=%s&l=english&cc=US" % urllib.parse.quote(q)).get("items", [])
        for it in items[:3]:
            u = "https://cdn.cloudflare.steamstatic.com/steam/apps/%s/library_600x900.jpg" % it["id"]
            out.append({"url": u, "thumb": u, "from": "Steam · " + it.get("name", "")})
    except Exception:
        pass
    try:
        d = fetch_json("https://en.wikipedia.org/w/api.php?action=query&format=json&generator=search&gsrlimit=4"
                       "&prop=pageimages&piprop=original|thumbnail&pithumbsize=400&gsrsearch=" + urllib.parse.quote(q + " video game"))
        pages = sorted(d.get("query", {}).get("pages", {}).values(), key=lambda p: p.get("index", 99))
        for pg in pages:
            if "original" in pg:
                out.append({"url": pg["original"]["source"], "thumb": pg.get("thumbnail", {}).get("source", pg["original"]["source"]),
                            "from": "Wikipedia · " + pg.get("title", "")})
    except Exception:
        pass
    seen, uniq = set(), []
    for c in out:
        if c["url"] not in seen:
            seen.add(c["url"]); uniq.append(c)
    return uniq[:limit]

def download(url, key):
    os.makedirs(ART_DIR, exist_ok=True)
    import hashlib
    ext = os.path.splitext(urllib.parse.urlparse(url).path)[1].lower()
    ext = ext if ext in (".jpg", ".jpeg", ".png", ".webp") else ".jpg"
    path = os.path.join(ART_DIR, hashlib.sha1(key.encode()).hexdigest()[:16] + ext)
    req = urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(req, timeout=20) as r:
        data = r.read()
    if len(data) < 2000:            # an error page, not a picture
        raise ValueError("too small")
    with open(path, "wb") as f:
        f.write(data)
    return path

def auto_covers(games, edited):
    """Find a cover for every game that has none (not ones you set yourself). Prints progress."""
    covers = load_json(COVERS, {})
    todo = [g for g in games if not g.get("cover") and g["key"] not in covers and g["key"] not in edited]
    done = 0
    for i, g in enumerate(todo):
        print("PROGRESS %d %d %s" % (i + 1, len(todo), g["name"]), flush=True)
        try:
            cands = find_covers(g["name"], limit=3)
            for c in cands:
                try:
                    covers[g["key"]] = download(c["url"], g["key"])
                    done += 1
                    break
                except Exception:
                    continue
            else:
                covers[g["key"]] = ""        # nothing found; don't keep trying every time
        except Exception:
            pass
        os.makedirs(CACHE, exist_ok=True)
        with open(COVERS, "w") as f:
            json.dump(covers, f)
    print("DONE %d %d" % (done, len(todo)), flush=True)

def apply_covers(games):
    covers = load_json(COVERS, {})
    for g in games:
        p = covers.get(g["key"])
        if p and not g.get("cover") and os.path.exists(p):
            g["cover"] = "file://" + p

# ---------------------------------------------------------------- main
def main():
    if len(sys.argv) > 2 and sys.argv[1] == "findcover":
        print(json.dumps({"covers": find_covers(" ".join(sys.argv[2:]))}))
        return
    if len(sys.argv) > 3 and sys.argv[1] == "savecover":      # savecover KEY URL -> local file path
        try:
            print(download(sys.argv[3], sys.argv[2]))
        except Exception:
            print("")
        return
    want_names = "--names" in sys.argv
    steam, cols, missing = steam_games()
    if want_names and missing:
        if fetch_names(missing):
            steam, cols, missing = steam_games()
    emu, emu_exes = emu_games()
    games = steam + heroic_games() + recomp_games() + emu
    if "--autocovers" in sys.argv:
        edited = set(a for a in sys.argv[sys.argv.index("--autocovers") + 1:] if not a.startswith("--"))
        auto_covers([g for g in games if g["src"] != "steam"], edited)
        return
    apply_covers(games)
    games.sort(key=lambda g: g["name"].lower())
    recomp_launcher = ""
    for p in [os.path.join(HOME, ".local/bin")] + os.environ.get("PATH", "").split(":"):
        hits = sorted(glob.glob(os.path.join(p, "RecompLauncher*.AppImage")) + glob.glob(os.path.join(p, "recomplauncher")))
        if hits:
            recomp_launcher = hits[-1]
            break
    print(json.dumps({"games": games, "collections": cols, "missingNames": len(missing),
                      "recompLauncher": recomp_launcher, "eglantine": emu_open(emu_exes["switch2"]) if emu_exes.get("switch2") else [],
                      "eden": emu_open(emu_exes["switch1"]) if emu_exes.get("switch1") else [], "at": int(time.time())}))

if __name__ == "__main__":
    main()
