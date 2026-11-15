#!/usr/bin/env python3
"""JoeOS game library for the bar's Games view.

    games.py            print every game as JSON (Steam, Heroic, Recomp)
    games.py --names    also look up names of Steam games that aren't installed
                        (Steam store, a few each run, saved in ~/.cache/joeos/steam-names.json)

Only reads launcher files; it never changes anything.
"""
import glob, json, os, re, sys, time, urllib.request

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
                    "key": "recomp:" + real, "id": p, "name": name, "src": "recomp", "installed": True,
                    "cover": ("file://" + icon) if icon else "", "header": "", "last": int(os.path.getatime(p)),
                    "play": play, "install": [], "cols": [],
                })
    return out

# ---------------------------------------------------------------- main
def main():
    want_names = "--names" in sys.argv
    steam, cols, missing = steam_games()
    if want_names and missing:
        if fetch_names(missing):
            steam, cols, missing = steam_games()
    games = steam + heroic_games() + recomp_games()
    games.sort(key=lambda g: g["name"].lower())
    recomp_launcher = ""
    for p in [os.path.join(HOME, ".local/bin")] + os.environ.get("PATH", "").split(":"):
        hits = sorted(glob.glob(os.path.join(p, "RecompLauncher*.AppImage")) + glob.glob(os.path.join(p, "recomplauncher")))
        if hits:
            recomp_launcher = hits[-1]
            break
    print(json.dumps({"games": games, "collections": cols, "missingNames": len(missing),
                      "recompLauncher": recomp_launcher, "at": int(time.time())}))

if __name__ == "__main__":
    main()
