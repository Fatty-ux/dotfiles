#!/usr/bin/env python3
"""JoeOS app store helper for the launcher's Store view.

    store.py search WORDS     find apps on Flathub, the Arch repos and the AUR  (JSON)
    store.py featured         popular apps to show before you search            (JSON)
    store.py flatinstall ID   install a Flathub app just for you (no password)
    store.py flatremove ID    remove it again
Only flatinstall/flatremove change anything; installing from the Arch repos and the AUR
happens in a terminal so you can see what's going on and type your password.
"""
import json, os, re, shutil, subprocess, sys, urllib.parse, urllib.request

ICON = "https://dl.flathub.org/repo/appstream/x86_64/icons/128x128/%s.png"

FEATURED = [
    ("com.discordapp.Discord", "Discord", "Chat with friends: voice, video and text"),
    ("dev.vencord.Vesktop", "Vesktop", "Discord with Vencord built in"),
    ("org.prismlauncher.PrismLauncher", "Prism Launcher", "Minecraft with mods and many instances"),
    ("com.spotify.Client", "Spotify", "Music and podcasts"),
    ("com.obsproject.Studio", "OBS Studio", "Record and stream your screen"),
    ("org.videolan.VLC", "VLC", "Plays any video or music file"),
    ("net.davidotek.pupgui2", "ProtonUp-Qt", "Get GE-Proton and other game fixes"),
    ("net.lutris.Lutris", "Lutris", "Play games from everywhere"),
    ("com.usebottles.bottles", "Bottles", "Run Windows programs"),
    ("org.kde.kdenlive", "Kdenlive", "Edit videos"),
    ("org.gimp.GIMP", "GIMP", "Edit pictures"),
    ("org.kde.krita", "Krita", "Digital painting"),
    ("org.blender.Blender", "Blender", "3D modelling and animation"),
    ("md.obsidian.Obsidian", "Obsidian", "Notes that link together"),
    ("org.libreoffice.LibreOffice", "LibreOffice", "Documents, spreadsheets and slides"),
    ("org.telegram.desktop", "Telegram", "Messaging"),
    ("fr.handbrake.ghb", "HandBrake", "Shrink and convert videos"),
    ("org.qbittorrent.qBittorrent", "qBittorrent", "Torrent downloads"),
    ("io.missioncenter.MissionCenter", "Mission Center", "See what's using your PC"),
    ("com.github.tchx84.Flatseal", "Flatseal", "Change what Flatpak apps can access"),
]

def run(cmd, timeout=25):
    try:
        return subprocess.run(cmd, capture_output=True, text=True, timeout=timeout).stdout
    except Exception:
        return ""

def installed_pkgs():
    return set(run(["pacman", "-Qq"]).split())

def installed_flatpaks():
    if not shutil.which("flatpak"):
        return set()
    return set(run(["flatpak", "list", "--app", "--columns=application"]).split())

def search_repo(q, have):
    out, cur = [], None
    for line in run(["pacman", "-Ss", "--", q]).splitlines():
        if line.startswith("    "):
            if cur:
                cur["desc"] = line.strip()
                out.append(cur)
                cur = None
            continue
        m = re.match(r"^(\S+)/(\S+) (\S+)", line)
        if m:
            cur = {"src": "repo", "repo": m.group(1), "id": m.group(2), "name": m.group(2), "version": m.group(3),
                   "installed": m.group(2) in have, "icon": "", "votes": 0}
    return out[:60]

def search_aur(q, have):
    try:
        url = "https://aur.archlinux.org/rpc/v5/search/%s?by=name-desc" % urllib.parse.quote(q)
        with urllib.request.urlopen(url, timeout=10) as r:
            data = json.load(r).get("results", [])
    except Exception:
        return []
    data.sort(key=lambda p: -(p.get("Popularity") or 0))
    return [{"src": "aur", "id": p["Name"], "name": p["Name"], "version": p.get("Version", ""),
             "desc": p.get("Description") or "", "installed": p["Name"] in have, "icon": "",
             "votes": p.get("NumVotes") or 0, "outdated": bool(p.get("OutOfDate"))} for p in data[:60]]

def search_flatpak(q, have):
    if not shutil.which("flatpak"):
        return []
    out = []
    for line in run(["flatpak", "search", "--columns=application,name,version,description,remotes", q]).splitlines():
        f = line.split("\t")
        if len(f) < 4 or "." not in f[0]:
            continue
        if len(f) >= 5 and "flathub" not in f[4]:
            continue
        out.append({"src": "flatpak", "id": f[0], "name": f[1], "version": f[2], "desc": f[3],
                    "installed": f[0] in have, "icon": ICON % f[0], "votes": 0})
    return out[:60]

def rank(items, q):
    ql = q.lower()
    def score(it):
        n = it["name"].lower()
        s = 0
        if n == ql: s -= 1000
        elif n.startswith(ql): s -= 500
        elif ql in n: s -= 200
        s -= {"flatpak": 30, "repo": 20, "aur": 0}[it["src"]]
        s -= min(it.get("votes", 0), 3000) / 30
        return s
    return sorted(items, key=score)

def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else ""
    if cmd == "search":
        q = " ".join(sys.argv[2:]).strip()
        if not q:
            print(json.dumps({"results": []})); return
        pk, fp = installed_pkgs(), installed_flatpaks()
        res = search_flatpak(q, fp) + search_repo(q, pk) + search_aur(q, pk)
        print(json.dumps({"results": rank(res, q), "query": q,
                          "hasParu": bool(shutil.which("paru") or shutil.which("yay")),
                          "hasFlatpak": bool(shutil.which("flatpak"))}))
    elif cmd == "featured":
        fp = installed_flatpaks()
        print(json.dumps({"results": [{"src": "flatpak", "id": i, "name": n, "version": "", "desc": d,
                                       "installed": i in fp, "icon": ICON % i, "votes": 0} for i, n, d in FEATURED],
                          "hasParu": bool(shutil.which("paru") or shutil.which("yay")),
                          "hasFlatpak": bool(shutil.which("flatpak"))}))
    elif cmd in ("flatinstall", "flatremove") and len(sys.argv) > 2:
        app = sys.argv[2]
        if cmd == "flatinstall":
            subprocess.run(["flatpak", "remote-add", "--user", "--if-not-exists", "flathub",
                            "https://dl.flathub.org/repo/flathub.flatpakrepo"], capture_output=True)
            r = subprocess.run(["flatpak", "install", "--user", "-y", "--noninteractive", "flathub", app], capture_output=True, text=True)
        else:
            r = subprocess.run(["flatpak", "uninstall", "-y", "--noninteractive", app], capture_output=True, text=True)
        print("ok" if r.returncode == 0 else "fail")
    else:
        print(__doc__)

if __name__ == "__main__":
    main()
