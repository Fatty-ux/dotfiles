import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import Quickshell.Io
import Quickshell.Services.SystemTray
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Qt.labs.folderlistmodel

ShellRoot {
    id: root

    // ---------- Theme (pick it on the Themes tab in the hub) ----------
    // 'seed' is the dominant vivid color found in the wallpaper.
    property color seed: "#89b4fa"
    property bool wallIsLight: false
    property var wallPalette: []          // the main colours of the wallpaper, as "#rrggbb"
    //   colorSource: "neutral" = black and white glass, "wallpaper" = colours from the wallpaper,
    //                "custom" = the colour you picked (customColor)
    //   themeStyle:  how the bars are drawn: "glass", "frosted", "clear", "solid" or "neon"
    //   themeShade:  "dark", "light" or "auto" (follows how bright the wallpaper is)
    //   themeTint:   how much the colour soaks into the glass (0 = only the accent, 1 = everything)
    readonly property string colorSource: pins.adapter.colorSource
    readonly property string themeStyle: pins.adapter.themeStyle
    readonly property string themeShade: pins.adapter.themeShade
    readonly property real themeTint: pins.adapter.themeTint
    readonly property bool glassTheme: colorSource === "neutral"
    readonly property bool dark: themeShade === "dark" || (themeShade !== "light" && !wallIsLight)
    readonly property color themeSeed: colorSource === "custom" ? pins.adapter.customColor : seed

    readonly property real hue: themeSeed.hslHue < 0 ? 0.6 : themeSeed.hslHue
    readonly property real sat: glassTheme ? 0
        : colorSource === "custom" ? Math.min(0.9, themeSeed.hslSaturation)
        : Math.max(0.35, Math.min(0.85, themeSeed.hslSaturation))
    readonly property real tsat: sat * themeTint      // saturation used for the glass itself

    // see-through-ness for each style: popup, surface, overlay (dark), then the same for light, then edge
    readonly property var styleTable: ({
        glass:   [0.42, 0.30, 0.45, 0.50, 0.38, 0.60, 0.24],
        frosted: [0.74, 0.46, 0.58, 0.80, 0.55, 0.72, 0.14],
        clear:   [0.20, 0.14, 0.28, 0.26, 0.20, 0.40, 0.34],
        solid:   [0.97, 0.92, 0.95, 0.98, 0.95, 0.97, 0.08],
        neon:    [0.55, 0.22, 0.38, 0.60, 0.30, 0.50, 0.75]
    })
    readonly property var styleA: styleTable[themeStyle] || styleTable.glass
    readonly property string customColor: pins.adapter.customColor

    readonly property color accentBase: glassTheme ? (dark ? Qt.rgba(0.90, 0.92, 0.95, 1) : Qt.rgba(0.16, 0.17, 0.20, 1))
        : colorSource === "custom"
            ? Qt.hsla(hue, sat, dark ? Math.max(0.55, Math.min(0.85, themeSeed.hslLightness)) : Math.max(0.25, Math.min(0.45, themeSeed.hslLightness)), 1)
            : (dark ? Qt.hsla(hue, sat, 0.72, 1) : Qt.hsla(hue, sat, 0.38, 1))

    property color bg: dark ? Qt.hsla(hue, tsat * 0.35, 0.10, 1) : Qt.hsla(hue, tsat * 0.30, 0.96, 1)
    // Liquid glass: surfaces are see-through and Hyprland blurs what's behind them
    // (layer rules in ~/.config/hypr/config/decorations.lua). The styleTable above sets how see-through.
    property color surface: dark ? Qt.hsla(hue, tsat * 0.30, 0.22, styleA[1]) : Qt.hsla(hue, tsat * 0.25, 0.99, styleA[4])
    property color overlay: dark ? Qt.hsla(hue, tsat * 0.30, 0.38, styleA[2]) : Qt.hsla(hue, tsat * 0.35, 0.86, styleA[5])
    property color popupBg: dark ? Qt.hsla(hue, tsat * 0.35, 0.10, styleA[0]) : Qt.hsla(hue, tsat * 0.25, 0.97, styleA[3])
    property color fg: dark ? Qt.hsla(hue, tsat * 0.30, 0.93, 1) : Qt.hsla(hue, tsat * 0.40, 0.14, 1)
    property color muted: dark ? Qt.hsla(hue, tsat * 0.20, 0.72, 1) : Qt.hsla(hue, tsat * 0.25, 0.38, 1)
    property color accent: accentBase
    property color danger: dark ? "#f38ba8" : "#c0264a"
    property color glassEdge: themeStyle === "neon" ? Qt.rgba(accentBase.r, accentBase.g, accentBase.b, styleA[6])
        : (dark ? Qt.rgba(1, 1, 1, styleA[6]) : Qt.rgba(1, 1, 1, Math.min(0.9, styleA[6] * 2.9)))

    // ---- what the Themes tab offers ----
    readonly property var themeStyles: [
        { id: "glass",   name: "Liquid glass", sub: "See-through and blurred" },
        { id: "frosted", name: "Frosted",      sub: "Thicker, softer glass" },
        { id: "clear",   name: "Crystal",      sub: "Almost invisible" },
        { id: "solid",   name: "Solid",        sub: "No see-through" },
        { id: "neon",    name: "Neon edge",    sub: "Glowing coloured rims" }
    ]
    readonly property var themePresets: [
        { name: "Liquid glass", source: "neutral",   style: "glass",   shade: "dark",  tint: 1,   color: "#e6eaf2" },
        { name: "Wallpaper",    source: "wallpaper", style: "glass",   shade: "auto",  tint: 1,   color: "" },
        { name: "Paper",        source: "neutral",   style: "frosted", shade: "light", tint: 1,   color: "#ffffff" },
        { name: "Catppuccin",   source: "custom",    style: "glass",   shade: "dark",  tint: 1,   color: "#cba6f7" },
        { name: "Tokyo Night",  source: "custom",    style: "glass",   shade: "dark",  tint: 1,   color: "#7aa2f7" },
        { name: "Nord",         source: "custom",    style: "frosted", shade: "dark",  tint: 1,   color: "#88c0d0" },
        { name: "Dracula",      source: "custom",    style: "glass",   shade: "dark",  tint: 1,   color: "#bd93f9" },
        { name: "Gruvbox",      source: "custom",    style: "solid",   shade: "dark",  tint: 1,   color: "#d79921" },
        { name: "Rosé Pine",    source: "custom",    style: "frosted", shade: "dark",  tint: 1,   color: "#ebbcba" },
        { name: "Everforest",   source: "custom",    style: "frosted", shade: "dark",  tint: 1,   color: "#a7c080" },
        { name: "Sakura",       source: "custom",    style: "frosted", shade: "light", tint: 1,   color: "#f5a9c4" },
        { name: "Ocean",        source: "custom",    style: "clear",   shade: "dark",  tint: 1,   color: "#4fc3f7" },
        { name: "Ember",        source: "custom",    style: "neon",    shade: "dark",  tint: 0.5, color: "#ff7a45" },
        { name: "Matrix",       source: "custom",    style: "neon",    shade: "dark",  tint: 0.5, color: "#39ff14" },
        { name: "Synthwave",    source: "custom",    style: "neon",    shade: "dark",  tint: 1,   color: "#ff4d8d" }
    ]
    readonly property var themeSwatches: [
        "#ff5555", "#e63946", "#c0392b", "#ff8a80", "#ff4d8d", "#ff79c6", "#f5a9c4", "#e91e63",
        "#b388ff", "#cba6f7", "#bd93f9", "#9b59b6", "#7e57c2", "#5c6bc0", "#7aa2f7", "#89b4fa",
        "#82aaff", "#3d8bff", "#1e88e5", "#4fc3f7", "#26c6da", "#00bcd4", "#88c0d0", "#94e2d5",
        "#1abc9c", "#00e676", "#2ecc71", "#a6e3a1", "#4caf50", "#a7c080", "#39ff14", "#c6ff00",
        "#f9e2af", "#ffd54f", "#f1c40f", "#d79921", "#fab387", "#ff9800", "#ff7a45", "#e64a19",
        "#d4a373", "#a1887f", "#8d6e63", "#ffffff", "#cfd8dc", "#9e9e9e", "#607d8b", "#37474f"
    ]

    function setTheme(src, style, shade, tint, colorHex) {
        if (src) pins.adapter.colorSource = src;
        if (style) pins.adapter.themeStyle = style;
        if (shade) pins.adapter.themeShade = shade;
        if (tint !== undefined && tint !== null) pins.adapter.themeTint = tint;
        if (colorHex) pins.adapter.customColor = colorHex;
    }
    function pickColor(hex) {
        pins.adapter.customColor = hex;
        pins.adapter.colorSource = "custom";
    }
    function themeLabel() {
        const s = themeStyles.find(x => x.id === themeStyle);
        const src = colorSource === "neutral" ? "Neutral" : colorSource === "wallpaper" ? "Wallpaper" : "Custom";
        return (s ? s.name : "Glass") + " · " + src;
    }

    // Colors fade smoothly when the wallpaper (or theme) changes
    Behavior on bg { ColorAnimation { duration: 700 } }
    Behavior on surface { ColorAnimation { duration: 700 } }
    Behavior on overlay { ColorAnimation { duration: 700 } }
    Behavior on popupBg { ColorAnimation { duration: 700 } }
    Behavior on fg { ColorAnimation { duration: 700 } }
    Behavior on muted { ColorAnimation { duration: 700 } }
    Behavior on accent { ColorAnimation { duration: 700 } }
    Behavior on danger { ColorAnimation { duration: 700 } }
    Behavior on glassEdge { ColorAnimation { duration: 700 } }

    // ---------- Your settings (edit, save, and the bars reload) ----------
    // Look and feel
    readonly property int animMs: gameMode ? 0 : 150   // animation speed in ms (0 = no animations; game mode turns them off)
    readonly property bool hoverZoom: true          // pinned icons grow when hovered
    readonly property string iconFont: "JetBrainsMono Nerd Font"   // font the bar icons come from
    // Clock
    readonly property bool use24h: false     // false = 12-hour time with AM/PM
    readonly property bool showSeconds: false
    readonly property string timePattern: (use24h ? "hh:mm" : "h:mm") + (showSeconds ? ":ss" : "") + (use24h ? "" : " AP")
    // Behavior
    readonly property real volumeStep: 0.05         // how much one scroll tick changes the volume
    // Bottom bar: what to show (workspaces and pinned apps are always shown)
    readonly property bool bottomShowWindowList: true
    readonly property bool bottomShowTray: true
    readonly property bool bottomShowMedia: true
    readonly property bool bottomShowClock: true
    readonly property bool bottomShowWallpaperButton: true
    readonly property int dockIconSize: 44         // size of the app icons on the bottom dock
    readonly property int pillIconSize: 30         // app icons on the small dock pill
    property real dockPillW: 200                   // how wide the dock pill is (the launcher grows out of it)
    // Top bar: a pill at the top centre that grows into the hub when clicked (see "Top bar: the island")
    // Weather (from Open-Meteo, no account or key needed). Put your own coordinates here.
    readonly property string weatherName: "Windsor, ON"
    readonly property real weatherLat: 42.3149
    readonly property real weatherLon: -83.0364
    readonly property bool weatherMetric: true      // false = Fahrenheit and mph
    // Desktops (workspaces): every monitor gets its own set
    readonly property int defaultDesktops: 4       // how many each monitor starts with
    readonly property int maxDesktops: 9
    readonly property bool showDesktopOsd: true    // small pop-up when you switch desktops
    // Auto-hide (switch it on/off from the control center):
    //   on  = both bars tuck away; touch the top or bottom edge with the mouse to bring one back.
    //         Windows shrink to fit while a bar is out and go back to full size when it hides.
    //   off = both bars always visible
    readonly property string autoHide: pins.adapter.autoHide
    readonly property bool autoHideOn: autoHide !== "off"
    readonly property int hideDelayMs: 450        // wait before hiding after the mouse leaves
    readonly property int hotZoneSize: 6          // thickness of the invisible hover strip at the screen edge (px)

    // ---------- Shared state ----------
    SystemClock {
        id: clock
        precision: root.showSeconds ? SystemClock.Seconds : SystemClock.Minutes
    }

    // Pinned apps are saved here so they survive restarts.
    // (Run `mkdir -p ~/.local/state` once if that folder doesn't exist.)
    FileView {
        id: pins
        path: Quickshell.env("HOME") + "/.local/state/quickshell-pins.json"
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) writeAdapter();
        }
        adapter: JsonAdapter {
            property list<string> pinned: ["firefox", "kitty"]
            property string wallpaper: ""
            property string liveWallpaper: ""   // a video from ~/Videos/Wallpapers ("" = none)
            property string themeMode: "glass"     // old setting, only read once to move you to the new ones
            property bool themeV2: false
            property string colorSource: "neutral"
            property string themeStyle: "glass"
            property string themeShade: "dark"
            property real themeTint: 1
            property string customColor: "#89b4fa"
            property bool glassDefaultSet: false    // switched to the glass theme once
            property string autoHide: "windows"
            property string desktopsJson: ""
            property string historyJson: ""     // which apps were opened, how often and when (launcher tabs)
            property string sportsLeague: "nba"  // league shown on the Sports tab
            property string sportsFav: ""        // favourite team: "league|teamId|ABBR"
            property bool gameMode: false        // game mode stays on across restarts
            property bool restoreSession: true   // reopen apps on their desktops after logging in
            property bool topPillAlways: true    // the top pill stays on screen (no pull tab)
            property bool lyricsOpen: false      // the left panel stays open across restarts
            property string leftTab: "lyrics"    // which tab the left panel shows
            property int dispSat: 100            // Display tab: saturation %
            property int dispCon: 100            //   contrast %
            property int dispTemp: 6500          //   warmth in Kelvin (6500 = off)
            property int dispBri: 100            //   brightness %
        }
    }

    // System (PipeWire) volume
    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }
    readonly property var sink: Pipewire.defaultAudioSink

    // Microphone (default input) and every sound device, for the switchers in the hub
    PwObjectTracker { objects: [Pipewire.defaultAudioSource] }
    readonly property var source: Pipewire.defaultAudioSource
    property string devPicker: ""     // "out" or "in" while the device list is open

    readonly property var outputDevices: {
        const out = [], list = Pipewire.nodes.values;
        for (let i = 0; i < list.length; i++)
            if (list[i].audio && list[i].isSink && !list[i].isStream) out.push(list[i]);
        return out;
    }
    readonly property var inputDevices: {
        const out = [], list = Pipewire.nodes.values;
        for (let i = 0; i < list.length; i++)
            if (list[i].audio && !list[i].isSink && !list[i].isStream) out.push(list[i]);
        return out;
    }

    function devName(n) {
        return n ? (n.description || n.nickname || n.name) : "None";
    }

    function setDevice(n) {
        if (devPicker === "in") Pipewire.preferredDefaultAudioSource = n;
        else Pipewire.preferredDefaultAudioSink = n;
        devPicker = "";
    }

    onHubOpenChanged: if (!hubOpen) devPicker = ""

    // Wallpapers: drop images into ~/Pictures/Wallpapers
    FolderListModel {
        id: wallpapers
        folder: "file://" + Quickshell.env("HOME") + "/Pictures/Wallpapers"
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.JPG", "*.JPEG", "*.PNG", "*.WEBP"]
        showDirs: false
    }

    // ---------- Wallpaper picker (centre of the screen) ----------
    property bool wallPickerOpen: false

    // Optional, in hyprland.conf:  bind = SUPER, W, global, quickshell:wallpaper
    GlobalShortcut {
        appid: "quickshell"
        name: "wallpaper"
        description: "Open the wallpaper picker"
        onPressed: root.wallPickerOpen = !root.wallPickerOpen
    }

    // Alternative:  quickshell ipc call wallpaper toggle
    IpcHandler {
        target: "wallpaper"
        function toggle(): void {
            root.wallPickerOpen = !root.wallPickerOpen;
        }
    }

    function setWallpaper(url) {
        pins.adapter.liveWallpaper = "";          // a picture replaces any live wallpaper
        pins.adapter.wallpaper = url;
    }

    // ---------- Live wallpapers (videos in ~/Videos/Wallpapers) ----------
    // The video plays behind everything (LiveWallpaper.qml). A still frame of it becomes the
    // normal wallpaper too, so the bar colours, terminal colours and lock screen all match it.
    readonly property string liveThumbDir: Quickshell.env("HOME") + "/.cache/joeos/live-thumbs"
    property bool liveThumbsReady: false
    property bool liveNoFfmpeg: false
    property bool liveUnavailable: false      // Qt video support missing
    property bool livePaused: false

    function liveThumbFor(fileName) {
        return "file://" + liveThumbDir + "/" + fileName + ".jpg";
    }

    function setLiveWallpaper(videoUrl, fileName) {
        pins.adapter.wallpaper = liveThumbFor(fileName);
        pins.adapter.liveWallpaper = videoUrl;
    }

    FolderListModel {
        id: liveVideos
        folder: "file://" + Quickshell.env("HOME") + "/Videos/Wallpapers"
        nameFilters: ["*.mp4", "*.webm", "*.mkv", "*.mov", "*.MP4", "*.WEBM", "*.MKV", "*.MOV"]
        showDirs: false
    }

    Process {
        id: liveThumbProc
        command: ["bash", Quickshell.env("HOME") + "/.config/quickshell/scripts/livethumbs.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.liveNoFfmpeg = text.indexOf("NOFFMPEG") >= 0;
                root.liveThumbsReady = true;
            }
        }
    }

    function refreshLiveThumbs() {
        if (liveThumbProc.running) return;
        liveThumbsReady = false;
        liveThumbProc.running = true;
    }

    // ---------- Lock screen follows the desktop wallpaper ----------
    // Writes the wallpaper's path to ~/.config/hypr/hyprlock-wallpaper.conf as $wallpaper,
    // which hyprlock.conf reads (source = ...) and uses for its background.
    readonly property string lockWallpaper: pins.adapter.wallpaper
    onLockWallpaperChanged: writeLockWallpaper()

    function writeLockWallpaper() {
        let path = lockWallpaper;
        if (path.indexOf("file://") === 0) path = decodeURIComponent(path.slice(7));
        Quickshell.execDetached(["sh", "-c",
            'mkdir -p "$HOME/.config/hypr" && printf "%s\\n" "\\$wallpaper = $1" > "$HOME/.config/hypr/hyprlock-wallpaper.conf"',
            "sh", path]);
    }

    function randomWallpaper() {
        if (wallpapers.count === 0) return;
        const i = Math.floor(Math.random() * wallpapers.count);
        setWallpaper(wallpapers.get(i, "fileUrl").toString());
    }

    // True when the workspace currently shown on this screen has any windows
    function workspaceHasWindows(screen) {
        const list = Hyprland.workspaces.values;
        for (let i = 0; i < list.length; i++) {
            const ws = list[i];
            if (ws.active && ws.monitor && ws.monitor.name === screen.name)
                return ws.toplevels.values.length > 0;
        }
        return false;
    }

    // ---------- App launcher state ----------
    property bool launcherOpen: false
    property int launcherTab: 0       // 0 = all, 1 = recent, 2 = frequent, 3 = pinned

    // Bind in hyprland.conf:  bind = SUPER, SPACE, global, quickshell:launcher
    GlobalShortcut {
        appid: "quickshell"
        name: "launcher"
        description: "Toggle the app launcher"
        onPressed: root.launcherOpen = !root.launcherOpen
    }

    // Alternative:  qs ipc call launcher toggle
    IpcHandler {
        target: "launcher"
        function toggle(): void {
            root.launcherOpen = !root.launcherOpen;
        }
    }

    // ---------- Launch history (for the Recent and Frequent tabs) ----------
    readonly property var launchHistory: {
        try {
            return JSON.parse(pins.adapter.historyJson || "{}");
        } catch (e) {
            return {};
        }
    }

    function recordLaunch(entry) {
        if (!entry || !entry.id) return;
        const src = launchHistory, out = {};
        for (const k in src) out[k] = { c: src[k].c, t: src[k].t };
        const old = out[entry.id];
        out[entry.id] = { c: (old ? old.c : 0) + 1, t: Date.now() };
        // keep the 60 most recent so the file stays small
        const keys = Object.keys(out).sort((a, b) => out[b].t - out[a].t);
        for (let i = 60; i < keys.length; i++) delete out[keys[i]];
        pins.adapter.historyJson = JSON.stringify(out);
    }

    // Use this instead of entry.execute() so the launch shows up in Recent / Frequent
    function launchApp(entry) {
        if (!entry) return;
        recordLaunch(entry);
        entry.execute();
    }

    function entriesById() {
        const map = {};
        const all = DesktopEntries.applications.values;
        for (let i = 0; i < all.length; i++) map[all[i].id] = all[i];
        return map;
    }

    // What a launcher tab shows. Typing always searches every app.
    function appsForTab(tab, query) {
        if (query.trim() !== "" || tab === 0) return searchApps(query);
        if (tab === 3) {
            const out = [];
            const list = pins.adapter.pinned;
            for (let i = 0; i < list.length; i++) {
                const e = DesktopEntries.heuristicLookup(list[i]);
                if (e) out.push(e);
            }
            return out;
        }
        const h = launchHistory, map = entriesById();
        const keys = Object.keys(h).filter(k => map[k] && !map[k].noDisplay);
        if (tab === 1) keys.sort((a, b) => h[b].t - h[a].t);
        else keys.sort((a, b) => (h[b].c - h[a].c) || (h[b].t - h[a].t));
        return keys.slice(0, 24).map(k => map[k]);
    }

    function searchApps(query) {
        const all = DesktopEntries.applications.values;
        const q = query.trim().toLowerCase();
        const out = [];
        for (let i = 0; i < all.length; i++) {
            const e = all[i];
            if (e.noDisplay) continue;
            const name = (e.name || "").toLowerCase();
            let score = 0;
            if (q === "") {
                score = 1;
            } else if (name.startsWith(q)) {
                score = 100;
            } else if (name.includes(q)) {
                score = 60;
            } else {
                const extra = ((e.genericName || "") + " " + (e.comment || "") + " "
                    + String(e.keywords || "")).toLowerCase();
                if (extra.includes(q)) score = 20;
            }
            if (score > 0) out.push({ entry: e, score: score, name: name });
        }
        out.sort((a, b) => (b.score - a.score) || (a.name < b.name ? -1 : (a.name > b.name ? 1 : 0)));
        return out.map(o => o.entry);
    }

    // The player shown in the media tab: whichever is playing, else the first
    readonly property var player: pickPlayer()

    function playing(p) {
        return p && p.playbackState == MprisPlaybackState.Playing;
    }

    function pickPlayer() {
        const list = Mpris.players.values;
        for (let i = 0; i < list.length; i++)
            if (playing(list[i])) return list[i];
        return list.length > 0 ? list[0] : null;
    }

    // The PipeWire audio stream belonging to a media player (Spotify, Firefox, mpv...)
    function playerStream(p) {
        if (!p) return null;
        const who = ((p.identity || "") + " " + (p.desktopEntry || "")).toLowerCase();
        const list = audioStreams;
        for (let i = 0; i < list.length; i++) {
            const pr = list[i].properties || {};
            const app = (pr["application.name"] || "").toLowerCase();
            const bin = (pr["application.process.binary"] || "").toLowerCase();
            if ((app && who.indexOf(app) >= 0) || (bin && who.indexOf(bin) >= 0)) return list[i];
        }
        return null;
    }

    // Volume for one player: its own audio stream, else the player's own volume, else the speakers
    function mediaVolume(p) {
        const st = playerStream(p);
        if (st && st.audio) return st.audio.volume;
        if (p && p.volumeSupported) return p.volume;
        return sink && sink.audio ? sink.audio.volume : 0;
    }

    function setMediaVolume(p, v) {
        v = Math.max(0, Math.min(1, v));
        const st = playerStream(p);
        if (st && st.audio) st.audio.volume = v;
        else if (p && p.volumeSupported) p.volume = v;
        else if (sink && sink.audio) sink.audio.volume = v;
    }

    function mediaMuted(p) {
        const st = playerStream(p);
        if (st && st.audio) return st.audio.muted;
        return sink && sink.audio ? sink.audio.muted : false;
    }

    function toggleMediaMute(p) {
        const st = playerStream(p);
        if (st && st.audio) st.audio.muted = !st.audio.muted;
        else if (sink && sink.audio) sink.audio.muted = !sink.audio.muted;
    }

    function fmt(sec) {
        if (!isFinite(sec) || sec < 0) return "0:00";
        const s = Math.floor(sec);
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
    }

    function windowsFor(appId) {
        const out = [];
        const list = ToplevelManager.toplevels.values;
        const id = appId.toLowerCase();
        for (let i = 0; i < list.length; i++)
            if (list[i].appId.toLowerCase() === id) out.push(list[i]);
        return out;
    }

    function isPinned(appId) {
        const list = pins.adapter.pinned;
        const id = appId.toLowerCase();
        for (let i = 0; i < list.length; i++)
            if (list[i].toLowerCase() === id) return true;
        return false;
    }

    function pin(appId) {
        if (!appId || isPinned(appId)) return;
        const list = pins.adapter.pinned;
        const out = [];
        for (let i = 0; i < list.length; i++) out.push(list[i]);
        out.push(appId);
        pins.adapter.pinned = out;
    }

    function unpin(appId) {
        const list = pins.adapter.pinned;
        const id = appId.toLowerCase();
        const out = [];
        for (let i = 0; i < list.length; i++)
            if (list[i].toLowerCase() !== id) out.push(list[i]);
        pins.adapter.pinned = out;
    }

    // ---------- Wallpaper color extraction ----------
    // Called with RGBA bytes sampled from a small copy of the wallpaper
    function applyPalette(data) {
        const bins = 24;
        const weight = [], sr = [], sg = [], sb = [];
        for (let k = 0; k < bins; k++) { weight.push(0); sr.push(0); sg.push(0); sb.push(0); }
        let lum = 0, count = 0, ar = 0, ag = 0, ab = 0;
        for (let i = 0; i < data.length; i += 4) {
            const r = data[i] / 255, g = data[i + 1] / 255, b = data[i + 2] / 255;
            const mx = Math.max(r, g, b), mn = Math.min(r, g, b);
            const l = (mx + mn) / 2;
            lum += 0.2126 * r + 0.7152 * g + 0.0722 * b;
            ar += r; ag += g; ab += b; count++;
            const d = mx - mn;
            if (d < 0.08 || l < 0.12 || l > 0.92) continue;     // skip greys, near-black and near-white
            const s = d / (1 - Math.abs(2 * l - 1));
            let h;
            if (mx === r) h = ((g - b) / d) % 6;
            else if (mx === g) h = (b - r) / d + 2;
            else h = (r - g) / d + 4;
            h = (h * 60 + 360) % 360;
            const bi = Math.floor(h / (360 / bins)) % bins;
            const w = s * (1 - Math.abs(l - 0.5) * 1.2);         // favor vivid, mid-brightness pixels
            weight[bi] += w; sr[bi] += r * w; sg[bi] += g * w; sb[bi] += b * w;
        }
        let best = -1, bestW = 0;
        for (let k = 0; k < bins; k++) if (weight[k] > bestW) { bestW = weight[k]; best = k; }
        // the wallpaper's main colours, strongest first, for the Themes tab
        const hex = v => ("0" + Math.round(Math.max(0, Math.min(1, v)) * 255).toString(16)).slice(-2);
        const order = [];
        for (let k = 0; k < bins; k++) if (weight[k] > 3) order.push(k);
        order.sort((x, y) => weight[y] - weight[x]);
        const pal = order.slice(0, 7).map(k => "#" + hex(sr[k] / weight[k]) + hex(sg[k] / weight[k]) + hex(sb[k] / weight[k]));
        if (count > 0) pal.push("#" + hex(ar / count) + hex(ag / count) + hex(ab / count));
        wallPalette = pal;
        wallIsLight = count > 0 && (lum / count) > 0.6;
        if (best >= 0 && bestW > 6) {
            seed = Qt.rgba(sr[best] / weight[best], sg[best] / weight[best], sb[best] / weight[best], 1);
        } else if (count > 0) {
            seed = Qt.rgba(ar / count, ag / count, ab / count, 1);    // greyscale wallpaper
        }
    }

    // existing setups get switched to the glass theme once (after that it's up to you)
    Timer {
        interval: 2500
        running: true
        onTriggered: {
            if (!pins.adapter.glassDefaultSet) {
                pins.adapter.themeMode = "glass";
                pins.adapter.glassDefaultSet = true;
            }
            // move the old theme setting over to the Themes tab settings, once
            if (!pins.adapter.themeV2) {
                const m = pins.adapter.themeMode;
                if (m === "glass") root.setTheme("neutral", "glass", "dark", 1, "");
                else root.setTheme("wallpaper", "glass", m === "light" ? "light" : (m === "dark" ? "dark" : "auto"), 1, "");
                pins.adapter.themeV2 = true;
            }
        }
    }

    // quick toggle: step through the styles (everything else is on the Themes tab)
    function cycleTheme() {
        const ids = themeStyles.map(s => s.id);
        pins.adapter.themeStyle = ids[(ids.indexOf(themeStyle) + 1) % ids.length];
    }

    function cycleAutoHide() {
        pins.adapter.autoHide = pins.adapter.autoHide === "off" ? "always" : "off";
    }

    // ---------- Top bar pull-down tab ----------
    property bool topBarOpen: false

    // Optional, in hyprland.conf:  bind = SUPER, T, global, quickshell:topbar
    GlobalShortcut {
        appid: "quickshell"
        name: "topbar"
        description: "Pull the top bar down / push it back up"
        onPressed: root.topBarOpen = !root.topBarOpen
    }

    // Alternative:  quickshell ipc call topbar toggle
    IpcHandler {
        target: "topbar"
        function toggle(): void {
            root.topBarOpen = !root.topBarOpen;
        }
    }

    // ---------- Control center state ----------
    property bool panelOpen: false
    property double panelClosedAt: 0
    property bool dnd: false          // do not disturb: no pop-up toasts
    property int tab: 0               // 0 = settings, 1 = volume, 2 = performance

    GlobalShortcut {
        appid: "quickshell"
        name: "panel"
        description: "Toggle the control center"
        onPressed: root.panelOpen = !root.panelOpen
    }

    // Alternative:  quickshell ipc call panel toggle
    IpcHandler {
        target: "panel"
        function toggle(): void {
            root.panelOpen = !root.panelOpen;
        }
    }

    // ---------- Notifications ----------
    // This replaces mako/dunst while Quickshell is running (only one can own notifications)
    property int toastSeq: 0
    ListModel { id: toastModel }

    NotificationServer {
        id: notifServer
        keepOnReload: true
        bodySupported: true
        imageSupported: true
        actionsSupported: true
        onNotification: n => {
            n.tracked = true;
            if (root.dnd) return;
            root.toastSeq += 1;
            toastModel.append({
                tid: root.toastSeq,
                nid: n.id,
                summary: n.summary,
                body: n.body,
                appName: n.appName,
                critical: n.urgency === NotificationUrgency.Critical
            });
            while (toastModel.count > 4) toastModel.remove(0);
        }
    }

    // ---- Clicking a notification opens the app it came from ----
    function notifById(id) {
        const list = notifServer.trackedNotifications.values;
        for (let i = 0; i < list.length; i++) if (list[i].id === id) return list[i];
        return null;
    }

    // names an app might go by: "Vesktop", "vesktop", "com.spotify.Client" -> "spotify", ...
    function appKeys(n) {
        const keys = [];
        const add = v => {
            if (!v) return;
            v = String(v).toLowerCase().replace(/\.desktop$/, "");
            for (const k of [v, v.replace(/ /g, "-"), v.replace(/ /g, ""), v.split(".").pop()])
                if (k && keys.indexOf(k) < 0) keys.push(k);
        };
        add(n.desktopEntry);
        add(n.appName);
        const e = DesktopEntries.heuristicLookup(n.desktopEntry || n.appName);
        if (e) {
            add(e.id);
            add(e.startupClass);
            add(e.name);
        }
        return keys;
    }

    // the open window of the app that sent it (prefers one whose title mentions the message)
    function windowForNotif(n) {
        const keys = appKeys(n);
        const list = ToplevelManager.toplevels.values;
        let best = null, bestScore = 0;
        for (let i = 0; i < list.length; i++) {
            const id = (list[i].appId || "").toLowerCase();
            const last = id.split(".").pop();
            let score = 0;
            for (const k of keys) {
                if (id === k) score = Math.max(score, 3);
                else if (last === k || last === k.split(".").pop()) score = Math.max(score, 2);
                else if (k.length > 3 && (id.indexOf(k) >= 0 || k.indexOf(last) >= 0)) score = Math.max(score, 1);
            }
            if (score > 0 && n.summary && (list[i].title || "").toLowerCase().indexOf(n.summary.toLowerCase()) >= 0) score += 0.5;
            if (score > bestScore) { best = list[i]; bestScore = score; }
        }
        return best;
    }

    function openNotification(n) {
        if (!n) return;
        // work out the window first: invoking the notification can make it disappear
        const win = windowForNotif(n);
        const entry = DesktopEntries.heuristicLookup(n.desktopEntry || n.appName);
        let def = null;
        const acts = n.actions || [];
        for (let i = 0; i < acts.length; i++) if (acts[i].identifier === "default") def = acts[i];

        // 1. let the app jump to the exact chat / email / tab (its own "default" action)
        if (def) def.invoke();
        // 2. bring its window to the front, switching desktop if it's on another one
        if (win) win.activate();
        // 3. not open at all? start it
        else if (!def && entry) entry.execute();
        // 4. it's been seen: clear it (invoking already does this for most apps)
        if (!def) n.dismiss();

        hubOpen = false;
        panelOpen = false;
    }

    function removeToast(tid) {
        for (let i = 0; i < toastModel.count; i++) {
            if (toastModel.get(i).tid === tid) {
                toastModel.remove(i);
                return;
            }
        }
    }

    function clearNotifications() {
        const list = notifServer.trackedNotifications.values;
        for (let i = list.length - 1; i >= 0; i--) list[i].dismiss();
        toastModel.clear();
    }

    // ---------- Apps that are playing audio (for the Volume tab) ----------
    PwObjectTracker { objects: Pipewire.nodes.values }

    readonly property var audioStreams: {
        const out = [];
        const list = Pipewire.nodes.values;
        for (let i = 0; i < list.length; i++) {
            const n = list[i];
            if (n.isStream && !n.isSink && n.audio) out.push(n);
        }
        return out;
    }

    // ---------- System stats (for the Performance tab) ----------
    property real cpuUsage: 0
    property real memUsage: 0
    property real swapUsage: 0
    property string loadAvg: ""
    property real lastCpuTotal: 0
    property real lastCpuIdle: 0

    FileView {
        id: statFile
        path: "/proc/stat"
        onLoaded: {
            const parts = text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
            const idle = parts[3] + (parts[4] || 0);
            let total = 0;
            for (let i = 0; i < parts.length; i++) total += parts[i];
            if (root.lastCpuTotal > 0) {
                const dt = total - root.lastCpuTotal;
                const di = idle - root.lastCpuIdle;
                root.cpuUsage = dt > 0 ? Math.max(0, Math.min(1, 1 - di / dt)) : 0;
            }
            root.lastCpuTotal = total;
            root.lastCpuIdle = idle;
        }
    }

    FileView {
        id: memFile
        path: "/proc/meminfo"
        onLoaded: {
            const t = text();
            const get = key => {
                const m = t.match(new RegExp(key + ":\\s+(\\d+)"));
                return m ? Number(m[1]) : 0;
            };
            const total = get("MemTotal"), avail = get("MemAvailable");
            const sTotal = get("SwapTotal"), sFree = get("SwapFree");
            root.memUsage = total > 0 ? 1 - avail / total : 0;
            root.swapUsage = sTotal > 0 ? 1 - sFree / sTotal : 0;
        }
    }

    FileView {
        id: loadFile
        path: "/proc/loadavg"
        onLoaded: root.loadAvg = text().trim().split(" ").slice(0, 3).join("   ")
    }

    Timer {
        interval: 1500
        repeat: true
        running: true                 // the top pill always shows CPU and RAM
        triggeredOnStart: true
        onTriggered: {
            statFile.reload();
            memFile.reload();
            loadFile.reload();
        }
    }

    // ---------- Close everything ----------
    signal closeAllRequested()

    function closeAll() {
        launcherOpen = false;
        panelOpen = false;
        weatherOpen = false;
        wallPickerOpen = false;
        hubOpen = false;
        switcherOpen = false;
        sideOpen = false;
        closeAllRequested();
    }

    // Switching workspace also closes any open popup or panel
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "workspacev2") root.closeAll();
        }
    }

    // ---------- Weather (Open-Meteo, no account or key needed) ----------
    property bool weatherOpen: false
    property double weatherClosedAt: 0
    property var wx: null
    property string wxStatus: "Loading weather..."

    GlobalShortcut {
        appid: "quickshell"
        name: "weather"
        description: "Toggle the weather panel"
        onPressed: root.weatherOpen = !root.weatherOpen
    }

    // Alternative:  quickshell ipc call weather toggle
    IpcHandler {
        target: "weather"
        function toggle(): void {
            root.weatherOpen = !root.weatherOpen;
        }
    }

    function fetchWeather() {
        const url = "https://api.open-meteo.com/v1/forecast?latitude=" + weatherLat
            + "&longitude=" + weatherLon
            + "&current=temperature_2m,apparent_temperature,relative_humidity_2m,is_day,weather_code,pressure_msl,wind_speed_10m"
            + "&hourly=temperature_2m,weather_code,precipitation_probability"
            + "&daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset,uv_index_max,precipitation_probability_max"
            + "&timezone=auto&forecast_days=7"
            + (weatherMetric ? "" : "&temperature_unit=fahrenheit&wind_speed_unit=mph");
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;
            if (xhr.status === 200) {
                try {
                    root.wx = JSON.parse(xhr.responseText);
                    root.wxStatus = "";
                } catch (e) {
                    root.wxStatus = "Could not read the weather data";
                    weatherRetry.restart();
                }
            } else {
                root.wxStatus = "Weather unavailable (error " + xhr.status + ")";
                weatherRetry.restart();
            }
        };
        xhr.open("GET", url);
        xhr.send();
    }

    Timer {
        interval: 15 * 60 * 1000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.fetchWeather()
    }

    Timer {
        id: weatherRetry
        interval: 60 * 1000
        onTriggered: root.fetchWeather()
    }

    function wxText(code) {
        if (code === 0) return "Clear";
        if (code === 1) return "Mostly clear";
        if (code === 2) return "Partly cloudy";
        if (code === 3) return "Overcast";
        if (code === 45 || code === 48) return "Fog";
        if (code >= 51 && code <= 57) return "Drizzle";
        if (code >= 61 && code <= 67) return "Rain";
        if (code >= 71 && code <= 77) return "Snow";
        if (code >= 80 && code <= 82) return "Showers";
        if (code === 85 || code === 86) return "Snow showers";
        if (code >= 95) return "Thunderstorm";
        return "Unknown";
    }

    function wxIcon(code, day) {
        if (code === 0 || code === 1) return day ? "☀" : "☾";
        if (code === 2 || code === 3 || code === 45 || code === 48) return "☁";
        if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82)) return "☂";
        if ((code >= 71 && code <= 77) || code === 85 || code === 86) return "❄";
        if (code >= 95) return "⚡";
        return "☁";
    }

    readonly property var wxNow: {
        if (!wx || !wx.current || !wx.daily) return null;
        const c = wx.current, d = wx.daily;
        const fmt = root.use24h ? "hh:mm" : "h:mm AP";
        return {
            temp: Math.round(c.temperature_2m),
            feels: Math.round(c.apparent_temperature),
            humidity: Math.round(c.relative_humidity_2m),
            pressure: Math.round(c.pressure_msl),
            wind: Math.round(c.wind_speed_10m),
            desc: wxText(c.weather_code),
            icon: wxIcon(c.weather_code, c.is_day === 1),
            hi: Math.round(d.temperature_2m_max[0]),
            lo: Math.round(d.temperature_2m_min[0]),
            uv: Math.round(d.uv_index_max[0]),
            sunrise: Qt.formatDateTime(new Date(d.sunrise[0]), fmt),
            sunset: Qt.formatDateTime(new Date(d.sunset[0]), fmt)
        };
    }

    // Next 8 hours
    readonly property var wxHours: {
        if (!wx || !wx.hourly) return [];
        const h = wx.hourly, out = [];
        const cutoff = Date.now() - 30 * 60 * 1000;
        for (let i = 0; i < h.time.length && out.length < 8; i++) {
            const d = new Date(h.time[i]);
            if (d.getTime() < cutoff) continue;
            out.push({
                label: Qt.formatDateTime(d, root.use24h ? "hh" : "h AP"),
                icon: wxIcon(h.weather_code[i], d.getHours() >= 6 && d.getHours() < 20),
                temp: Math.round(h.temperature_2m[i])
            });
        }
        return out;
    }

    // Next 7 days
    readonly property var wxDays: {
        if (!wx || !wx.daily) return [];
        const d = wx.daily, out = [];
        for (let i = 0; i < d.time.length; i++) {
            out.push({
                day: i === 0 ? "Today" : Qt.formatDateTime(new Date(d.time[i] + "T12:00"), "ddd"),
                icon: wxIcon(d.weather_code[i], true),
                lo: Math.round(d.temperature_2m_min[i]),
                hi: Math.round(d.temperature_2m_max[i]),
                rain: d.precipitation_probability_max[i]
            });
        }
        return out;
    }

    // ---------- Desktop manager ----------
    // Desktops are LINKED across monitors: desktop 1 is desktop 1 on every screen, and switching
    // moves all monitors together. Each monitor still has its own Hyprland workspace behind each
    // desktop (that's how Hyprland works), but the lists are kept the same length and in step.
    // The lists are saved, so an empty desktop stays until you delete it.
    readonly property var deskMap: {
        try {
            return JSON.parse(pins.adapter.desktopsJson || "{}");
        } catch (e) {
            return {};
        }
    }

    // Runs each Lua dispatcher through hyprctl, one after the other.
    // Switching monitors makes Hyprland move the mouse, so it's noted first and put back after.
    function hyprList(exprs) {
        const parts = ['pos=$(hyprctl cursorpos 2>/dev/null)'];
        for (let i = 0; i < exprs.length; i++)
            parts.push("hyprctl dispatch '" + exprs[i] + "'");
        parts.push('case "$pos" in *,*) x=${pos%%,*}; y=${pos##*,}; '
            + 'hyprctl dispatch "hl.dsp.cursor.move({ x = ${x% *}, y = ${y# } })" ;; esac');
        Quickshell.execDetached(["sh", "-c", parts.join("; ") + " >/dev/null 2>&1"]);
    }

    function workspaceById(id) {
        const list = Hyprland.workspaces.values;
        for (let i = 0; i < list.length; i++)
            if (list[i].id === id) return list[i];
        return null;
    }

    function wsWindowCount(id) {
        const ws = workspaceById(id);
        return ws ? ws.toplevels.values.length : 0;
    }

    // The workspace currently shown on a monitor
    function activeWsId(monitorName) {
        const list = Hyprland.workspaces.values;
        for (let i = 0; i < list.length; i++) {
            const ws = list[i];
            if (ws.active && ws.monitor && ws.monitor.name === monitorName) return ws.id;
        }
        return -1;
    }

    function copyMap() {
        const out = {};
        const src = deskMap;
        for (const k in src) out[k] = src[k].slice();
        return out;
    }

    function saveDesk(map) {
        pins.adapter.desktopsJson = JSON.stringify(map);
    }

    // Lowest workspace number that nothing is using yet
    function freeId(map) {
        const used = {};
        for (const k in map)
            for (let i = 0; i < map[k].length; i++) used[map[k][i]] = true;
        const list = Hyprland.workspaces.values;
        for (let i = 0; i < list.length; i++)
            if (list[i].id > 0) used[list[i].id] = true;
        let id = 1;
        while (used[id]) id++;
        return id;
    }

    // First run: keep the desktops each monitor already has, then top every monitor up
    function initDesktops() {
        const map = copyMap();
        const list = Hyprland.workspaces.values;
        const fresh = [];
        for (let s = 0; s < Quickshell.screens.length; s++) {
            const name = Quickshell.screens[s].name;
            if (map[name]) continue;
            const ids = [];
            for (let i = 0; i < list.length; i++) {
                const ws = list[i];
                if (ws.id > 0 && ws.monitor && ws.monitor.name === name) ids.push(ws.id);
            }
            ids.sort((a, b) => a - b);
            map[name] = ids;
            fresh.push(name);
        }
        for (let f = 0; f < fresh.length; f++)
            while (map[fresh[f]].length < defaultDesktops) map[fresh[f]].push(freeId(map));
        // linked desktops: every monitor gets the same number
        let count = 0;
        for (let s = 0; s < Quickshell.screens.length; s++)
            count = Math.max(count, (map[Quickshell.screens[s].name] || []).length);
        let changed = fresh.length > 0;
        for (let s = 0; s < Quickshell.screens.length; s++) {
            const name = Quickshell.screens[s].name;
            if (!map[name]) map[name] = [];
            while (map[name].length < count) {
                map[name].push(freeId(map));
                changed = true;
            }
        }
        if (changed) saveDesk(map);
    }

    // A monitor plugged in later gets linked too
    Connections {
        target: Quickshell
        function onScreensChanged() {
            if (Hyprland.workspaces.values.length > 0) root.initDesktops();
        }
    }

    // Wait until Hyprland has told us about its workspaces, then set up once
    Timer {
        interval: 1500
        repeat: true
        running: true
        onTriggered: {
            if (Hyprland.workspaces.values.length > 0 && Quickshell.screens.length > 0) {
                root.initDesktops();
                running = false;
            }
        }
    }

    function focusedMonitorName() {
        return Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "";
    }

    // How many desktops there are (the same on every monitor)
    readonly property int deskCount: {
        let n = 0;
        for (const k in deskMap) n = Math.max(n, deskMap[k].length);
        return n;
    }

    // Which desktop (0 = first) the focused monitor is showing
    function currentDeskIndex() {
        const name = focusedMonitorName();
        return (deskMap[name] || []).indexOf(activeWsId(name));
    }

    // Monitor names with the focused one last, so focus ends up where you already are
    function screensFocusedLast() {
        const here = focusedMonitorName(), out = [];
        for (let i = 0; i < Quickshell.screens.length; i++)
            if (Quickshell.screens[i].name !== here) out.push(Quickshell.screens[i].name);
        if (here !== "") out.push(here);
        return out;
    }

    // Switch EVERY monitor to desktop number n (0 = first)
    function gotoDeskIndex(n) {
        if (n < 0 || n >= deskCount) return;
        const here = focusedMonitorName();
        const names = screensFocusedLast();
        const cmds = [];
        for (let i = 0; i < names.length; i++) {
            const ids = deskMap[names[i]] || [];
            if (n >= ids.length) continue;
            if (names[i] !== here && activeWsId(names[i]) === ids[n]) continue;   // already there
            cmds.push('hl.dsp.focus({ monitor = "' + names[i] + '" })');
            cmds.push('hl.dsp.focus({ workspace = ' + ids[n] + ', on_current_monitor = true })');
        }
        if (cmds.length > 0) hyprList(cmds);
    }

    // Clicking a desktop on any monitor switches all monitors to that desktop number
    function gotoDesktop(monitorName, id) {
        gotoDeskIndex((deskMap[monitorName] || []).indexOf(id));
    }

    // A new desktop is added on every monitor at once
    function addDesktop(monitorName) {
        if (deskCount >= maxDesktops) return;
        const newIndex = deskCount;     // the new desktop goes on the end
        const map = copyMap();
        for (let i = 0; i < Quickshell.screens.length; i++) {
            const name = Quickshell.screens[i].name;
            if (!map[name]) map[name] = [];
            map[name].push(freeId(map));
        }
        saveDesk(map);
        gotoDeskIndex(newIndex);
    }

    // Deleting desktop N removes it on every monitor; its windows move to the neighbouring desktop
    function removeDesktop(monitorName, id) {
        const n = (deskMap[monitorName] || []).indexOf(id);
        removeDeskIndex(n);
    }

    function removeDeskIndex(n) {
        if (deskCount <= 1 || n < 0 || n >= deskCount) return;
        const map = copyMap();
        const cmds = [];
        const names = screensFocusedLast();
        for (let s = 0; s < names.length; s++) {
            const name = names[s];
            const ids = map[name] || [];
            if (n >= ids.length) continue;
            const gone = ids[n];
            const target = ids[n > 0 ? n - 1 : 1];
            const ws = workspaceById(gone);
            if (ws) {
                const tops = ws.toplevels.values;
                for (let i = 0; i < tops.length; i++) {
                    let a = String(tops[i].address);
                    if (a.indexOf("0x") !== 0) a = "0x" + a;
                    cmds.push('hl.dsp.window.move({ workspace = ' + target + ', follow = false, window = "address:' + a + '" })');
                }
            }
            if (activeWsId(name) === gone) {
                cmds.push('hl.dsp.focus({ monitor = "' + name + '" })');
                cmds.push('hl.dsp.focus({ workspace = ' + target + ', on_current_monitor = true })');
            }
            ids.splice(n, 1);
            map[name] = ids;
        }
        saveDesk(map);
        if (cmds.length > 0) hyprList(cmds);
    }

    function switchToNth(n) {
        gotoDeskIndex(n - 1);
    }

    function cycleDesktop(delta) {
        if (deskCount === 0) return;
        const at = Math.max(currentDeskIndex(), 0);
        gotoDeskIndex((at + delta + deskCount) % deskCount);
    }

    // Move the focused window to desktop n (0 = first) on the monitor it's on
    function moveWindowToDesk(n, follow) {
        const ids = deskMap[focusedMonitorName()] || [];
        if (n < 0 || n >= ids.length) return;
        hyprList(['hl.dsp.window.move({ workspace = ' + ids[n] + ', follow = false })']);
        if (follow) gotoDeskIndex(n);
    }

    // Media keys:  qs ipc call media toggle | next | previous
    IpcHandler {
        target: "media"
        function toggle(): void {
            if (root.player && root.player.canTogglePlaying) root.player.togglePlaying();
        }
        function next(): void {
            if (root.player && root.player.canGoNext) root.player.next();
        }
        function previous(): void {
            if (root.player && root.player.canGoPrevious) root.player.previous();
        }
    }

    // Apps open on desktop n, across every monitor (for the switcher)
    function deskApps(n) {
        const out = [];
        for (const name in deskMap) {
            const ids = deskMap[name];
            if (n >= ids.length) continue;
            const ws = workspaceById(ids[n]);
            if (!ws) continue;
            const tops = ws.toplevels.values;
            for (let i = 0; i < tops.length; i++) {
                const t = tops[i];
                const appId = t.wayland ? t.wayland.appId : (t.lastIpcObject && t.lastIpcObject.class ? t.lastIpcObject.class : "");
                out.push({ appId: appId, title: t.title || appId });
            }
        }
        return out;
    }

    // ---------- Desktop switcher (Super+Tab) ----------
    // Hold Super, tap Tab to move along, let go of Super to switch. Arrows / numbers / click work too.
    property bool switcherOpen: false
    property int switcherSel: 0

    function switcherStep(delta) {
        if (deskCount === 0) return;
        if (!switcherOpen) {
            switcherSel = (Math.max(currentDeskIndex(), 0) + delta + deskCount) % deskCount;
            switcherOpen = true;
        } else {
            switcherSel = (switcherSel + delta + deskCount) % deskCount;
        }
    }

    function switcherCommit() {
        if (!switcherOpen) return;
        switcherOpen = false;
        gotoDeskIndex(switcherSel);
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "desktopswitch"
        description: "Desktop switcher: next desktop"
        onPressed: root.switcherStep(1)
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "desktopswitchback"
        description: "Desktop switcher: previous desktop"
        onPressed: root.switcherStep(-1)
    }

    // From a terminal:  quickshell ipc call desktops switchTo 2   (also next, prev, add, remove, reset)
    IpcHandler {
        target: "desktops"
        function switchTo(n: int): void { root.switchToNth(n); }
        function next(): void { root.cycleDesktop(1); }
        function switcher(): void { root.switcherStep(1); }
        function switcherBack(): void { root.switcherStep(-1); }
        // Move the focused window to desktop n: "moveWindowTo" follows it, "sendWindowTo" stays put
        function moveWindowTo(n: int): void { root.moveWindowToDesk(n - 1, true); }
        function sendWindowTo(n: int): void { root.moveWindowToDesk(n - 1, false); }
        function moveWindowBy(delta: int): void {
            if (root.deskCount === 0) return;
            const at = Math.max(root.currentDeskIndex(), 0);
            root.moveWindowToDesk((at + delta + root.deskCount) % root.deskCount, true);
        }
        function prev(): void { root.cycleDesktop(-1); }
        function add(): void {
            const name = root.focusedMonitorName();
            if (name !== "") root.addDesktop(name);
        }
        function remove(): void {
            const name = root.focusedMonitorName();
            if (name !== "") root.removeDeskIndex(root.currentDeskIndex());
        }
        function reset(): void {
            pins.adapter.desktopsJson = "";
            root.initDesktops();
        }
    }

    // ---------- Desktop switch pop-up ----------
    property bool osdShow: false
    property bool osdReady: false

    Timer {
        interval: 4000
        running: true
        onTriggered: root.osdReady = true
    }

    Timer {
        id: osdHide
        interval: 1300
        onTriggered: root.osdShow = false
    }

    Connections {
        target: Hyprland
        function onFocusedWorkspaceChanged() {
            if (!root.osdReady || !root.showDesktopOsd) return;
            root.osdShow = true;
            osdHide.restart();
        }
    }
    // ---------- Terminal colors (kitty follows the wallpaper) ----------
    // Builds a kitty color file from the wallpaper palette. Uses the base values, not the
    // animated ones, so the result is final even while the bars are still fading.
    function kittyThemeText() {
        const d = dark;
        const h = hue;
        const s = sat;
        const col = (hh, sa, li) => Qt.hsla(((hh % 1) + 1) % 1, sa, li, 1).toString();
        const accentHex = accentBase.toString();
        const bgc = d ? col(h, s * 0.35, 0.09) : col(h, s * 0.30, 0.97);
        // text: clearly tinted with the wallpaper colour, still easy to read
        const fgc = d ? col(h, s * 0.45, 0.88) : col(h, s * 0.55, 0.18);
        const lo = d ? 0.62 : 0.38;                // normal ANSI colors
        const hi = d ? 0.74 : 0.30;                // bright ANSI colors
        const hues = [0.0, 0.33, 0.12, 0.60, 0.80, 0.50];   // red green yellow blue magenta cyan
        const lines = [
            "# Generated by Quickshell from the wallpaper. Do not edit by hand.",
            "foreground " + fgc,
            "background " + bgc,
            "selection_foreground " + bgc,
            "selection_background " + accentHex,
            "cursor " + accentHex,
            "cursor_text_color " + bgc,
            "url_color " + accentHex,
            "active_border_color " + accentHex,
            "inactive_border_color " + col(h, s * 0.2, 0.3),
            "active_tab_foreground " + bgc,
            "active_tab_background " + accentHex,
            "inactive_tab_foreground " + fgc,
            "inactive_tab_background " + col(h, s * 0.3, d ? 0.16 : 0.88),
            "color0 " + col(h, s * 0.25, d ? 0.16 : 0.85),
            "color7 " + col(h, s * 0.35, d ? 0.80 : 0.30),
            "color8 " + col(h, s * 0.40, d ? 0.48 : 0.62),
            "color15 " + col(h, s * 0.30, d ? 0.95 : 0.12)
        ];
        // Every colour leans 25% of the way toward the wallpaper's hue, so red stays reddish,
        // green stays greenish, but they all look like they belong to the wallpaper.
        // Blue (color4) is the wallpaper accent itself; fastfetch uses it for its labels.
        const lean = glassTheme ? 0 : 0.25;
        const tint = base => base + ((((h - base) % 1) + 1.5) % 1 - 0.5) * lean;
        const sLo = Math.max(0.35, Math.min(0.75, s * 0.9));
        const sHi = Math.max(0.45, Math.min(0.85, s));
        for (let i = 0; i < 6; i++) {
            const hh = i === 3 ? (glassTheme ? 0.60 : h) : tint(hues[i]);
            // glass theme: "blue" (the accent) is a soft silver-blue to match the glass
            const sl = glassTheme && i === 3 ? 0.22 : sLo, sh = glassTheme && i === 3 ? 0.28 : sHi;
            const ll = glassTheme && i === 3 ? 0.78 : lo, lh = glassTheme && i === 3 ? 0.86 : hi;
            lines.push("color" + (i + 1) + " " + col(hh, sl, ll));
            lines.push("color" + (i + 9) + " " + col(hh, sh, lh));
        }
        return lines.join("\n");
    }

    // Writes ~/.config/kitty/colors-wallpaper.conf and tells every open kitty to reload
    function writeKittyTheme() {
        const path = Quickshell.env("HOME") + "/.config/kitty/colors-wallpaper.conf";
        Quickshell.execDetached(["sh", "-c",
            'mkdir -p "$(dirname "$2")" && printf "%s\\n" "$1" > "$2" && (pkill -USR1 kitty || true)',
            "sh", kittyThemeText(), path]);
    }

    Timer {
        id: kittyTimer
        interval: 900
        onTriggered: root.writeKittyTheme()
    }
    onSeedChanged: kittyTimer.restart()
    onThemeSeedChanged: kittyTimer.restart()
    onThemeTintChanged: kittyTimer.restart()
    onDarkChanged: kittyTimer.restart()
    onGlassThemeChanged: kittyTimer.restart()

    // once at startup, after the wallpaper colors have been picked
    Timer {
        interval: 3000
        running: true
        onTriggered: root.writeKittyTheme()
    }

    // ---------- Small reusable widgets ----------
    // (inline components can't see ids above, so their colors are set here)
    component ValueBar: Item {
        id: bar
        property var theme: null
        property real value: 0
        signal moved(real v)
        implicitHeight: 18

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 6
            radius: 3
            color: bar.theme ? bar.theme.overlay : "#45475a"

            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, bar.value))
                height: parent.height
                radius: 3
                color: bar.theme ? bar.theme.accent : "#89b4fa"
            }
        }

        MouseArea {
            anchors.fill: parent
            onPressed: mouse => bar.moved(Math.max(0, Math.min(1, mouse.x / width)))
            onPositionChanged: mouse => {
                if (pressed) bar.moved(Math.max(0, Math.min(1, mouse.x / width)));
            }
        }
    }

    component IconButton: Rectangle {
        id: btn
        property var theme: null
        property string label: ""
        property bool dim: false
        signal clicked()
        implicitWidth: 44
        implicitHeight: 34
        radius: 8
        color: area.containsMouse ? (btn.theme ? btn.theme.overlay : "#99585b70") : (btn.theme ? btn.theme.surface : "#66313244")
        Behavior on color { ColorAnimation { duration: 120 } }
        opacity: dim ? 0.4 : 1

        Text {
            anchors.centerIn: parent
            text: btn.label
            color: btn.theme ? btn.theme.fg : "#cdd6f4"
            font.pixelSize: 14
        }

        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            onClicked: btn.clicked()
        }
    }

    // Top bar button: icon + label on a pill that pops when hovered, like the dock icons
    component BarButton: Rectangle {
        id: bb
        property var theme: null
        property string icon: ""
        property string label: ""
        property bool active: false
        property bool interactive: true
        property int maxLabelWidth: 0        // 0 = no limit
        signal clicked(var mouse)
        signal wheeled(var wheel)
        implicitWidth: bbRow.implicitWidth + 28
        implicitHeight: 36
        radius: 12
        color: bb.theme ? ((bb.active || bbMouse.containsMouse) ? bb.theme.overlay : bb.theme.surface) : "#313244"
        border.width: 1
        border.color: bb.theme ? bb.theme.glassEdge : "transparent"
        scale: bbMouse.pressed ? 0.94 : (bbMouse.containsMouse ? 1.07 : 1)
        Behavior on scale { NumberAnimation { duration: bb.theme ? bb.theme.animMs : 150; easing.type: Easing.OutBack } }
        Behavior on color { ColorAnimation { duration: 120 } }

        Row {
            id: bbRow
            anchors.centerIn: parent
            spacing: 8

            Text {
                visible: bb.icon !== ""
                anchors.verticalCenter: parent.verticalCenter
                text: bb.icon
                color: bb.theme ? bb.theme.accent : "#89b4fa"
                font.family: bb.theme ? bb.theme.iconFont : ""
                font.pixelSize: 15
            }
            Text {
                visible: bb.label !== ""
                anchors.verticalCenter: parent.verticalCenter
                width: bb.maxLabelWidth > 0 ? Math.min(implicitWidth, bb.maxLabelWidth) : implicitWidth
                elide: Text.ElideRight
                text: bb.label
                color: bb.theme ? bb.theme.fg : "#cdd6f4"
                font.pixelSize: 13
            }
        }

        MouseArea {
            id: bbMouse
            anchors.fill: parent
            enabled: bb.interactive
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton
            onClicked: mouse => bb.clicked(mouse)
            onWheel: wheel => bb.wheeled(wheel)
        }
    }

    component ConfirmButton: Rectangle {
        id: cb
        property var theme: null
        property string label: ""
        property bool armed: false
        signal confirmed()
        implicitWidth: 80
        implicitHeight: 34
        radius: 8
        color: armed ? (cb.theme ? cb.theme.danger : "#f38ba8") : (area.containsMouse ? (cb.theme ? cb.theme.overlay : "#45475a") : (cb.theme ? cb.theme.surface : "#313244"))
        Behavior on color { ColorAnimation { duration: 120 } }

        Timer {
            id: reset
            interval: 3000
            onTriggered: cb.armed = false
        }

        Text {
            anchors.centerIn: parent
            text: cb.armed ? "Confirm?" : cb.label
            color: cb.armed ? (cb.theme ? cb.theme.bg : "#1e1e2e") : (cb.theme ? cb.theme.fg : "#cdd6f4")
            font.pixelSize: 13
        }

        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                if (cb.armed) {
                    cb.armed = false;
                    reset.stop();
                    cb.confirmed();
                } else {
                    cb.armed = true;
                    reset.restart();
                }
            }
        }
    }

    // ---------- One bar per screen ----------
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: panel
            required property var modelData
            screen: modelData

            anchors {
                bottom: true
                left: true
                right: true
            }
            implicitHeight: 34
            color: "transparent"
            WlrLayershell.namespace: "quickshell-bar"

            // ----- Auto-hide -----
            // Touch the screen edge and the bar slides out; windows shrink to make room for it.
            // Move away and it slides back after a moment; windows stretch back to full size.
            readonly property bool wantHide: root.autoHideOn
            readonly property bool popupOpen: ctxMenu.visible || mediaPopup.visible || root.wallPickerOpen
            readonly property bool keepOpen: !wantHide || barHover.hovered || popupOpen
            property bool barShown: true

            onKeepOpenChanged: {
                if (keepOpen) {
                    hideTimer.stop();
                    barShown = true;
                } else {
                    hideTimer.restart();
                }
            }
            Component.onCompleted: if (!keepOpen) hideTimer.start()

            Timer {
                id: hideTimer
                interval: root.hideDelayMs
                onTriggered: panel.barShown = panel.keepOpen
            }

            // Windows only make room while the bar is out
            // just a small tab now, so windows keep the whole screen
            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: 0

            // While hidden, only a thin strip at the screen edge listens for the mouse;
            // everything else passes straight through to the windows underneath
            mask: Region { item: bottomHot }

            // The tab stays out of sight until the mouse touches the bottom edge of the screen
            // (anywhere along it). It stays while you're near it, then tucks away.
            property bool tabPeek: false
            Item {
                id: bottomHot
                anchors.bottom: parent.bottom
                // the whole bottom edge listens; once the tab is out, only the area around it does
                width: panel.tabPeek ? bottomTab.width + 200 : parent.width
                x: (parent.width - width) / 2
                height: panel.tabPeek ? parent.height : root.hotZoneSize
            }
            Connections {
                target: barHover
                function onHoveredChanged() {
                    if (barHover.hovered) {
                        tabHideTimer.stop();
                        panel.tabPeek = true;
                    } else {
                        tabHideTimer.restart();
                    }
                }
            }
            Timer {
                id: tabHideTimer
                interval: 1500      // time to reach the tab after it pops up
                onTriggered: panel.tabPeek = false
            }
            Region { id: edgeMask; item: hotStrip }

            Item {
                id: hotStrip
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: root.hotZoneSize
            }

            // Is the mouse anywhere over this bar (or the edge strip)? Sits on top of everything,
            // but only watches: hovers and clicks still reach the buttons underneath.
            Item {
                anchors.fill: parent
                z: 1000
                HoverHandler { id: barHover }
            }

            // Closes this bar's popups when asked (outside click, workspace change)
            Connections {
                target: root
                function onCloseAllRequested() {
                    ctxMenu.visible = false;
                    mediaPopup.visible = false;
                }
            }

            property double mediaClosedAt: 0

            // Opens the shared right-click menu above an item
            function openMenu(target, entries) {
                ctxMenu.entries = entries;
                const p = target.mapToItem(null, 0, 0);
                ctxMenu.anchor.rect = Qt.rect(p.x, p.y, target.width, target.height);
                ctxMenu.visible = true;
            }

            // ===== Right-click menu =====
            PopupWindow {
                id: ctxMenu
                property var entries: []
                anchor.window: panel
                anchor.edges: Edges.Top
                anchor.gravity: Edges.Top
                implicitWidth: 200
                implicitHeight: menuCol.implicitHeight + 12
                color: "transparent"
                visible: false

                Rectangle {
                    opacity: 0
                    scale: 0.96
                    NumberAnimation on opacity { running: ctxMenu.visible; from: 0; to: 1; duration: root.animMs; easing.type: Easing.OutCubic }
                    NumberAnimation on scale { running: ctxMenu.visible; from: 0.96; to: 1; duration: root.animMs; easing.type: Easing.OutCubic }
                    anchors.fill: parent
                    radius: 10
                    color: root.popupBg
                    border.color: root.overlay
                    border.width: 1

                    GlassShine { radius: parent.radius; dark: root.dark }

                    Column {
                        id: menuCol
                        anchors.fill: parent
                        anchors.margins: 6
                        spacing: 2

                        Repeater {
                            model: ctxMenu.entries

                            delegate: Rectangle {
                                id: menuRow
                                required property var modelData
                                width: menuCol.width
                                height: 30
                                radius: 6
                                color: rowMouse.containsMouse ? root.overlay : "transparent"

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.left
                                    anchors.leftMargin: 10
                                    text: menuRow.modelData.text
                                    color: menuRow.modelData.danger ? root.danger : root.fg
                                    font.pixelSize: 13
                                }

                                MouseArea {
                                    id: rowMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        ctxMenu.visible = false;
                                        menuRow.modelData.action();
                                    }
                                }
                            }
                        }
                    }
                }
            }

            HyprlandFocusGrab {
                windows: [ctxMenu]
                active: ctxMenu.visible
                onCleared: {
                    root.closeAll();
                    ctxMenu.visible = false;
                }
            }

            // ===== Media popup =====
            PopupWindow {
                id: mediaPopup
                readonly property var p: root.player
                anchor.window: panel
                anchor.edges: Edges.Top
                anchor.gravity: Edges.Top
                implicitWidth: dockNowPlaying.implicitWidth + 44
                implicitHeight: dockNowPlaying.implicitHeight + 52
                color: "transparent"
                visible: false

                // if the card ever changes size while open, re-attach "click away to close"
                property bool rearming: false
                onImplicitHeightChanged: if (visible) { rearming = true; rearmTimer.restart(); }
                onImplicitWidthChanged: if (visible) { rearming = true; rearmTimer.restart(); }
                Timer {
                    id: rearmTimer
                    interval: 80
                    onTriggered: mediaPopup.rearming = false
                }

                // Position only updates when asked, so poll while it's open
                Timer {
                    interval: 1000
                    repeat: true
                    running: mediaPopup.visible && root.playing(mediaPopup.p)
                    onTriggered: mediaPopup.p.positionChanged()
                }

                Connections {
                    target: root
                    function onPlayerChanged() {
                        if (!root.player) mediaPopup.visible = false;
                    }
                }

                Rectangle {
                    id: mediaCard
                    opacity: 0
                    scale: 0.96
                    NumberAnimation on opacity { running: mediaPopup.visible; from: 0; to: 1; duration: root.animMs * 1.5; easing.type: Easing.OutCubic }
                    NumberAnimation on scale { running: mediaPopup.visible; from: 0.96; to: 1; duration: root.animMs * 2; easing.type: Easing.OutBack }
                    anchors.fill: parent
                    anchors.bottomMargin: 8
                    radius: 28
                    color: root.popupBg
                    border.color: root.glassEdge
                    border.width: 1
                    clip: true

                    GlassShine { radius: parent.radius; dark: root.dark }

                    NowPlaying {
                        id: dockNowPlaying
                        theme: root
                        player: mediaPopup.p
                        artSize: 300
                        wide: false
                        backdropMargin: 22
                        x: 22
                        y: 22
                    }
                }
            }

            HyprlandFocusGrab {
                windows: [mediaPopup]
                active: mediaPopup.visible && !mediaPopup.rearming
                onCleared: {
                    root.closeAll();
                    mediaPopup.visible = false;
                    panel.mediaClosedAt = Date.now();
                }
            }

            // ===== The bar itself: one small plain tab at the bottom =====
            // Click it and it grows into the launcher: search at the top, your pinned apps at the bottom.
            Rectangle {
                id: bottomTab
                anchors.horizontalCenter: parent.horizontalCenter
                y: panel.tabPeek && !root.launcherOpen ? parent.height - height + 10 : parent.height + 4
                height: bottomTabMouse.containsMouse ? 26 : 22
                width: Math.max(160, panel.width * 0.12) + (bottomTabMouse.containsMouse ? 24 : 0)
                radius: 11
                color: root.popupBg
                border.width: 1
                border.color: root.glassEdge
                Behavior on y { NumberAnimation { duration: root.animMs * 2; easing.type: Easing.OutCubic } }
                Behavior on width { NumberAnimation { duration: root.animMs * 1.5; easing.type: Easing.OutCubic } }
                Behavior on height { NumberAnimation { duration: root.animMs; easing.type: Easing.OutCubic } }
                onWidthChanged: root.dockPillW = width

                GlassShine { radius: parent.radius; dark: root.dark }

                MouseArea {
                    id: bottomTabMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        panel.tabPeek = false;
                        root.launcherOpen = !root.launcherOpen;
                    }
                }
            }
        }
    }

    // ---------- Login screen wallpaper ----------
    // Keeps a copy of the current wallpaper where the login screen (Plasma Login / SDDM) can read it.
    // Only does anything after the one-time setup (login-wallpaper-setup) made that folder yours.
    readonly property string loginWallSrc: pins.adapter.wallpaper
    onLoginWallSrcChanged: loginWallTimer.restart()
    Timer {
        id: loginWallTimer
        interval: 1500          // wait a moment so quick clicks through wallpapers only copy the last one
        onTriggered: {
            if (!root.loginWallSrc) return;
            const path = decodeURIComponent(String(root.loginWallSrc).replace(/^file:\/\//, ""));
            // writes into whichever login picture the setup made (Plasma Login or SDDM),
            // keeping that file's owner and permissions
            Quickshell.execDetached(["sh", "-c",
                'set -- "$1" /var/lib/plasmalogin/wallpapers/joeos-login.jpg /usr/local/share/joeos/login-wallpaper.jpg; '
                + 'src="$1"; shift; ok=""; for t in "$@"; do [ -w "$t" ] && ok=1; done; [ -n "$ok" ] || exit 0; '
                + 'tmp="${XDG_RUNTIME_DIR:-/tmp}/joeos-login.jpg"; '
                + 'ffmpeg -v error -y -i "$src" -frames:v 1 -q:v 2 "$tmp" || exit 0; '
                + 'for t in "$@"; do [ -w "$t" ] && cat "$tmp" > "$t"; done',
                "sh", path]);
        }
    }

    // ---------- Remember open apps across restarts ----------
    // Every minute: note which apps are open and which desktop + monitor each window is on
    // (~/.local/state/joeos/session.json). After logging in: open them again and put every
    // window back on its desktop as it appears. Only apps with a launcher entry are reopened
    // (so games started from a launcher aren't). Turn it off with the "Reopen apps" tile.
    property bool sessionRestoring: false
    property bool sessionReady: false        // no saving until the restore is finished
    property var sessionPending: []          // windows still waiting to be placed
    property int sessionLastCount: -1
    property int sessionDropSeen: -1         // a smaller window count must be seen twice in a row
    readonly property string sessionFile: Quickshell.env("HOME") + "/.local/state/joeos/session.json"
    readonly property var sessionSkip: ["quickshell", "joeos-update", "xdg-desktop-portal-gtk", "xdg-desktop-portal-hyprland", "hyprland-share-picker"]
    readonly property var sessionMultiLaunch: ["kitty", "foot", "alacritty", "wezterm", "org.wezfurlong.wezterm", "konsole", "ghostty", "com.mitchellh.ghostty"]

    function sessionMonitorName(id) {
        const list = Hyprland.monitors.values;
        for (let i = 0; i < list.length; i++) if (list[i].id === id) return list[i].name;
        return "";
    }

    Process {
        id: sessionSnap
        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                let list = [];
                try { list = JSON.parse(text); } catch (e) { return; }
                const out = [];
                for (const c of list) {
                    const cls = c["class"] || c.initialClass || "";
                    if (!cls || !c.mapped || c.hidden) continue;
                    if (!c.workspace || c.workspace.id <= 0) continue;          // skip special/scratch workspaces
                    if (root.sessionSkip.indexOf(cls.toLowerCase()) >= 0) continue;
                    const e = DesktopEntries.heuristicLookup(cls) || DesktopEntries.heuristicLookup(c.initialClass || "");
                    if (!e) continue;                                            // nothing to reopen it with
                    out.push({ cls: cls, entry: e.id, ws: c.workspace.id, mon: root.sessionMonitorName(c.monitor), title: c.title || "" });
                }
                // closing apps during shutdown shouldn't wipe the list: a drop must show up twice in a row
                if (out.length < root.sessionLastCount && root.sessionDropSeen !== out.length) {
                    root.sessionDropSeen = out.length;
                    return;
                }
                root.sessionDropSeen = -1;
                root.sessionLastCount = out.length;
                Quickshell.execDetached(["sh", "-c", 'mkdir -p "$(dirname "$1")" && printf "%s" "$2" > "$1.tmp" && mv -f "$1.tmp" "$1"',
                    "sh", root.sessionFile, JSON.stringify({ saved: Date.now(), windows: out })]);
            }
        }
    }
    Timer {
        interval: 60000
        repeat: true
        running: root.sessionReady && pins.adapter.restoreSession
        onTriggered: sessionSnap.running = true
    }

    // first start of the bar since logging in? (a marker in the runtime folder, wiped at logout/reboot)
    Process {
        id: sessionCheck
        running: true
        command: ["sh", "-c", 'm="${XDG_RUNTIME_DIR:-/tmp}/joeos-session-${HYPRLAND_INSTANCE_SIGNATURE:-x}"; '
            + 'if [ -e "$m" ]; then echo SKIP; else touch "$m"; cat "$1" 2>/dev/null; fi', "sh", Quickshell.env("HOME") + "/.local/state/joeos/session.json"]
        stdout: StdioCollector {
            onStreamFinished: {
                const t = text.trim();
                let data = null;
                if (t !== "SKIP") { try { data = JSON.parse(t); } catch (e) {} }
                if (!data || !data.windows || data.windows.length === 0 || !pins.adapter.restoreSession) {
                    root.sessionReady = true;
                    return;
                }
                sessionStart.data = data;
                sessionStart.start();      // give the monitors and desktops a moment to settle
            }
        }
    }
    Timer {
        id: sessionStart
        property var data: null
        interval: 3000
        onTriggered: root.sessionRestore(data.windows)
    }

    function sessionRestore(wins) {
        sessionPending = wins.slice();
        sessionRestoring = true;
        // open each app once (terminals once per window); browsers reopen their own windows
        const launched = {};
        for (const w of wins) {
            const multi = sessionMultiLaunch.indexOf(w.cls.toLowerCase()) >= 0;
            if (launched[w.entry] && !multi) continue;
            launched[w.entry] = true;
            const e = DesktopEntries.heuristicLookup(w.entry) || DesktopEntries.heuristicLookup(w.cls);
            if (e) e.execute();
        }
        root.toastSeq += 1;
        toastModel.append({ tid: root.toastSeq, nid: -1, appName: "JoeOS", critical: false,
            summary: "Welcome back", body: "Reopening " + wins.length + " window" + (wins.length === 1 ? "" : "s") + " from last time." });
        sessionGiveUp.restart();
    }

    function sessionFinish() {
        if (!sessionRestoring) return;
        sessionRestoring = false;
        sessionPending = [];
        sessionReady = true;
        sessionGiveUp.stop();
        gotoDeskIndex(0);           // start on desktop 1
    }
    Timer {
        id: sessionGiveUp
        interval: 90000             // slow apps get 90 seconds to appear
        onTriggered: root.sessionFinish()
    }

    // a window appeared: if it's one we're waiting for, send it to its desktop
    Connections {
        target: Hyprland
        enabled: root.sessionRestoring
        function onRawEvent(event) {
            if (event.name !== "openwindow") return;
            const parts = event.data.split(",");
            if (parts.length < 3) return;
            const addr = parts[0].indexOf("0x") === 0 ? parts[0] : "0x" + parts[0];
            const cls = parts[2].toLowerCase();
            const pend = root.sessionPending.slice();
            for (let i = 0; i < pend.length; i++) {
                if (pend[i].cls.toLowerCase() !== cls) continue;
                const w = pend.splice(i, 1)[0];
                root.sessionPending = pend;
                const cmds = ['hl.dsp.window.move({ workspace = ' + w.ws + ', follow = false, window = "address:' + addr + '" })'];
                if (w.mon) cmds.push('hl.dsp.workspace.move({ workspace = ' + w.ws + ', monitor = "' + w.mon + '" })');
                root.hyprList(cmds);
                if (pend.length === 0) sessionDone.restart();
                return;
            }
        }
    }
    Timer {
        id: sessionDone
        interval: 1500
        onTriggered: root.sessionFinish()
    }

    // ---------- Log out / Reboot / Shut down ----------
    // Saves the open apps first (for "Reopen apps"), then tries each way in turn. If something
    // blocks it, a notification says why (also logged to ~/.cache/joeos/power.log).
    function powerAction(action) {
        hubOpen = false;
        panelOpen = false;
        if (sessionReady && pins.adapter.restoreSession) sessionSnap.running = true;
        powerTimer.action = action;
        powerTimer.restart();
    }
    Timer {
        id: powerTimer
        property string action: ""
        interval: 700           // a moment for the save to finish
        onTriggered: Quickshell.execDetached(["sh", "-c",
            'a="$1"; log="$HOME/.cache/joeos/power.log"; mkdir -p "${log%/*}"; '
            + 'fail() { echo "$(date) $a: $1" >> "$log"; notify-send -a JoeOS "Could not $a" "$1" 2>/dev/null; }; '
            + 'case "$a" in '
            + '  logout) '
            + '    if command -v hyprshutdown >/dev/null 2>&1; then hyprshutdown && exit 0; fi; '
            + '    if command -v uwsm >/dev/null 2>&1 && uwsm check is-active >/dev/null 2>&1; then uwsm stop && exit 0; fi; '
            + '    out=$(hyprctl dispatch "hl.dsp.exit()" 2>&1); [ "$(printf "%s\\n" "$out" | tail -n 1)" = ok ] && exit 0; '
            + '    [ -n "$XDG_SESSION_ID" ] && loginctl terminate-session "$XDG_SESSION_ID" 2>/dev/null && exit 0; '
            + '    fail "$out" ;; '
            + '  reboot|poweroff) '
            + '    out=$(systemctl "$a" 2>&1) && exit 0; '
            + '    out2=$(systemctl "$a" --check-inhibitors=no 2>&1) && exit 0; '
            + '    fail "${out2:-$out}" ;; '
            + 'esac', "sh", action])
    }

    // ---------- Game mode ----------
    // Turns off blur, shadows, see-through windows and animations (in Hyprland and in the bars)
    // and pauses a live wallpaper, for more FPS. Turning it off reloads your normal Hyprland config.
    //   qs ipc call gamemode toggle | enable | disable
    readonly property bool gameMode: pins.adapter.gameMode
    function setGameMode(on) {
        if (on === gameMode) return;
        pins.adapter.gameMode = on;
        root.toastSeq += 1;
        toastModel.append({
            tid: root.toastSeq, nid: -1, appName: "JoeOS", critical: false,
            summary: on ? "Game mode on" : "Game mode off",
            body: on ? "Blur, see-through windows and animations are off for more FPS." : "Your glass look is back."
        });
    }
    onGameModeChanged: {
        displayRestore.restart();          // screen colours: off for games, back afterwards
        if (gameMode)
            Quickshell.execDetached(["hyprctl", "eval",
                "hl.config({ animations = { enabled = false }, decoration = { active_opacity = 1.0, inactive_opacity = 1.0, "
                + "dim_inactive = false, blur = { enabled = false }, shadow = { enabled = false } } })"]);
        else
            Quickshell.execDetached(["hyprctl", "reload"]);
    }
    IpcHandler {
        target: "gamemode"
        function toggle(): void { root.setGameMode(!root.gameMode); }
        function enable(): void { root.setGameMode(true); }
        function disable(): void { root.setGameMode(false); }
    }

    // ---------- Update checker ----------
    // Counts waiting updates every 30 minutes: system (pacman), AUR (paru/yay) and Flatpak.
    // Clicking the dock badge opens a terminal that installs them. Right-click checks again.
    property int updSystem: 0
    property int updAur: 0
    property int updFlatpak: 0
    property var updNames: []
    property bool updCanCheck: true        // false when checkupdates (pacman-contrib) is missing
    property bool updRunning: false
    property bool updChecking: false
    readonly property int updTotal: updSystem + updAur + updFlatpak
    readonly property string updSummary: {
        const parts = [];
        if (updSystem) parts.push(updSystem + " system");
        if (updAur) parts.push(updAur + " AUR");
        if (updFlatpak) parts.push(updFlatpak + " Flatpak");
        return parts.join(" · ");
    }

    function checkUpdates() {
        if (updRunning || updCheck.running) return;
        updChecking = true;
        updCheck.running = true;
    }
    function runUpdates() {
        if (updRunning) return;
        updRunning = true;
        updRun.running = true;
    }

    Process {
        id: updCheck
        command: ["sh", "-c",
            "echo '== system'; if command -v checkupdates >/dev/null 2>&1; then checkupdates 2>/dev/null; else echo '!nocheck'; fi; "
            + "echo '== aur'; if command -v paru >/dev/null 2>&1; then paru -Qua 2>/dev/null; elif command -v yay >/dev/null 2>&1; then yay -Qua 2>/dev/null; fi; "
            + "echo '== flatpak'; if command -v flatpak >/dev/null 2>&1; then flatpak remote-ls --updates --columns=application 2>/dev/null; fi; true"]
        stdout: StdioCollector {
            onStreamFinished: {
                let sec = "", sys = 0, aur = 0, fp = 0, can = true;
                const names = [];
                for (const raw of text.split("\n")) {
                    const line = raw.trim();
                    if (line === "") continue;
                    if (line.indexOf("== ") === 0) { sec = line.slice(3); continue; }
                    if (line === "!nocheck") { can = false; continue; }
                    if (line.indexOf("::") === 0 || line.toLowerCase().indexOf("warning") === 0) continue;
                    if (sec === "system") sys++;
                    else if (sec === "aur") aur++;
                    else if (sec === "flatpak") fp++;
                    else continue;
                    if (names.length < 8) names.push(line.split(/\s+/)[0]);
                }
                root.updSystem = sys;
                root.updAur = aur;
                root.updFlatpak = fp;
                root.updNames = names;
                root.updCanCheck = can;
                root.updChecking = false;
            }
        }
        onExited: root.updChecking = false
    }

    Process {
        id: updRun
        command: ["kitty", "--class", "joeos-update", "--title", "Updating JoeOS", "sh", "-c",
            "printf '\\n  \\033[1mUpdating your system\\033[0m\\n\\n'; "
            + "if command -v paru >/dev/null 2>&1; then paru -Syu; else sudo pacman -Syu; fi; "
            + "if command -v flatpak >/dev/null 2>&1; then printf '\\n  \\033[1mUpdating Flatpak apps\\033[0m\\n\\n'; flatpak update; fi; "
            + "printf '\\n  All done! Press Enter to close. '; read _"]
        onExited: {
            root.updRunning = false;
            root.checkUpdates();
        }
    }

    // first check shortly after login, then every 30 minutes
    Timer { interval: 90000; running: true; onTriggered: root.checkUpdates() }
    Timer { interval: 1800000; running: true; repeat: true; onTriggered: root.checkUpdates() }

    // ---------- Sports tab (basketball scores, standings, teams, players) ----------
    // Everything comes from ESPN's public scores feed: no account or key needed.
    readonly property var sportsLeagues: [
        { id: "nba", name: "NBA" },
        { id: "wnba", name: "WNBA" },
        { id: "mens-college-basketball", name: "NCAA M" },
        { id: "womens-college-basketball", name: "NCAA W" }
    ]
    readonly property string sportsLeague: pins.adapter.sportsLeague || "nba"
    property string sportsView: "games"      // games, standings, teams, team, player
    property string sportsBackTo: "games"    // where Back goes from a team page
    property int sportsDay: 0                // days away from today on the Games page
    property var sportsGames: []
    property var sportsConfs: []             // standings, one entry per conference
    property int sportsConf: 0
    property string sportsTeamFilter: ""
    property var sportsTeam: null
    property var sportsRoster: []
    property var sportsRecent: []
    property var sportsUpcoming: []
    property var sportsPlayer: null
    property var sportsPlayerStats: null
    property string sportsStatus: ""
    property int sportsPending: 0
    readonly property bool sportsLoading: sportsPending > 0
    property int sportsGen: 0                // bumped on league change so late answers are ignored
    property double sportsUpdated: 0
    readonly property bool sportsVisible: hubOpen && hubTab === 7
    readonly property bool sportsAnyLive: {
        for (let i = 0; i < sportsGames.length; i++) if (sportsGames[i].state === "in") return true;
        for (let i = 0; i < sportsUpcoming.length; i++) if (sportsUpcoming[i].state === "in") return true;
        if (sportsView === "game" && sportsGame && sportsGame.state === "in") return true;
        return false;
    }

    // favourite team (only for the league it belongs to)
    readonly property var sportsFavParts: (pins.adapter.sportsFav || "").split("|")
    readonly property string sportsFavId: sportsFavParts.length === 3 && sportsFavParts[0] === sportsLeague ? sportsFavParts[1] : ""
    readonly property string sportsFavAbbr: sportsFavId !== "" ? sportsFavParts[2] : ""
    function sportsToggleFav() {
        if (!sportsTeam) return;
        pins.adapter.sportsFav = sportsFavId === sportsTeam.id ? "" : sportsLeague + "|" + sportsTeam.id + "|" + (sportsTeam.abbr || "");
        sportsSortGames();
    }

    readonly property var sportsDayDate: {
        const d = new Date();
        d.setHours(12, 0, 0, 0);
        d.setDate(d.getDate() + sportsDay);
        return d;
    }
    readonly property string sportsDayLabel: {
        const names = { "-1": "Yesterday", "0": "Today", "1": "Tomorrow" };
        const pre = names[String(sportsDay)];
        return (pre ? pre + "  ·  " : "") + Qt.formatDate(sportsDayDate, "dddd, MMMM d");
    }
    onSportsDayChanged: sportsLoadGames()
    onSportsVisibleChanged: {
        if (sportsVisible && (Date.now() - sportsUpdated > 60000 || sportsGames.length === 0)) sportsRefresh();
    }

    // keeps scores fresh while the tab is open (every 20 s when a game is live)
    Timer {
        interval: root.sportsView === "game" && root.sportsGame && root.sportsGame.state === "in" ? 15000
            : root.sportsAnyLive ? 20000 : 120000
        running: root.sportsVisible
        repeat: true
        onTriggered: root.sportsRefresh()
    }

    function sportsTime(iso) {
        return Qt.formatDateTime(new Date(iso), root.use24h ? "HH:mm" : "h:mm AP");
    }
    function sportsBase() {
        return "https://site.api.espn.com/apis/site/v2/sports/basketball/" + sportsLeague;
    }
    function sportsLogo(t) {
        if (!t) return "";
        if (t.logos && t.logos.length) {
            for (let i = 0; i < t.logos.length; i++)
                if (t.logos[i].rel && t.logos[i].rel.indexOf("dark") >= 0) return t.logos[i].href;
            return t.logos[0].href;
        }
        return t.logo || "";
    }
    function sportsScore(sc) {
        if (sc === undefined || sc === null) return "";
        return typeof sc === "object" ? (sc.displayValue || "") : String(sc);
    }

    function sportsGet(url, done) {
        const gen = sportsGen;
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;
            root.sportsPending = Math.max(0, root.sportsPending - 1);
            if (gen !== root.sportsGen) return;
            if (xhr.status === 200) {
                try {
                    done(JSON.parse(xhr.responseText));
                    root.sportsStatus = "";
                    root.sportsUpdated = Date.now();
                } catch (e) {
                    root.sportsStatus = "Couldn't read the sports data";
                    console.warn("sports:", e);
                }
            } else {
                root.sportsStatus = xhr.status === 0 ? "Can't reach ESPN right now (no internet?)" : "ESPN error " + xhr.status;
            }
        };
        sportsPending += 1;
        xhr.open("GET", url);
        xhr.send();
    }

    function sportsRefresh() {
        if (sportsView === "games") sportsLoadGames();
        else if (sportsView === "standings" || sportsView === "teams") sportsLoadStandings();
        else if (sportsView === "team" && sportsTeam) sportsLoadTeam(sportsTeam.id);
        else if (sportsView === "player" && sportsPlayer) sportsLoadPlayer(sportsPlayer);
        else if (sportsView === "game" && sportsGame) sportsLoadGame(sportsGame.id);
    }

    function sportsShow(view) {
        sportsView = view;
        if (view === "games") sportsLoadGames();
        else if (sportsConfs.length === 0) sportsLoadStandings();
    }

    function sportsSetLeague(id) {
        if (id === sportsLeague) return;
        sportsGen += 1;
        pins.adapter.sportsLeague = id;
        sportsGames = [];
        sportsConfs = [];
        sportsConf = 0;
        sportsTeam = null;
        sportsPlayer = null;
        sportsStatus = "";
        sportsTeamFilter = "";
        if (sportsView === "team" || sportsView === "player") sportsView = "games";
        Qt.callLater(sportsRefresh);
    }

    // ---- Games on one day ----
    function sportsLoadGames() {
        let url = sportsBase() + "/scoreboard?dates=" + Qt.formatDate(sportsDayDate, "yyyyMMdd");
        if (sportsLeague.indexOf("college") >= 0) url += "&groups=50&limit=300";
        sportsGet(url, function (j) {
            const out = [];
            const evs = j.events || [];
            for (let i = 0; i < evs.length; i++) {
                const ev = evs[i], c = ev.competitions[0], st = ev.status || c.status;
                const side = {};
                for (let k = 0; k < c.competitors.length; k++) {
                    const t = c.competitors[k], tm = t.team || {};
                    side[t.homeAway] = {
                        id: String(tm.id),
                        abbr: tm.abbreviation || "",
                        name: tm.shortDisplayName || tm.displayName || "",
                        logo: root.sportsLogo(tm),
                        score: root.sportsScore(t.score),
                        record: t.records && t.records.length ? t.records[0].summary : "",
                        winner: t.winner === true
                    };
                }
                if (!side.home || !side.away) continue;
                const tv = [];
                (c.broadcasts || []).forEach(b => (b.names || []).forEach(n => { if (tv.indexOf(n) < 0) tv.push(n); }));
                out.push({
                    id: ev.id, date: ev.date, state: st.type.state, detail: st.type.shortDetail || "",
                    tv: tv.join(", "), away: side.away, home: side.home
                });
            }
            root.sportsGames = out;
            root.sportsSortGames();
        });
    }
    function sportsSortGames() {
        const order = { "in": 0, "pre": 1, "post": 2 };
        const fav = sportsFavId;
        const g = sportsGames.slice();
        g.sort((a, b) => {
            const fa = fav !== "" && (a.home.id === fav || a.away.id === fav) ? 0 : 1;
            const fb = fav !== "" && (b.home.id === fav || b.away.id === fav) ? 0 : 1;
            if (fa !== fb) return fa - fb;
            if (order[a.state] !== order[b.state]) return order[a.state] - order[b.state];
            return a.date < b.date ? -1 : a.date > b.date ? 1 : 0;
        });
        sportsGames = g;
    }

    // ---- Standings (also gives the list of teams) ----
    function sportsLoadStandings() {
        sportsGet("https://site.api.espn.com/apis/v2/sports/basketball/" + sportsLeague + "/standings", function (j) {
            const groups = j.children && j.children.length ? j.children : [j];
            const confs = [];
            for (let i = 0; i < groups.length; i++) {
                const g = groups[i], s = g.standings;
                if (!s || !s.entries || !s.entries.length) continue;
                const rows = s.entries.map(e => {
                    const st = {};
                    (e.stats || []).forEach(x => {
                        const v = x.displayValue !== undefined ? x.displayValue : x.summary;
                        if (x.name) st[x.name] = v;
                        if (x.type && st[x.type] === undefined) st[x.type] = v;
                        if (x.name === "playoffSeed") st.seedNum = x.value;
                        if (x.name === "winPercent") st.pctNum = x.value;
                    });
                    const t = e.team || {};
                    return {
                        id: String(t.id), name: t.displayName || "", short: t.shortDisplayName || t.name || t.displayName || "",
                        abbr: t.abbreviation || "", logo: root.sportsLogo(t),
                        w: st.wins || "0", l: st.losses || "0", pct: st.winPercent || "", gb: st.gamesBehind || "-",
                        strk: st.streak || "", l10: st.lasttengames || st["Last Ten Games"] || "",
                        seed: st.seedNum || 0, pctNum: st.pctNum || 0
                    };
                });
                rows.sort((a, b) => (a.seed && b.seed) ? a.seed - b.seed : b.pctNum - a.pctNum);
                confs.push({ name: g.abbreviation || g.shortName || g.name || "Standings", rows: rows });
            }
            root.sportsConfs = confs;
            if (root.sportsConf >= confs.length) root.sportsConf = 0;
        });
    }
    readonly property var sportsAllTeams: {
        const out = [], f = sportsTeamFilter.toLowerCase();
        for (let i = 0; i < sportsConfs.length; i++)
            for (let k = 0; k < sportsConfs[i].rows.length; k++) {
                const r = sportsConfs[i].rows[k];
                if (f === "" || r.name.toLowerCase().indexOf(f) >= 0 || r.abbr.toLowerCase().indexOf(f) >= 0) out.push(r);
            }
        out.sort((a, b) => a.name.localeCompare(b.name));
        return out;
    }

    // ---- One team: roster + schedule ----
    function sportsOpenTeam(id) {
        if (sportsView === "games" || sportsView === "standings" || sportsView === "teams") sportsBackTo = sportsView;
        sportsTeam = { id: String(id) };
        sportsRoster = [];
        sportsRecent = [];
        sportsUpcoming = [];
        sportsView = "team";
        sportsLoadTeam(String(id));
    }
    function sportsLoadTeam(id) {
        sportsGet(sportsBase() + "/teams/" + id + "/roster", function (j) {
            const t = j.team || {};
            root.sportsTeam = {
                id: String(id), name: t.displayName || "", abbr: t.abbreviation || "",
                logo: root.sportsLogo(t), color: t.color ? "#" + t.color : "",
                record: t.recordSummary || "", standing: t.standingSummary || ""
            };
            let list = j.athletes || [];
            if (list.length && list[0].items) {         // some leagues group players by position
                let flat = [];
                list.forEach(g => flat = flat.concat(g.items || []));
                list = flat;
            }
            root.sportsRoster = list.map(a => ({
                id: String(a.id), name: a.displayName || a.fullName || "", jersey: a.jersey || "",
                pos: a.position ? (a.position.abbreviation || "") : "",
                height: a.displayHeight || "", weight: a.displayWeight || "",
                age: a.age ? String(a.age) : "",
                exp: a.experience && a.experience.years !== undefined ? String(a.experience.years) : "",
                headshot: a.headshot ? a.headshot.href : "",
                injury: a.injuries && a.injuries.length ? (a.injuries[0].status || "Injured") : ""
            })).sort((a, b) => (parseInt(a.jersey) || 99) - (parseInt(b.jersey) || 99));
        });
        sportsGet(sportsBase() + "/teams/" + id + "/schedule", function (j) {
            const done = [], next = [];
            (j.events || []).forEach(ev => {
                const c = ev.competitions[0], st = c.status || ev.status;
                let us = null, them = null;
                c.competitors.forEach(x => { if (String(x.team.id) === String(id)) us = x; else them = x; });
                if (!us || !them) return;
                const g = {
                    id: ev.id, date: ev.date, state: st.type.state, detail: st.type.shortDetail || "",
                    home: us.homeAway === "home", opp: them.team.abbreviation || "",
                    oppName: them.team.shortDisplayName || them.team.displayName || "",
                    oppId: String(them.team.id), oppLogo: root.sportsLogo(them.team),
                    us: root.sportsScore(us.score), them: root.sportsScore(them.score), won: us.winner === true
                };
                if (g.state === "post") done.push(g); else next.push(g);
            });
            root.sportsRecent = done.slice(-4).reverse();
            root.sportsUpcoming = next.slice(0, 5);
        });
    }

    // ---- One game: live box score (every player's stats) ----
    property var sportsGame: null            // the game card that was clicked
    property var sportsBox: null             // { teams: [away, home], lines, detail, state }
    property int sportsBoxSide: 0            // which team's players are shown (0 away, 1 home)
    property string sportsPlayerFrom: "team" // where Back goes from a player page
    function sportsOpenGame(g) {
        if (sportsView === "games" || sportsView === "standings" || sportsView === "teams" || sportsView === "team")
            sportsBackTo = sportsView;
        sportsGame = g;
        sportsBox = null;
        sportsBoxSide = 0;
        sportsView = "game";
        sportsLoadGame(g.id);
    }
    function sportsLoadGame(id) {
        sportsGet(sportsBase() + "/summary?event=" + id, function (j) {
            const box = j.boxscore || {};
            const teams = [];
            (box.players || []).forEach(t => {
                const st = (t.statistics || [])[0] || {};
                const tm = t.team || {};
                teams.push({
                    id: String(tm.id), abbr: tm.abbreviation || "", name: tm.shortDisplayName || tm.displayName || "",
                    logo: root.sportsLogo(tm),
                    labels: st.labels || st.names || [],
                    totals: st.totals || [],
                    players: (st.athletes || []).map(a => {
                        const at = a.athlete || {};
                        return {
                            id: String(at.id), name: at.displayName || "", short: at.shortName || at.displayName || "",
                            jersey: at.jersey || "", pos: at.position ? (at.position.abbreviation || "") : "",
                            headshot: at.headshot ? at.headshot.href : "",
                            height: "", weight: "", age: "", exp: "", injury: "", team: tm.displayName || "",
                            starter: a.starter === true, dnp: a.didNotPlay === true,
                            reason: a.reason || "", stats: a.stats || []
                        };
                    })
                });
            });
            // keep away first, like the game card
            const g = root.sportsGame;
            if (g && teams.length === 2 && teams[0].id === g.home.id) teams.reverse();

            // score by quarter and the clock, if the summary has them
            const out = { teams: teams, lines: [], detail: g ? g.detail : "", state: g ? g.state : "", away: g ? g.away.score : "", home: g ? g.home.score : "" };
            const hc = j.header && j.header.competitions ? j.header.competitions[0] : null;
            if (hc) {
                const st = hc.status || {};
                if (st.type) {
                    out.state = st.type.state || out.state;
                    out.detail = st.type.shortDetail || out.detail;
                }
                const side = {};
                (hc.competitors || []).forEach(c => side[c.homeAway] = c);
                if (side.away && side.home) {
                    out.away = root.sportsScore(side.away.score) || out.away;
                    out.home = root.sportsScore(side.home.score) || out.home;
                    const al = side.away.linescores || [], hl = side.home.linescores || [];
                    for (let i = 0; i < Math.max(al.length, hl.length); i++)
                        out.lines.push({
                            label: i < 4 ? "Q" + (i + 1) : (i === 4 ? "OT" : "OT" + (i - 3)),
                            away: al[i] ? (al[i].displayValue || String(al[i].value || "")) : "",
                            home: hl[i] ? (hl[i].displayValue || String(hl[i].value || "")) : ""
                        });
                }
            }
            if (g && out.state) root.sportsGame = Object.assign({}, g, { state: out.state, detail: out.detail });
            root.sportsBox = out;
        });
    }
    function sportsOpenPlayerFrom(p, from) {
        sportsPlayerFrom = from;
        sportsOpenPlayer(p);
    }

    // ---- One player ----
    function sportsOpenPlayer(p) {
        sportsPlayer = p;
        sportsView = "player";
        sportsLoadPlayer(p);
    }
    function sportsLoadPlayer(p) {
        sportsPlayerStats = null;
        sportsGet("https://site.web.api.espn.com/apis/common/v3/sports/basketball/" + sportsLeague + "/athletes/" + p.id + "/overview", function (j) {
            const s = j.statistics;
            root.sportsPlayerStats = s && s.labels ? {
                labels: s.labels,
                rows: (s.splits || []).map(x => ({ name: x.displayName || "", stats: x.stats || [] }))
            } : { labels: [], rows: [] };
        });
    }

    // ---------- Top bar: the island ----------
    // A compact pill at the top centre. Click it and it grows into the hub:
    // Home, Media, Apps, Calendar, Alerts and System.
    property bool hubOpen: false
    property int hubTab: 0           // 0 home, 1 media, 2 apps, 3 calendar, 4 alerts, 5 system, 6 capture, 7 sports, 8 themes
    property int calOffset: 0        // how many months away from this one the calendar shows
    readonly property int hubW: 900
    readonly property int hubH: 560

    function openHub(tab) {
        hubTab = tab;
        calOffset = 0;
        hubOpen = true;
    }

    // Optional, in hyprland.conf:  bind = SUPER, A, global, quickshell:hub
    GlobalShortcut {
        appid: "quickshell"
        name: "hub"
        description: "Open or close the top hub"
        onPressed: root.hubOpen = !root.hubOpen
    }

    // Alternative:  quickshell ipc call hub toggle   (or: quickshell ipc call hub open 3)
    IpcHandler {
        target: "hub"
        function toggle(): void {
            root.hubOpen = !root.hubOpen;
        }
        function open(tab: int): void {
            root.openHub(tab);
        }
    }

    // ----- Network, Bluetooth and night light state (checked every few seconds) -----
    property bool wifiOn: false
    property string netKind: ""      // "wifi", "ethernet" or "" when offline
    property string netName: ""
    property string btState: "none"  // "yes", "no", or "none" when Bluetooth isn't available
    property string nightState: "none" // "on", "off", or "none" when hyprsunset isn't installed

    Process {
        id: statusProc
        command: ["sh", "-c", 'echo "W=$(nmcli -t -f WIFI g 2>/dev/null)"; echo "N=$(nmcli -t -f TYPE,STATE,CONNECTION d 2>/dev/null | grep -m1 ":connected:")"; if command -v bluetoothctl >/dev/null 2>&1; then echo "B=$(bluetoothctl show 2>/dev/null | grep -m1 -o "Powered: [a-z]*")"; fi; if command -v hyprsunset >/dev/null 2>&1; then if pgrep -x hyprsunset >/dev/null; then echo "S=on"; else echo "S=off"; fi; fi; if command -v wf-recorder >/dev/null 2>&1; then echo "R=yes"; fi']
        stdout: StdioCollector {
            onStreamFinished: {
                const v = { W: "", N: "", B: null, S: null, R: "" };
                const lines = text.split("\n");
                for (let i = 0; i < lines.length; i++) {
                    const at = lines[i].indexOf("=");
                    if (at > 0) v[lines[i].slice(0, at)] = lines[i].slice(at + 1);
                }
                root.wifiOn = v.W.trim() === "enabled";
                const n = v.N.trim().split(":");
                root.netKind = n.length >= 2 ? n[0] : "";
                root.netName = n.length >= 3 ? n.slice(2).join(":") : "";
                root.btState = v.B === null ? "none" : (v.B.indexOf("yes") >= 0 ? "yes" : "no");
                root.nightState = v.S === null ? "none" : v.S.trim();
                root.canRecord = (v.R || "").trim() === "yes";
            }
        }
    }

    Timer {
        interval: 5000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: if (!statusProc.running) statusProc.running = true
    }

    Timer {
        id: statusSoon
        interval: 800
        onTriggered: if (!statusProc.running) statusProc.running = true
    }

    // Runs a shell command, then re-checks the toggles so they update straight away
    function run(cmd) {
        Quickshell.execDetached(["sh", "-c", cmd]);
        statusSoon.restart();
    }

    // ----- GPU usage/temperature and CPU temperature (only while the hub is open) -----
    property int gpuUse: -1
    property int gpuTemp: -1
    property int cpuTemp: -1

    Process {
        id: gpuProc
        command: ["sh", "-c", 'g=""; if command -v nvidia-smi >/dev/null 2>&1; then g=$(nvidia-smi --query-gpu=utilization.gpu,temperature.gpu --format=csv,noheader,nounits 2>/dev/null | head -n1 | tr -d " "); fi; if [ -z "$g" ]; then for d in /sys/class/drm/card*/device; do if [ -r "$d/gpu_busy_percent" ]; then t=$(cat "$d"/hwmon/hwmon*/temp1_input 2>/dev/null | head -n1); g="$(cat "$d/gpu_busy_percent"),$(( ${t:-0} / 1000 ))"; break; fi; done; fi; c=""; for h in /sys/class/hwmon/hwmon*; do n=$(cat "$h/name" 2>/dev/null); if [ "$n" = k10temp ] || [ "$n" = coretemp ] || [ "$n" = zenpower ]; then c=$(( $(cat "$h/temp1_input" 2>/dev/null || echo 0) / 1000 )); break; fi; done; echo "G=$g"; echo "C=$c"']
        stdout: StdioCollector {
            onStreamFinished: {
                let g = "", c = "";
                const lines = text.split("\n");
                for (let i = 0; i < lines.length; i++) {
                    if (lines[i].indexOf("G=") === 0) g = lines[i].slice(2).trim();
                    if (lines[i].indexOf("C=") === 0) c = lines[i].slice(2).trim();
                }
                const gp = g.split(",");
                root.gpuUse = gp.length === 2 && gp[0] !== "" ? parseInt(gp[0]) : -1;
                root.gpuTemp = gp.length === 2 && gp[1] !== "" && parseInt(gp[1]) > 0 ? parseInt(gp[1]) : -1;
                root.cpuTemp = c !== "" && parseInt(c) > 0 ? parseInt(c) : -1;
            }
        }
    }

    Timer {
        interval: 2500
        repeat: true
        running: root.hubOpen
        triggeredOnStart: true
        onTriggered: if (!gpuProc.running) gpuProc.running = true
    }

    // ----- Screenshots and screen recording (Capture tab) -----
    // The work is done by scripts/capture.sh next to this file.
    readonly property string captureScript: Quickshell.env("HOME") + "/.config/quickshell/scripts/capture.sh"
    property int shotDelay: 0             // seconds to wait before a screenshot
    property string recAudio: "none"      // "none", "system" or "mic"
    property bool canRecord: false        // wf-recorder installed?
    readonly property bool recording: recProc.running
    property double recStartedAt: 0
    property int recSeconds: 0
    property var pendingCapture: null

    function focusedMonitorName2() {
        return Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "";
    }

    // Close the hub first so it isn't in the picture, then run the capture
    function capture(fn) {
        hubOpen = false;
        pendingCapture = fn;
        captureTimer.restart();
    }

    Timer {
        id: captureTimer
        interval: 450
        onTriggered: {
            const fn = root.pendingCapture;
            root.pendingCapture = null;
            if (fn) fn();
        }
    }

    function shot(mode) {
        const mon = focusedMonitorName2();
        const delay = String(shotDelay);
        capture(() => Quickshell.execDetached(["bash", root.captureScript, "shot", mode, delay, mon]));
    }

    function record(mode) {
        if (recording || !canRecord) return;
        const mon = focusedMonitorName2();
        const audio = recAudio;
        capture(() => {
            recProc.command = ["bash", root.captureScript, "rec", mode, audio, mon];
            recProc.running = true;
        });
    }

    function stopRecording() {
        Quickshell.execDetached(["bash", root.captureScript, "stop"]);
        recProc.signal(2);          // also tell the recording script itself to wrap up
        recStopGuard.restart();
    }
    // if the recorder is somehow still going after the stop script has had its turn,
    // stop tracking it so the pill and the Capture tab go back to normal
    Timer {
        id: recStopGuard
        interval: 7000
        onTriggered: if (recProc.running) recProc.running = false
    }

    function takeScreenshot() {
        shot("area");
    }

    Process {
        id: recProc
        onRunningChanged: {
            if (running) {
                root.recStartedAt = Date.now();
                root.recSeconds = 0;
            }
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.recording
        onTriggered: root.recSeconds = Math.floor((Date.now() - root.recStartedAt) / 1000)
    }

    function netIcon() {
        if (netKind === "wifi") return "";
        if (netKind === "ethernet") return "";
        return "";
    }

    function volIcon(a) {
        if (!a || a.muted) return "";
        return a.volume < 0.4 ? "" : "";
    }

    // Liquid glass shine: light across the top, a bright rim, and light pooling at the bottom.
    // Drop it into any rounded Rectangle:  GlassShine { radius: parent.radius; dark: root.dark }
    component GlassShine: Item {
        id: gs
        property real radius: 20
        property bool dark: true
        property real strength: 1
        anchors.fill: parent

        // soft light falling across the top half
        Rectangle {
            anchors.fill: parent
            radius: gs.radius
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, (gs.dark ? 0.16 : 0.45) * gs.strength) }
                GradientStop { position: 0.4; color: Qt.rgba(1, 1, 1, (gs.dark ? 0.03 : 0.10) * gs.strength) }
                GradientStop { position: 0.7; color: Qt.rgba(1, 1, 1, 0) }
            }
        }
        // light gathering along the bottom edge, like it's bending through the glass
        Rectangle {
            anchors.fill: parent
            radius: gs.radius
            gradient: Gradient {
                GradientStop { position: 0.78; color: Qt.rgba(1, 1, 1, 0) }
                GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, (gs.dark ? 0.09 : 0.25) * gs.strength) }
            }
        }
        // inner rim
        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: Math.max(0, gs.radius - 1)
            color: "transparent"
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, (gs.dark ? 0.10 : 0.35) * gs.strength)
        }
        // bright specular streak along the top edge
        Rectangle {
            anchors.top: parent.top
            anchors.topMargin: 1
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.max(0, parent.width - gs.radius * 1.4)
            height: 1
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0) }
                GradientStop { position: 0.3; color: Qt.rgba(1, 1, 1, (gs.dark ? 0.55 : 0.95) * gs.strength) }
                GradientStop { position: 0.7; color: Qt.rgba(1, 1, 1, (gs.dark ? 0.55 : 0.95) * gs.strength) }
                GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0) }
            }
        }
    }

    // ---------- Stickers ----------
    // Drop .png / .webp / .gif images into ~/Pictures/Stickers (animated GIFs and WebPs play)
    // and they show up in the little sticker
    // spots around the setup. With the folder empty, the spots show the droplet buddy instead.
    FolderListModel {
        id: stickerModel
        folder: "file://" + Quickshell.env("HOME") + "/Pictures/Stickers"
        nameFilters: ["*.png", "*.webp", "*.gif", "*.jpg", "*.jpeg", "*.PNG", "*.WEBP", "*.GIF", "*.JPG", "*.JPEG"]
        showDirs: false
        sortField: FolderListModel.Name
    }

    function stickerFor(slot) {
        const n = stickerModel.count;
        return n > 0 ? stickerModel.get(slot % n, "fileUrl").toString() : "";
    }

    // A sticker spot: one of your sticker images, or the droplet buddy if you have none.
    // It bobs gently, blinks now and then and hops when you hover it.
    component Buddy: Item {
        id: bud
        property var theme: null
        property int slot: 0
        property real size: 26
        readonly property string img: bud.theme ? bud.theme.stickerFor(bud.slot) : ""
        property real bob: 0
        implicitWidth: bud.size
        implicitHeight: bud.size
        width: bud.size
        height: bud.size
        scale: budHover.hovered ? 1.18 : 1
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }

        HoverHandler { id: budHover }

        SequentialAnimation on bob {
            loops: Animation.Infinite
            NumberAnimation { from: 0; to: -2; duration: 1300 + bud.slot * 90; easing.type: Easing.InOutSine }
            NumberAnimation { from: -2; to: 0; duration: 1300 + bud.slot * 90; easing.type: Easing.InOutSine }
        }

        // AnimatedImage plays GIFs and animated WebPs, and shows still pictures normally
        AnimatedImage {
            visible: bud.img !== ""
            anchors.fill: parent
            source: bud.img
            playing: visible
            fillMode: Image.PreserveAspectFit
            smooth: true
            transform: Translate { y: bud.bob }
        }

        Canvas {
            id: drop
            visible: bud.img === ""
            anchors.fill: parent
            transform: Translate { y: bud.bob }
            property bool blink: false
            onBlinkChanged: requestPaint()
            onWidthChanged: requestPaint()

            Timer {
                interval: 3100 + bud.slot * 430
                running: drop.visible
                repeat: true
                onTriggered: {
                    drop.blink = true;
                    blinkOff.restart();
                }
            }
            Timer {
                id: blinkOff
                interval: 140
                onTriggered: drop.blink = false
            }

            onPaint: {
                const c = getContext("2d");
                const w = width, h = height;
                c.reset();
                // body: a round water droplet
                c.beginPath();
                c.moveTo(w * 0.5, h * 0.04);
                c.bezierCurveTo(w * 0.62, h * 0.24, w * 0.92, h * 0.44, w * 0.92, h * 0.64);
                c.bezierCurveTo(w * 0.92, h * 0.86, w * 0.73, h * 0.97, w * 0.5, h * 0.97);
                c.bezierCurveTo(w * 0.27, h * 0.97, w * 0.08, h * 0.86, w * 0.08, h * 0.64);
                c.bezierCurveTo(w * 0.08, h * 0.44, w * 0.38, h * 0.24, w * 0.5, h * 0.04);
                c.closePath();
                const g = c.createLinearGradient(0, 0, 0, h);
                g.addColorStop(0, "rgba(186, 230, 253, 0.95)");
                g.addColorStop(1, "rgba(56, 152, 236, 0.95)");
                c.fillStyle = g;
                c.fill();
                c.lineWidth = Math.max(1, w * 0.04);
                c.strokeStyle = "rgba(255, 255, 255, 0.75)";
                c.stroke();
                // shine
                c.beginPath();
                c.ellipse(w * 0.26, h * 0.38, w * 0.14, h * 0.18);
                c.fillStyle = "rgba(255, 255, 255, 0.55)";
                c.fill();
                // eyes (or a blink)
                c.fillStyle = "#1b2330";
                c.strokeStyle = "#1b2330";
                c.lineWidth = Math.max(1, w * 0.05);
                const ey = h * 0.62, er = w * 0.065;
                [0.37, 0.63].forEach(x => {
                    if (drop.blink) {
                        c.beginPath();
                        c.moveTo(w * x - er, ey);
                        c.lineTo(w * x + er, ey);
                        c.stroke();
                    } else {
                        c.beginPath();
                        c.arc(w * x, ey, er, 0, Math.PI * 2);
                        c.fill();
                        c.beginPath();
                        c.arc(w * x + er * 0.35, ey - er * 0.35, er * 0.38, 0, Math.PI * 2);
                        c.fillStyle = "white";
                        c.fill();
                        c.fillStyle = "#1b2330";
                    }
                });
                // rosy cheeks
                c.fillStyle = "rgba(255, 140, 170, 0.55)";
                [0.25, 0.75].forEach(x => {
                    c.beginPath();
                    c.ellipse(w * x - w * 0.06, h * 0.72 - h * 0.035, w * 0.12, h * 0.07);
                    c.fill();
                });
                // little smile
                c.beginPath();
                c.arc(w * 0.5, h * 0.70, w * 0.075, Math.PI * 0.15, Math.PI * 0.85);
                c.strokeStyle = "#1b2330";
                c.lineWidth = Math.max(1, w * 0.045);
                c.stroke();
            }
        }
    }

    // Now playing: a big square picture of the song / video, with everything lined up to its width.
    //   wide: false = controls under the picture (bottom dock pop-up)
    //   wide: true  = controls beside the picture, matching its top and bottom (hub Media tab)
    component NowPlaying: Item {
        id: np
        property var theme: null
        property var player: null
        property int artSize: 280
        property bool wide: false
        property real backdropMargin: 20       // how far the blurred art spreads into the card around it
        readonly property bool isPlaying: np.theme ? np.theme.playing(np.player) : false
        readonly property int infoWidth: np.wide ? Math.round(np.artSize * 1.2) : np.artSize
        implicitWidth: npGrid.implicitWidth
        implicitHeight: npGrid.implicitHeight

        // position only updates when asked
        Timer {
            interval: 1000
            repeat: true
            running: np.visible && np.isPlaying
            onTriggered: if (np.player) np.player.positionChanged()
        }

        // soft blurred copy of the art behind everything (tiny image scaled up = blur)
        Item {
            anchors.fill: parent
            anchors.margins: -np.backdropMargin
            clip: true
            z: -1
            Image {
                id: npBackdrop
                anchors.fill: parent
                source: np.player ? np.player.trackArtUrl : ""
                sourceSize.width: 96
                sourceSize.height: 96
                fillMode: Image.PreserveAspectCrop
                visible: false
            }
            MultiEffect {
                anchors.fill: parent
                source: npBackdrop
                blurEnabled: true
                blur: 1.0
                blurMax: 64
                saturation: 0.15
                opacity: npBackdrop.status === Image.Ready ? 0.5 : 0
                Behavior on opacity { NumberAnimation { duration: 400 } }
            }
            Rectangle {
                anchors.fill: parent
                color: np.theme ? Qt.rgba(np.theme.bg.r, np.theme.bg.g, np.theme.bg.b, 0.35) : "transparent"
            }
        }

        GridLayout {
            id: npGrid
            columns: np.wide ? 2 : 1
            columnSpacing: 28
            rowSpacing: 16

            // ---- the picture ----
            Rectangle {
                Layout.preferredWidth: np.artSize
                Layout.preferredHeight: np.artSize
                radius: Math.round(np.artSize * 0.08)
                color: np.theme ? np.theme.overlay : "#333"

                Image {
                    id: npArt
                    anchors.fill: parent
                    source: np.player ? np.player.trackArtUrl : ""
                    sourceSize.width: np.artSize * 2
                    fillMode: Image.PreserveAspectCrop
                    smooth: true
                    visible: false
                }
                // the rounded shape the picture is cut to
                Item {
                    id: npArtMask
                    anchors.fill: parent
                    layer.enabled: true
                    visible: false
                    Rectangle {
                        anchors.fill: parent
                        radius: Math.round(np.artSize * 0.08)
                        color: "black"
                    }
                }
                MultiEffect {
                    anchors.fill: parent
                    source: npArt
                    maskEnabled: true
                    maskSource: npArtMask
                    visible: npArt.status === Image.Ready
                }
                Text {
                    anchors.centerIn: parent
                    visible: npArt.status !== Image.Ready
                    text: "\uf001"
                    color: np.theme ? np.theme.muted : "grey"
                    font.family: np.theme ? np.theme.iconFont : ""
                    font.pixelSize: np.artSize * 0.25
                }
                GlassShine { radius: parent.radius; dark: np.theme ? np.theme.dark : true; strength: 0.7 }
                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: "transparent"
                    border.width: 1
                    border.color: np.theme ? np.theme.glassEdge : "transparent"
                }
            }

            // ---- everything else, exactly as wide as the picture (or a bit wider beside it) ----
            ColumnLayout {
                Layout.preferredWidth: np.infoWidth
                Layout.preferredHeight: np.wide ? np.artSize : -1
                spacing: np.wide ? 8 : 6

                Text {
                    Layout.fillWidth: true
                    text: np.player ? (np.player.trackTitle || np.player.identity || "Unknown") : "Nothing playing"
                    color: np.theme ? np.theme.fg : "white"
                    font.pixelSize: np.wide ? 26 : 18
                    font.bold: true
                    wrapMode: Text.Wrap
                    maximumLineCount: np.wide ? 2 : 1      // the dock card keeps one size
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    visible: np.wide ? text !== " " : true
                    text: np.player && np.player.trackArtist ? np.player.trackArtist : " "
                    color: np.theme ? np.theme.muted : "grey"
                    font.pixelSize: np.wide ? 16 : 13
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    text: np.player ? np.player.identity : ""
                    color: np.theme ? np.theme.accent : "white"
                    font.pixelSize: 11
                    opacity: 0.85
                    elide: Text.ElideRight
                }

                // beside the picture: push the controls down to line up with its bottom edge
                Item {
                    Layout.fillHeight: np.wide
                    Layout.preferredHeight: np.wide ? -1 : 4
                }

                // ---- seek bar + times ----
                ValueBar {
                    theme: np.theme
                    Layout.fillWidth: true
                    value: np.player && np.player.length > 0 ? np.player.position / np.player.length : 0
                    onMoved: v => {
                        const p = np.player;
                        if (p && p.canSeek && p.length > 0) p.position = v * p.length;
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: np.theme ? np.theme.fmt(np.player ? np.player.position : 0) : ""
                        color: np.theme ? np.theme.muted : "grey"
                        font.pixelSize: 11
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: np.theme ? np.theme.fmt(np.player ? np.player.length : 0) : ""
                        color: np.theme ? np.theme.muted : "grey"
                        font.pixelSize: 11
                    }
                }

                // ---- five evenly spaced buttons across the full width ----
                Row {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 60

                    Repeater {
                        model: [
                            { key: "shuffle", icon: "\uf074" },
                            { key: "prev", icon: "\uf048" },
                            { key: "play", icon: "" },
                            { key: "next", icon: "\uf051" },
                            { key: "repeat", icon: "\uf01e" }
                        ]
                        delegate: Item {
                            id: npCell
                            required property var modelData
                            readonly property var p: np.player
                            readonly property bool big: npCell.modelData.key === "play"
                            readonly property bool lit: npCell.modelData.key === "shuffle" ? !!(npCell.p && npCell.p.shuffle)
                                : npCell.modelData.key === "repeat" ? !!(npCell.p && npCell.p.loopState !== MprisLoopState.None)
                                : false
                            readonly property bool ok: !npCell.p ? false
                                : npCell.modelData.key === "shuffle" ? npCell.p.shuffleSupported
                                : npCell.modelData.key === "repeat" ? npCell.p.loopSupported
                                : npCell.modelData.key === "prev" ? npCell.p.canGoPrevious
                                : npCell.modelData.key === "next" ? npCell.p.canGoNext
                                : npCell.p.canTogglePlaying
                            width: np.infoWidth / 5
                            height: 60

                            Rectangle {
                                anchors.centerIn: parent
                                width: npCell.big ? 58 : 42
                                height: width
                                radius: width / 2
                                opacity: npCell.ok ? 1 : 0.35
                                color: npCell.big ? (np.theme ? np.theme.fg : "white")
                                    : npCell.lit ? (np.theme ? np.theme.accent : "white")
                                    : (npMouse.containsMouse && np.theme ? np.theme.overlay : "transparent")
                                border.width: npCell.big ? 0 : 1
                                border.color: npMouse.containsMouse || npCell.lit ? (np.theme ? np.theme.glassEdge : "transparent") : "transparent"
                                scale: npMouse.pressed ? 0.9 : (npMouse.containsMouse ? 1.06 : 1)
                                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                                Behavior on color { ColorAnimation { duration: 150 } }

                                Text {
                                    anchors.centerIn: parent
                                    anchors.horizontalCenterOffset: npCell.big && !np.isPlaying ? 2 : 0
                                    text: npCell.big ? (np.isPlaying ? "\uf04c" : "\uf04b") : npCell.modelData.icon
                                    color: npCell.big || npCell.lit ? (np.theme ? np.theme.bg : "black") : (np.theme ? np.theme.fg : "white")
                                    font.family: np.theme ? np.theme.iconFont : ""
                                    font.pixelSize: npCell.big ? 22 : 16
                                }
                                // "1" when repeating one song
                                Rectangle {
                                    visible: npCell.modelData.key === "repeat" && !!npCell.p && npCell.p.loopState === MprisLoopState.Track
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    width: 14
                                    height: 14
                                    radius: 7
                                    color: np.theme ? np.theme.bg : "black"
                                    Text { anchors.centerIn: parent; text: "1"; color: np.theme ? np.theme.accent : "white"; font.pixelSize: 9; font.bold: true }
                                }

                                MouseArea {
                                    id: npMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: npCell.ok ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    onClicked: {
                                        const p = npCell.p;
                                        if (!p || !npCell.ok) return;
                                        const k = npCell.modelData.key;
                                        if (k === "play") p.togglePlaying();
                                        else if (k === "prev") p.previous();
                                        else if (k === "next") p.next();
                                        else if (k === "shuffle") p.shuffle = !p.shuffle;
                                        else if (k === "repeat")
                                            p.loopState = p.loopState === MprisLoopState.None ? MprisLoopState.Playlist
                                                : (p.loopState === MprisLoopState.Playlist ? MprisLoopState.Track : MprisLoopState.None);
                                    }
                                }
                            }
                        }
                    }
                }

                // ---- volume, same width ----
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    Text {
                        text: np.theme ? (np.theme.mediaMuted(np.player) ? "\uf026" : np.theme.volIcon({ volume: np.theme.mediaVolume(np.player), muted: false })) : ""
                        color: np.theme ? np.theme.fg : "white"
                        font.family: np.theme ? np.theme.iconFont : ""
                        font.pixelSize: 15
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -6
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (np.theme) np.theme.toggleMediaMute(np.player)
                        }
                    }
                    ValueBar {
                        theme: np.theme
                        Layout.fillWidth: true
                        value: np.theme ? np.theme.mediaVolume(np.player) : 0
                        onMoved: v => { if (np.theme) np.theme.setMediaVolume(np.player, v); }
                    }
                    Text {
                        Layout.preferredWidth: 36
                        horizontalAlignment: Text.AlignRight
                        text: np.theme ? Math.round(np.theme.mediaVolume(np.player) * 100) + "%" : ""
                        color: np.theme ? np.theme.muted : "grey"
                        font.pixelSize: 11
                    }
                }
            }
        }
    }

    // Small rounded switch used on the Sports tab (Games / Standings / NBA ...)
    component SportChip: Rectangle {
        id: sc
        property var theme: null
        property string label: ""
        property string icon: ""
        property bool active: false
        signal clicked()
        implicitWidth: scRow.implicitWidth + (sc.label === "" ? 20 : 24)
        implicitHeight: 32
        radius: 10
        color: sc.active ? (sc.theme ? sc.theme.accent : "white") : (scMouse.containsMouse && sc.theme ? sc.theme.overlay : "transparent")
        border.width: sc.active ? 0 : 1
        border.color: sc.theme ? sc.theme.glassEdge : "transparent"
        scale: scMouse.pressed ? 0.94 : 1
        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }

        Row {
            id: scRow
            anchors.centerIn: parent
            spacing: 6
            Text {
                visible: sc.icon !== ""
                anchors.verticalCenter: parent.verticalCenter
                text: sc.icon
                font.family: sc.theme ? sc.theme.iconFont : ""
                font.pixelSize: 13
                color: sc.active ? (sc.theme ? sc.theme.bg : "black") : (sc.theme ? sc.theme.accent : "white")
            }
            Text {
                visible: sc.label !== ""
                anchors.verticalCenter: parent.verticalCenter
                text: sc.label
                font.pixelSize: 12
                font.bold: sc.active
                color: sc.active ? (sc.theme ? sc.theme.bg : "black") : (sc.theme ? sc.theme.fg : "white")
            }
        }

        MouseArea {
            id: scMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: sc.clicked()
        }
    }

    // A team logo from ESPN; shows the team's letters in a circle until (or if) the picture loads
    component TeamLogo: Item {
        id: tl
        property var theme: null
        property string source: ""
        property string abbr: ""
        implicitWidth: 32
        implicitHeight: 32

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            visible: tlImg.status !== Image.Ready
            color: tl.theme ? tl.theme.overlay : "#444"
            Text {
                anchors.centerIn: parent
                text: tl.abbr
                color: tl.theme ? tl.theme.fg : "white"
                font.pixelSize: Math.max(8, Math.round(tl.width * 0.28))
                font.bold: true
            }
        }
        Image {
            id: tlImg
            anchors.fill: parent
            source: tl.source
            sourceSize.width: 160
            sourceSize.height: 160
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            smooth: true
            mipmap: true
        }
    }

    // A quick-toggle tile (hub Home and System)
    component HubToggle: Rectangle {
        id: tgl
        property var theme: null
        property var item: ({})
        radius: 20
        color: tgl.item.active ? tgl.theme.accent : (tglMouse.containsMouse ? tgl.theme.overlay : tgl.theme.surface)
        border.width: 1
        border.color: tgl.theme.glassEdge
        opacity: tgl.item.ok ? 1 : 0.45
        scale: tglMouse.pressed ? 0.95 : (tglMouse.containsMouse && tgl.item.ok ? 1.03 : 1)
        Behavior on color { ColorAnimation { duration: tgl.theme.animMs } }
        Behavior on scale { NumberAnimation { duration: tgl.theme.animMs; easing.type: Easing.OutBack } }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            Rectangle {
                Layout.preferredWidth: 38
                Layout.preferredHeight: 38
                radius: 19
                color: tgl.item.active ? Qt.rgba(1, 1, 1, 0.25) : tgl.theme.overlay

                Text {
                    anchors.centerIn: parent
                    text: tgl.item.icon
                    color: tgl.item.active ? tgl.theme.bg : tgl.theme.accent
                    font.family: tgl.theme.iconFont
                    font.pixelSize: 15
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                Text {
                    Layout.fillWidth: true
                    text: tgl.item.title
                    color: tgl.item.active ? tgl.theme.bg : tgl.theme.fg
                    font.pixelSize: 13
                    font.bold: true
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    text: tgl.item.sub
                    color: tgl.item.active ? tgl.theme.bg : tgl.theme.muted
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }
            }
        }

        MouseArea {
            id: tglMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: tgl.item.ok ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: if (tgl.item.ok) tgl.item.run()
        }
    }

    // Small glossy card used all over the hub
    component HubCard: Rectangle {
        id: hc
        property var theme: null
        radius: 20
        color: hc.theme ? hc.theme.surface : "#313244"
        border.width: 1
        border.color: hc.theme ? hc.theme.glassEdge : "transparent"

        GlassShine { radius: hc.radius; dark: hc.theme ? hc.theme.dark : true; strength: 0.6 }
    }

    // Volume row with mute, slider and a device button (output or microphone)
    component AudioRow: RowLayout {
        id: ar
        property var theme: null
        property bool input: false
        readonly property var node: ar.theme ? (ar.input ? ar.theme.source : ar.theme.sink) : null
        readonly property var a: ar.node ? ar.node.audio : null
        spacing: 10

        // mute button
        Rectangle {
            Layout.preferredWidth: 34
            Layout.preferredHeight: 34
            radius: 17
            color: muteMouse.containsMouse && ar.theme ? ar.theme.overlay : (ar.theme ? ar.theme.bg : "#1e1e2e")
            border.width: 1
            border.color: ar.theme ? ar.theme.glassEdge : "transparent"
            scale: muteMouse.pressed ? 0.9 : 1
            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutBack } }

            Text {
                anchors.centerIn: parent
                text: ar.input ? (!ar.a || ar.a.muted ? "\uf131" : "\uf130") : (ar.theme ? ar.theme.volIcon(ar.a) : "")
                color: ar.a && ar.a.muted ? (ar.theme ? ar.theme.danger : "red") : (ar.theme ? ar.theme.accent : "#89b4fa")
                font.family: ar.theme ? ar.theme.iconFont : ""
                font.pixelSize: 14
            }
            MouseArea {
                id: muteMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: if (ar.a) ar.a.muted = !ar.a.muted
            }
        }

        ValueBar {
            theme: ar.theme
            Layout.fillWidth: true
            value: ar.a ? ar.a.volume : 0
            onMoved: v => {
                if (ar.a) ar.a.volume = v;
            }
        }

        Text {
            Layout.preferredWidth: 44
            horizontalAlignment: Text.AlignRight
            text: !ar.a ? "--" : (ar.a.muted ? "Muted" : Math.round(ar.a.volume * 100) + "%")
            color: ar.theme ? ar.theme.fg : "white"
            font.pixelSize: 12
        }

        // which device: click to pick another
        Rectangle {
            Layout.preferredWidth: 200
            Layout.preferredHeight: 32
            radius: 11
            color: devMouse.containsMouse && ar.theme ? ar.theme.overlay : (ar.theme ? ar.theme.bg : "#1e1e2e")
            border.width: 1
            border.color: ar.theme ? ar.theme.glassEdge : "transparent"
            scale: devMouse.pressed ? 0.96 : 1
            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutBack } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 6
                Text {
                    text: ar.input ? "\uf130" : "\uf028"
                    color: ar.theme ? ar.theme.muted : "grey"
                    font.family: ar.theme ? ar.theme.iconFont : ""
                    font.pixelSize: 11
                }
                Text {
                    Layout.fillWidth: true
                    text: ar.theme ? ar.theme.devName(ar.node) : ""
                    color: ar.theme ? ar.theme.fg : "white"
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }
                Text {
                    text: "\uf107"
                    color: ar.theme ? ar.theme.muted : "grey"
                    font.family: ar.theme ? ar.theme.iconFont : ""
                    font.pixelSize: 12
                }
            }
            MouseArea {
                id: devMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: if (ar.theme) ar.theme.devPicker = ar.input ? "in" : "out"
            }
        }
    }

    // One app icon with its name (hub Apps tab)
    component AppTile: Rectangle {
        id: at
        property var theme: null
        property var entry: null
        signal launched()
        width: 92
        height: 96
        radius: 18
        color: atMouse.containsMouse && at.theme ? at.theme.overlay : "transparent"
        scale: atMouse.pressed ? 0.93 : (atMouse.containsMouse ? 1.06 : 1)
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }

        Column {
            anchors.centerIn: parent
            spacing: 6

            IconImage {
                anchors.horizontalCenter: parent.horizontalCenter
                implicitSize: 48
                source: at.entry ? Quickshell.iconPath(at.entry.icon, "application-x-executable") : ""
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 84
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                text: at.entry ? at.entry.name : ""
                color: at.theme ? at.theme.fg : "#cdd6f4"
                font.pixelSize: 11
            }
        }

        MouseArea {
            id: atMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: at.launched()
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: panel
            required property var modelData
            screen: modelData

            anchors {
                top: true
                left: true
                right: true
            }
            implicitHeight: 78           // pill (52) + room for the tab under it
            color: "transparent"
            WlrLayershell.namespace: "quickshell-topbar"

            readonly property bool focusedHere: !Hyprland.focusedMonitor || Hyprland.focusedMonitor.name === modelData.name
            readonly property bool hubHere: root.hubOpen && focusedHere
            onHubHereChanged: if (hubHere) hubKeys.forceActiveFocus()

            // ----- Pull tab -----
            // With auto-hide on, the pill stays tucked away until you click the little tab at the
            // top of the screen (no more popping out when the mouse brushes the edge). Click the
            // tab again to tuck it away. Windows make room while it's out.
            readonly property bool wantHide: root.autoHideOn && !pins.adapter.topPillAlways   // the top pill always shows
            readonly property bool popupOpen: hubHere
            readonly property bool keepOpen: !wantHide || popupOpen || root.topBarOpen
            readonly property bool barShown: keepOpen

            exclusionMode: ExclusionMode.Normal
            exclusiveZone: barShown ? 52 : 0

            // only the pill and the tab catch clicks; the rest passes through to windows
            mask: barShown ? topShownMask : topTabMask
            Region { id: topTabMask; item: topTab }
            Region {
                id: topShownMask
                item: pill
                Region { item: topTab }
            }

            // Pulled out with the tab? Clicking anywhere else (a window, the desktop) tucks it away again
            HyprlandFocusGrab {
                windows: [panel, hubWin]
                active: panel.wantHide && root.topBarOpen && panel.focusedHere
                onCleared: root.topBarOpen = false
            }

            // the tab: hangs from the top edge, rides down under the pill when it's out
            Rectangle {
                id: topTab
                visible: panel.wantHide && !panel.hubHere
                anchors.horizontalCenter: parent.horizontalCenter
                y: panel.barShown ? 50 : -10
                width: topTabMouse.containsMouse ? 74 : 60
                height: 24
                radius: 12
                color: root.popupBg
                border.width: 1
                border.color: root.glassEdge
                Behavior on y { NumberAnimation { duration: root.animMs * 2; easing.type: Easing.OutCubic } }
                Behavior on width { NumberAnimation { duration: root.animMs; easing.type: Easing.OutBack } }

                GlassShine { radius: parent.radius; dark: root.dark }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: panel.barShown ? 3 : 10
                    text: panel.barShown ? "\uf077" : "\uf078"
                    color: root.fg
                    font.family: root.iconFont
                    font.pixelSize: 11
                }

                MouseArea {
                    id: topTabMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.topBarOpen = !root.topBarOpen
                }
            }

            // Desktops on this monitor, the focused app, and today's calendar
            readonly property var desks: root.deskMap[modelData.name] || []
            readonly property var activeWin: ToplevelManager.activeToplevel
            readonly property var calInfo: {
                const now = clock.date;
                const first = new Date(now.getFullYear(), now.getMonth() + root.calOffset, 1);
                const start = new Date(first.getFullYear(), first.getMonth(), 1 - first.getDay());
                const days = [];
                for (let i = 0; i < 42; i++) {
                    const d = new Date(start.getFullYear(), start.getMonth(), start.getDate() + i);
                    days.push({
                        n: d.getDate(),
                        inMonth: d.getMonth() === first.getMonth(),
                        today: d.toDateString() === now.toDateString()
                    });
                }
                return { title: Qt.formatDate(first, "MMMM yyyy"), days: days };
            }

            // ===================== The compact pill =====================
            Rectangle {
                id: pill
                anchors.horizontalCenter: parent.horizontalCenter
                y: panel.barShown ? 6 : -height - 6
                width: pillRow.implicitWidth + 24
                height: 40
                radius: 20
                color: root.popupBg
                border.width: 1
                border.color: root.glassEdge
                opacity: panel.hubHere ? 0 : 1
                scale: pillMouse.pressed ? 0.97 : (pillHover.hovered ? 1.03 : 1)
                Behavior on y { NumberAnimation { duration: root.animMs * 2; easing.type: Easing.OutCubic } }
                Behavior on width { NumberAnimation { duration: root.animMs * 2; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: root.animMs } }
                Behavior on scale { NumberAnimation { duration: root.animMs; easing.type: Easing.OutBack } }

                HoverHandler { id: pillHover }

                GlassShine { radius: parent.radius; dark: root.dark }

                // clicking any empty part of the pill opens the hub
                MouseArea {
                    id: pillMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.openHub(0)
                }

                Row {
                    id: pillRow
                    anchors.centerIn: parent
                    spacing: 12

                    // sticker spot
                    Buddy { theme: root; slot: 0; size: 26; anchors.verticalCenter: parent.verticalCenter }

                    // ---- Now playing (only while something has a player open) ----
                    Rectangle {
                        id: pillMedia
                        visible: !!root.player
                        anchors.verticalCenter: parent.verticalCenter
                        width: pmRow.implicitWidth + 14
                        height: 30
                        radius: 15
                        color: pmHover.hovered ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(1, 1, 1, 0.055)
                        border.width: 1
                        border.color: root.glassEdge
                        Behavior on color { ColorAnimation { duration: root.animMs } }
                        Behavior on width { NumberAnimation { duration: root.animMs * 2; easing.type: Easing.OutCubic } }

                        HoverHandler { id: pmHover }

                        // a soft shine along the top, like the rest of the glass
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 1
                            radius: parent.radius
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.10) }
                                GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0) }
                            }
                        }

                        Row {
                            id: pmRow
                            anchors.verticalCenter: parent.verticalCenter
                            x: 4
                            spacing: 9

                            // album art (rounded) – click art or title to open the full player
                            Item {
                                id: pmArtBox
                                anchors.verticalCenter: parent.verticalCenter
                                width: 22
                                height: 22
                                Rectangle {
                                    anchors.fill: parent
                                    radius: 11
                                    color: root.overlay
                                    Text {
                                        anchors.centerIn: parent
                                        visible: pmArt.status !== Image.Ready
                                        text: ""
                                        color: root.muted
                                        font.family: root.iconFont
                                        font.pixelSize: 10
                                    }
                                }
                                Image {
                                    id: pmArt
                                    anchors.fill: parent
                                    source: root.player ? (root.player.trackArtUrl || "") : ""
                                    sourceSize.width: 64
                                    sourceSize.height: 64
                                    fillMode: Image.PreserveAspectCrop
                                    visible: false
                                    asynchronous: true
                                }
                                Item {
                                    id: pmArtMask
                                    anchors.fill: parent
                                    layer.enabled: true
                                    visible: false
                                    Rectangle { anchors.fill: parent; radius: 11; color: "black" }
                                }
                                MultiEffect {
                                    anchors.fill: parent
                                    source: pmArt
                                    maskEnabled: true
                                    maskSource: pmArtMask
                                    visible: pmArt.status === Image.Ready
                                }
                                // slowly spins like a record while playing
                                RotationAnimation on rotation {
                                    running: !!root.player && root.player.isPlaying && root.animMs > 0
                                    from: 0
                                    to: 360
                                    duration: 12000
                                    loops: Animation.Infinite
                                }
                            }

                            // title, scrolling slowly when it's too long and you point at it
                            Item {
                                id: pmTitleBox
                                anchors.verticalCenter: parent.verticalCenter
                                width: Math.min(pmTitle.implicitWidth, 170)
                                height: 18
                                clip: true
                                Text {
                                    id: pmTitle
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: root.player ? (root.player.trackTitle || root.player.identity || "") : ""
                                    color: root.fg
                                    font.pixelSize: 13
                                    font.bold: true
                                    x: 0
                                    // "…" when it doesn't fit; the full title scrolls by while you point at it
                                    width: pmHover.hovered ? implicitWidth : pmTitleBox.width
                                    elide: pmHover.hovered ? Text.ElideNone : Text.ElideRight
                                    SequentialAnimation on x {
                                        running: pmHover.hovered && pmTitle.implicitWidth > pmTitleBox.width && root.animMs > 0
                                        loops: Animation.Infinite
                                        onStopped: pmTitle.x = 0
                                        PauseAnimation { duration: 600 }
                                        NumberAnimation { to: pmTitleBox.width - pmTitle.implicitWidth; duration: Math.max(1500, (pmTitle.implicitWidth - pmTitleBox.width) * 28) }
                                        PauseAnimation { duration: 900 }
                                        NumberAnimation { to: 0; duration: 500; easing.type: Easing.OutCubic }
                                    }
                                }
                            }

                            // back · play/pause · next
                            Row {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2
                                Repeater {
                                    model: [
                                        { icon: "", act: "prev" },
                                        { icon: root.player && root.player.isPlaying ? "" : "", act: "toggle" },
                                        { icon: "", act: "next" }
                                    ]
                                    delegate: Rectangle {
                                        id: pmBtn
                                        required property var modelData
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: modelData.act === "toggle" ? 26 : 22
                                        height: width
                                        radius: width / 2
                                        color: modelData.act === "toggle" ? (pmBtnMouse.containsMouse ? root.fg : Qt.rgba(1, 1, 1, 0.16))
                                            : (pmBtnMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.14) : "transparent")
                                        scale: pmBtnMouse.pressed ? 0.85 : 1
                                        Behavior on color { ColorAnimation { duration: root.animMs } }
                                        Behavior on scale { NumberAnimation { duration: root.animMs; easing.type: Easing.OutBack } }
                                        Text {
                                            anchors.centerIn: parent
                                            anchors.horizontalCenterOffset: pmBtn.modelData.icon === "" ? 1 : 0
                                            text: pmBtn.modelData.icon
                                            color: pmBtn.modelData.act === "toggle" && pmBtnMouse.containsMouse ? root.bg : root.fg
                                            font.family: root.iconFont
                                            font.pixelSize: pmBtn.modelData.act === "toggle" ? 11 : 10
                                        }
                                        MouseArea {
                                            id: pmBtnMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                const p = root.player;
                                                if (!p) return;
                                                if (pmBtn.modelData.act === "prev" && p.canGoPrevious) p.previous();
                                                else if (pmBtn.modelData.act === "next" && p.canGoNext) p.next();
                                                else if (pmBtn.modelData.act === "toggle" && p.canTogglePlaying) p.togglePlaying();
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // art + title open the big player in the hub
                        MouseArea {
                            x: pmArtBox.x
                            width: pmTitleBox.x + pmTitleBox.width + 6
                            height: parent.height
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.openHub(1)
                        }
                    }

                    Rectangle { visible: !!root.player; anchors.verticalCenter: parent.verticalCenter; width: 4; height: 4; radius: 2; color: root.muted }

                    // ---- CPU and RAM ----
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 10

                        Repeater {
                            model: [
                                { icon: "", value: root.cpuUsage },
                                { icon: "", value: root.memUsage }
                            ]

                            delegate: Row {
                                id: chip
                                required property var modelData
                                spacing: 5

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: chip.modelData.icon
                                    color: root.accent
                                    font.family: root.iconFont
                                    font.pixelSize: 13
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: Math.round(chip.modelData.value * 100) + "%"
                                    color: root.fg
                                    font.pixelSize: 13
                                }
                            }
                        }
                    }

                    // ---- Recording: red dot + time, click to stop (only while recording) ----
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: root.recording
                            width: recRow.implicitWidth + 16
                            height: 24
                            radius: 12
                            color: Qt.rgba(root.danger.r, root.danger.g, root.danger.b, 0.22)
                            border.width: 1
                            border.color: root.danger

                            Row {
                                id: recRow
                                anchors.centerIn: parent
                                spacing: 6
                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 9
                                    height: 9
                                    radius: 4.5
                                    color: root.danger
                                    SequentialAnimation on opacity {
                                        running: root.recording
                                        loops: Animation.Infinite
                                        NumberAnimation { to: 0.25; duration: 600 }
                                        NumberAnimation { to: 1; duration: 600 }
                                    }
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: root.fmt(root.recSeconds)
                                    color: root.fg
                                    font.pixelSize: 12
                                    font.bold: true
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.stopRecording()
                            }
                        }
                }
            }

            // ===================== The hub (grows out of the pill) =====================
            // The hub's window is created once and never destroyed. When the hub is closed it is
            // invisible and every click passes straight through it. (Creating and destroying it on
            // every open/close is what made Quickshell crash.)
            PanelWindow {
                id: hubWin
                screen: panel.screen
                visible: true
                anchors.top: true
                implicitWidth: root.hubW + 40
                implicitHeight: root.hubH + 40
                exclusionMode: ExclusionMode.Ignore
                color: "transparent"
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "quickshell-hub"
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

                // open, or still shrinking back into the pill
                readonly property bool showing: panel.hubHere || hubCard.height > pill.height + 2
                mask: showing ? hubMaskOn : hubMaskOff
                Region { id: hubMaskOn; item: hubCard }
                Region { id: hubMaskOff }

                HyprlandFocusGrab {
                    windows: [hubWin]
                    active: panel.hubHere
                    onCleared: root.hubOpen = false
                }

                Item {
                    id: hubKeys
                    focus: true
                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Escape && root.devPicker !== "") root.devPicker = "";
                        else if (event.key === Qt.Key_Escape) root.hubOpen = false;
                        else if (event.key === Qt.Key_Tab) root.hubTab = (root.hubTab + 1) % 9;
                        else if (event.key === Qt.Key_Backtab) root.hubTab = (root.hubTab + 8) % 9;
                        else return;
                        event.accepted = true;
                    }
                }

                Rectangle {
                    id: hubCard
                    visible: hubWin.showing
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 6
                    width: panel.hubHere ? root.hubW : pill.width
                    height: panel.hubHere ? root.hubH : pill.height
                    radius: panel.hubHere ? 30 : 20
                    color: root.popupBg
                    border.width: 1
                    border.color: root.glassEdge
                    clip: true
                    Behavior on width { NumberAnimation { duration: root.animMs * 2.6; easing.type: Easing.OutBack; easing.overshoot: 0.8 } }
                    Behavior on height { NumberAnimation { duration: root.animMs * 2.6; easing.type: Easing.OutBack; easing.overshoot: 0.8 } }
                    Behavior on radius { NumberAnimation { duration: root.animMs * 2 } }

                    GlassShine { radius: parent.radius; dark: root.dark }
                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        gradient: Gradient {
                            GradientStop { position: 0.6; color: "transparent" }
                            GradientStop { position: 1.0; color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, root.dark ? 0.12 : 0.08) }
                        }
                    }

                    // The contents keep their full size and fade in, so they don't squash while the card grows
                    Item {
                        id: hubContent

                        // ---- Sound device picker (opens over the hub) ----
                        MouseArea {
                            anchors.fill: parent
                            z: 9
                            visible: root.devPicker !== ""
                            onClicked: root.devPicker = ""
                            Rectangle { anchors.fill: parent; radius: 30; color: "#2a000000" }
                        }

                        HubCard {
                            id: devCard
                            theme: root
                            z: 10
                            visible: root.devPicker !== ""
                            anchors.centerIn: parent
                            width: 420
                            height: Math.min(devCol.implicitHeight + 72, 400)
                            color: root.popupBg
                            readonly property var list: root.devPicker === "in" ? root.inputDevices : root.outputDevices
                            readonly property var current: root.devPicker === "in" ? root.source : root.sink

                            MouseArea { anchors.fill: parent }   // keep clicks inside from closing it

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 16
                                spacing: 10

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8
                                    Text {
                                        text: root.devPicker === "in" ? "\uf130" : "\uf028"
                                        color: root.accent
                                        font.family: root.iconFont
                                        font.pixelSize: 15
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        text: root.devPicker === "in" ? "Choose microphone" : "Choose sound output"
                                        color: root.fg
                                        font.pixelSize: 15
                                        font.bold: true
                                    }
                                    Text {
                                        text: "\uf00d"
                                        color: root.muted
                                        font.family: root.iconFont
                                        font.pixelSize: 13
                                        MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor; onClicked: root.devPicker = "" }
                                    }
                                }

                                Flickable {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    contentHeight: devCol.implicitHeight
                                    clip: true
                                    boundsBehavior: Flickable.StopAtBounds

                                    Column {
                                        id: devCol
                                        width: parent.width
                                        spacing: 6

                                        Repeater {
                                            model: devCard.list
                                            delegate: Rectangle {
                                                id: devRow
                                                required property var modelData
                                                readonly property bool isCurrent: devCard.current && devCard.current.id === devRow.modelData.id
                                                width: devCol.width
                                                height: 44
                                                radius: 12
                                                color: devRow.isCurrent ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.22)
                                                    : (devRowMouse.containsMouse ? root.overlay : root.surface)
                                                border.width: devRow.isCurrent ? 1 : 0
                                                border.color: root.accent
                                                Behavior on color { ColorAnimation { duration: root.animMs } }

                                                RowLayout {
                                                    anchors.fill: parent
                                                    anchors.leftMargin: 12
                                                    anchors.rightMargin: 12
                                                    spacing: 10
                                                    Text {
                                                        Layout.preferredWidth: 16
                                                        text: devRow.isCurrent ? "\uf00c" : ""
                                                        color: root.accent
                                                        font.family: root.iconFont
                                                        font.pixelSize: 13
                                                    }
                                                    Text {
                                                        Layout.fillWidth: true
                                                        text: root.devName(devRow.modelData)
                                                        color: root.fg
                                                        font.pixelSize: 13
                                                        font.bold: devRow.isCurrent
                                                        elide: Text.ElideRight
                                                    }
                                                }
                                                MouseArea {
                                                    id: devRowMouse
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: root.setDevice(devRow.modelData)
                                                }
                                            }
                                        }

                                        Text {
                                            visible: devCard.list.length === 0
                                            width: devCol.width
                                            horizontalAlignment: Text.AlignHCenter
                                            text: "No devices found"
                                            color: root.muted
                                            font.pixelSize: 13
                                        }
                                    }
                                }
                            }
                        }
                        width: root.hubW
                        height: root.hubH
                        anchors.horizontalCenter: parent.horizontalCenter
                        opacity: panel.hubHere ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: panel.hubHere ? root.animMs * 3 : root.animMs; easing.type: Easing.OutCubic } }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 20
                            spacing: 14

                            // ---- Header: big clock + tabs ----
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 14

                                Buddy { theme: root; slot: 2; size: 46 }

                                Column {
                                    spacing: 0
                                    Text {
                                        text: Qt.formatDateTime(clock.date, root.timePattern)
                                        color: root.fg
                                        font.pixelSize: 30
                                        font.bold: true
                                    }
                                    Text {
                                        text: Qt.formatDateTime(clock.date, "dddd, MMMM d")
                                        color: root.muted
                                        font.pixelSize: 12
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                Rectangle {
                                    implicitHeight: 42
                                    implicitWidth: tabRow.implicitWidth + 8
                                    radius: 14
                                    color: root.surface
                                    border.width: 1
                                    border.color: root.glassEdge

                                    Row {
                                        id: tabRow
                                        anchors.centerIn: parent
                                        spacing: 3

                                        Repeater {
                                            model: [
                                                { name: "Home", icon: "" },
                                                { name: "Media", icon: "" },
                                                { name: "Apps", icon: "" },
                                                { name: "Calendar", icon: "" },
                                                { name: "Alerts", icon: "" },
                                                { name: "System", icon: "" },
                                                { name: "Capture", icon: "" },
                                                { name: "Sports", icon: "\udb82\udc06" },
                                                { name: "Themes", icon: "\uf53f" }
                                            ]

                                            delegate: Rectangle {
                                                id: htab
                                                required property var modelData
                                                required property int index
                                                readonly property bool current: root.hubTab === htab.index
                                                width: htabRow.implicitWidth + 20
                                                height: 34
                                                radius: 11
                                                Behavior on width { NumberAnimation { duration: root.animMs; easing.type: Easing.OutCubic } }
                                                color: htab.current ? root.accent : (htabMouse.containsMouse ? root.overlay : "transparent")
                                                scale: htabMouse.pressed ? 0.94 : 1
                                                Behavior on color { ColorAnimation { duration: root.animMs } }
                                                Behavior on scale { NumberAnimation { duration: root.animMs; easing.type: Easing.OutBack } }

                                                Row {
                                                    id: htabRow
                                                    anchors.centerIn: parent
                                                    spacing: 6
                                                    Text {
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        text: htab.modelData.icon
                                                        color: htab.current ? root.bg : root.accent
                                                        font.family: root.iconFont
                                                        font.pixelSize: 13
                                                    }
                                                    // the name shows on the open tab (and when you point at one), so all 9 fit
                                                    Text {
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        visible: htab.current || htabMouse.containsMouse
                                                        text: htab.modelData.name
                                                        color: htab.current ? root.bg : root.fg
                                                        font.pixelSize: 12
                                                        font.bold: htab.current
                                                    }
                                                }

                                                MouseArea {
                                                    id: htabMouse
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: root.hubTab = htab.index
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // ---- Pages ----
                            StackLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                currentIndex: root.hubTab

                                // ===== 0: Home =====
                                ColumnLayout {
                                    spacing: 16

                                    // Quick toggles
                                    GridLayout {
                                        Layout.fillWidth: true
                                        columns: 4
                                        rowSpacing: 14
                                        columnSpacing: 14

                                        Repeater {
                                            model: [
                                                {
                                                    icon: "", title: "Wi-Fi",
                                                    sub: !root.wifiOn ? "Off" : (root.netKind === "wifi" ? root.netName : "On"),
                                                    active: root.wifiOn, ok: true,
                                                    run: () => root.run("nmcli radio wifi " + (root.wifiOn ? "off" : "on"))
                                                },
                                                {
                                                    icon: "", title: "Bluetooth",
                                                    sub: root.btState === "none" ? "Not available" : (root.btState === "yes" ? "On" : "Off"),
                                                    active: root.btState === "yes", ok: root.btState !== "none",
                                                    run: () => root.run("bluetoothctl power " + (root.btState === "yes" ? "off" : "on"))
                                                },
                                                {
                                                    icon: "", title: "Do not disturb",
                                                    sub: root.dnd ? "On" : "Off",
                                                    active: root.dnd, ok: true,
                                                    run: () => { root.dnd = !root.dnd; }
                                                },
                                                {
                                                    icon: "", title: "Night light",
                                                    sub: root.nightState === "none" ? "Needs hyprsunset" : (root.nightState === "on" ? "On" : "Off"),
                                                    active: root.nightState === "on", ok: root.nightState !== "none",
                                                    run: () => root.run(root.nightState === "on" ? "pkill -x hyprsunset" : "hyprsunset -t 4000 >/dev/null 2>&1")
                                                },
                                                {
                                                    icon: "", title: "Screenshot", sub: "Area · more in Capture",
                                                    active: false, ok: true,
                                                    run: () => root.takeScreenshot()
                                                },
                                                {
                                                    icon: "", title: "Wallpaper", sub: "Choose one",
                                                    active: false, ok: true,
                                                    run: () => { root.hubOpen = false; root.wallPickerOpen = true; }
                                                },
                                                {
                                                    icon: "\uf11b", title: "Game mode",
                                                    sub: root.gameMode ? "On · max FPS" : "Off",
                                                    active: root.gameMode, ok: true,
                                                    run: () => root.setGameMode(!root.gameMode)
                                                },
                                                {
                                                    icon: "\uf019", title: "Updates",
                                                    sub: root.updRunning ? "Updating…" : root.updChecking ? "Checking…"
                                                        : root.updTotal > 0 ? root.updTotal + " waiting · tap to install"
                                                        : root.updCanCheck ? "Up to date" : "Needs pacman-contrib",
                                                    active: root.updTotal > 0, ok: true,
                                                    run: () => { if (root.updTotal > 0) { root.hubOpen = false; root.runUpdates(); } else root.checkUpdates(); }
                                                }

                                            ]

                                            delegate: HubToggle {
                                                required property var modelData
                                                theme: root
                                                item: modelData
                                                Layout.fillWidth: true
                                                Layout.preferredHeight: 72
                                            }
                                        }
                                    }

                                    // Now playing + stats
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 138
                                        spacing: 12

                                        HubCard {
                                            theme: root
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: root.hubTab = 1
                                            }

                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.margins: 14
                                                spacing: 14
                                                visible: root.player !== null

                                                Rectangle {
                                                    Layout.preferredWidth: 110
                                                    Layout.preferredHeight: 110
                                                    radius: 16
                                                    color: root.overlay
                                                    clip: true
                                                    Image {
                                                        anchors.fill: parent
                                                        source: root.player ? root.player.trackArtUrl : ""
                                                        fillMode: Image.PreserveAspectCrop
                                                        visible: status === Image.Ready
                                                    }
                                                    Text {
                                                        anchors.centerIn: parent
                                                        visible: !root.player || root.player.trackArtUrl === ""
                                                        text: ""
                                                        color: root.muted
                                                        font.family: root.iconFont
                                                        font.pixelSize: 30
                                                    }
                                                }

                                                ColumnLayout {
                                                    Layout.fillWidth: true
                                                    spacing: 3
                                                    Text {
                                                        Layout.fillWidth: true
                                                        text: root.player ? (root.player.trackTitle || root.player.identity) : ""
                                                        color: root.fg
                                                        font.pixelSize: 15
                                                        font.bold: true
                                                        elide: Text.ElideRight
                                                    }
                                                    Text {
                                                        Layout.fillWidth: true
                                                        text: root.player ? root.player.trackArtist : ""
                                                        color: root.muted
                                                        font.pixelSize: 12
                                                        elide: Text.ElideRight
                                                    }
                                                    Item { Layout.fillHeight: true }
                                                    RowLayout {
                                                        spacing: 6
                                                        IconButton {
                                                            theme: root
                                                            label: "|◀"
                                                            dim: !(root.player && root.player.canGoPrevious)
                                                            onClicked: if (root.player && root.player.canGoPrevious) root.player.previous()
                                                        }
                                                        IconButton {
                                                            theme: root
                                                            implicitWidth: 54
                                                            label: root.playing(root.player) ? "❚❚" : "▶"
                                                            dim: !(root.player && root.player.canTogglePlaying)
                                                            onClicked: if (root.player && root.player.canTogglePlaying) root.player.togglePlaying()
                                                        }
                                                        IconButton {
                                                            theme: root
                                                            label: "▶|"
                                                            dim: !(root.player && root.player.canGoNext)
                                                            onClicked: if (root.player && root.player.canGoNext) root.player.next()
                                                        }
                                                    }
                                                }
                                            }

                                            Column {
                                                anchors.centerIn: parent
                                                visible: root.player === null
                                                spacing: 6
                                                Text {
                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                    text: ""
                                                    color: root.muted
                                                    font.family: root.iconFont
                                                    font.pixelSize: 26
                                                }
                                                Text {
                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                    text: "Nothing playing"
                                                    color: root.muted
                                                    font.pixelSize: 13
                                                }
                                            }
                                        }

                                        HubCard {
                                            theme: root
                                            Layout.preferredWidth: 300
                                            Layout.fillHeight: true

                                            ColumnLayout {
                                                anchors.fill: parent
                                                anchors.margins: 14
                                                spacing: 8

                                                Repeater {
                                                    model: [
                                                        { name: "CPU", icon: "", value: root.cpuUsage, extra: root.cpuTemp >= 0 ? root.cpuTemp + "°C" : "", show: true },
                                                        { name: "RAM", icon: "", value: root.memUsage, extra: "", show: true },
                                                        { name: "GPU", icon: "", value: root.gpuUse >= 0 ? root.gpuUse / 100 : 0, extra: root.gpuTemp >= 0 ? root.gpuTemp + "°C" : "", show: root.gpuUse >= 0 }
                                                    ]

                                                    delegate: ColumnLayout {
                                                        id: st
                                                        required property var modelData
                                                        visible: st.modelData.show
                                                        Layout.fillWidth: true
                                                        spacing: 4

                                                        RowLayout {
                                                            Layout.fillWidth: true
                                                            spacing: 7
                                                            Text {
                                                                text: st.modelData.icon
                                                                color: root.accent
                                                                font.family: root.iconFont
                                                                font.pixelSize: 12
                                                            }
                                                            Text {
                                                                Layout.fillWidth: true
                                                                text: st.modelData.name
                                                                color: root.fg
                                                                font.pixelSize: 12
                                                            }
                                                            Text {
                                                                visible: st.modelData.extra !== ""
                                                                text: st.modelData.extra
                                                                color: root.muted
                                                                font.pixelSize: 11
                                                            }
                                                            Text {
                                                                text: Math.round(st.modelData.value * 100) + "%"
                                                                color: root.fg
                                                                font.pixelSize: 12
                                                                font.bold: true
                                                            }
                                                        }
                                                        Rectangle {
                                                            Layout.fillWidth: true
                                                            implicitHeight: 6
                                                            radius: 3
                                                            color: root.overlay
                                                            Rectangle {
                                                                width: parent.width * Math.max(0, Math.min(1, st.modelData.value))
                                                                height: parent.height
                                                                radius: 3
                                                                color: root.accent
                                                                Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                                                            }
                                                        }
                                                    }
                                                }
                                                Item { Layout.fillHeight: true }
                                            }
                                        }
                                    }

                                    // Sound output + microphone
                                    HubCard {
                                        theme: root
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 100

                                        ColumnLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 14
                                            anchors.rightMargin: 14
                                            anchors.topMargin: 10
                                            anchors.bottomMargin: 10
                                            spacing: 8
                                            AudioRow { theme: root; Layout.fillWidth: true; input: false }
                                            AudioRow { theme: root; Layout.fillWidth: true; input: true }
                                        }
                                    }

                                    Item { Layout.fillHeight: true }
                                }

                                // ===== 1: Media =====
                                HubCard {
                                    theme: root
                                    clip: true

                                    NowPlaying {
                                        theme: root
                                        player: root.player
                                        visible: root.player !== null
                                        artSize: 360
                                        wide: true
                                        backdropMargin: 40
                                        anchors.centerIn: parent
                                    }

                                    Column {
                                        anchors.centerIn: parent
                                        visible: root.player === null
                                        spacing: 8
                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: "\uf001"
                                            color: root.muted
                                            font.family: root.iconFont
                                            font.pixelSize: 44
                                        }
                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: "Nothing playing right now"
                                            color: root.muted
                                            font.pixelSize: 14
                                        }
                                    }
                                }

                                // ===== 2: Apps =====
                                ColumnLayout {
                                    spacing: 10

                                    Text {
                                        text: "Pinned"
                                        color: root.fg
                                        font.pixelSize: 14
                                        font.bold: true
                                    }
                                    Flow {
                                        Layout.fillWidth: true
                                        spacing: 6
                                        Repeater {
                                            model: panel.hubHere && root.hubTab === 2 ? root.appsForTab(3, "") : []
                                            delegate: AppTile {
                                                required property var modelData
                                                theme: root
                                                entry: modelData
                                                onLaunched: { root.hubOpen = false; root.launchApp(modelData); }
                                            }
                                        }
                                    }

                                    Text {
                                        text: "Recent"
                                        color: root.fg
                                        font.pixelSize: 14
                                        font.bold: true
                                    }
                                    Flow {
                                        Layout.fillWidth: true
                                        spacing: 6
                                        Repeater {
                                            model: panel.hubHere && root.hubTab === 2 ? root.appsForTab(1, "").slice(0, 8) : []
                                            delegate: AppTile {
                                                required property var modelData
                                                theme: root
                                                entry: modelData
                                                onLaunched: { root.hubOpen = false; root.launchApp(modelData); }
                                            }
                                        }
                                    }

                                    Item { Layout.fillHeight: true }

                                    BarButton {
                                        theme: root
                                        Layout.alignment: Qt.AlignHCenter
                                        icon: ""
                                        label: "All apps"
                                        onClicked: mouse => { root.hubOpen = false; root.launcherOpen = true; }
                                    }
                                }

                                // ===== 3: Calendar =====
                                RowLayout {
                                    spacing: 12

                                    HubCard {
                                        theme: root
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true

                                        ColumnLayout {
                                            anchors.fill: parent
                                            anchors.margins: 16
                                            spacing: 8

                                            RowLayout {
                                                Layout.fillWidth: true
                                                Text {
                                                    Layout.fillWidth: true
                                                    text: panel.calInfo.title
                                                    color: root.fg
                                                    font.pixelSize: 17
                                                    font.bold: true
                                                }
                                                IconButton { theme: root; implicitWidth: 36; implicitHeight: 30; label: "‹"; onClicked: root.calOffset -= 1 }
                                                IconButton { theme: root; implicitWidth: 60; implicitHeight: 30; label: "Today"; onClicked: root.calOffset = 0 }
                                                IconButton { theme: root; implicitWidth: 36; implicitHeight: 30; label: "›"; onClicked: root.calOffset += 1 }
                                            }

                                            GridLayout {
                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                columns: 7
                                                rowSpacing: 4
                                                columnSpacing: 4

                                                Repeater {
                                                    model: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
                                                    delegate: Text {
                                                        required property string modelData
                                                        Layout.fillWidth: true
                                                        Layout.preferredWidth: 1      // equal columns
                                                        horizontalAlignment: Text.AlignHCenter
                                                        text: modelData
                                                        color: root.muted
                                                        font.pixelSize: 11
                                                        font.bold: true
                                                    }
                                                }

                                                Repeater {
                                                    model: panel.calInfo.days
                                                    delegate: Item {
                                                        id: cday
                                                        required property var modelData
                                                        Layout.fillWidth: true
                                                        Layout.fillHeight: true
                                                        Layout.preferredWidth: 1      // equal columns
                                                        Layout.preferredHeight: 1     // equal rows

                                                        HoverHandler { id: cdayHover }

                                                        // round highlight for today (and a soft one on hover)
                                                        Rectangle {
                                                            anchors.centerIn: parent
                                                            width: Math.min(parent.width, parent.height, 38)
                                                            height: width
                                                            radius: width / 2
                                                            color: cday.modelData.today ? root.accent : (cdayHover.hovered ? root.overlay : "transparent")
                                                            Behavior on color { ColorAnimation { duration: root.animMs } }
                                                        }

                                                        Text {
                                                            anchors.centerIn: parent
                                                            text: cday.modelData.n
                                                            color: cday.modelData.today ? root.bg : (cday.modelData.inMonth ? root.fg : root.muted)
                                                            opacity: cday.modelData.inMonth ? 1 : 0.45
                                                            font.pixelSize: 13
                                                            font.bold: cday.modelData.today
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.preferredWidth: 230
                                        Layout.maximumWidth: 230
                                        Layout.fillWidth: false
                                        Layout.fillHeight: true
                                        spacing: 12

                                        HubCard {
                                            theme: root
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 170

                                            Column {
                                                anchors.centerIn: parent
                                                spacing: 2
                                                Text {
                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                    text: Qt.formatDateTime(clock.date, "dddd")
                                                    color: root.accent
                                                    font.pixelSize: 14
                                                    font.bold: true
                                                }
                                                Text {
                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                    text: Qt.formatDateTime(clock.date, "d")
                                                    color: root.fg
                                                    font.pixelSize: 64
                                                    font.bold: true
                                                }
                                                Text {
                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                    text: Qt.formatDateTime(clock.date, "MMMM yyyy")
                                                    color: root.muted
                                                    font.pixelSize: 12
                                                }
                                            }
                                        }

                                        HubCard {
                                            theme: root
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true

                                            ColumnLayout {
                                                anchors.fill: parent
                                                anchors.margins: 16
                                                spacing: 4

                                                Text {
                                                    text: root.weatherName
                                                    color: root.muted
                                                    font.pixelSize: 11
                                                }
                                                RowLayout {
                                                    spacing: 10
                                                    Text {
                                                        text: root.wxNow ? root.wxNow.icon : "☁"
                                                        color: root.accent
                                                        font.pixelSize: 34
                                                    }
                                                    Text {
                                                        text: root.wxNow ? root.wxNow.temp + "°" : "--"
                                                        color: root.fg
                                                        font.pixelSize: 32
                                                        font.bold: true
                                                    }
                                                }
                                                Text {
                                                    Layout.fillWidth: true
                                                    text: root.wxNow ? root.wxNow.desc + "  ·  H " + root.wxNow.hi + "°  L " + root.wxNow.lo + "°" : root.wxStatus
                                                    color: root.muted
                                                    font.pixelSize: 12
                                                    elide: Text.ElideRight
                                                }
                                                Item { Layout.fillHeight: true }
                                                BarButton {
                                                    theme: root
                                                    Layout.fillWidth: true
                                                    icon: ""
                                                    label: "Full forecast"
                                                    onClicked: mouse => { root.hubOpen = false; root.weatherOpen = true; }
                                                }
                                            }
                                        }
                                    }
                                }

                                // ===== 4: Alerts =====
                                ColumnLayout {
                                    spacing: 10

                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text {
                                            Layout.fillWidth: true
                                            text: notifServer.trackedNotifications.values.length > 0
                                                ? notifServer.trackedNotifications.values.length + " notifications" : "Notifications"
                                            color: root.fg
                                            font.pixelSize: 15
                                            font.bold: true
                                        }
                                        BarButton {
                                            theme: root
                                            icon: ""
                                            label: root.dnd ? "Do not disturb: on" : "Do not disturb: off"
                                            active: root.dnd
                                            onClicked: mouse => { root.dnd = !root.dnd; }
                                        }
                                        BarButton {
                                            theme: root
                                            icon: ""
                                            label: "Clear all"
                                            onClicked: mouse => root.clearNotifications()
                                        }
                                    }

                                    Item {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true

                                        ListView {
                                            id: hubNotifs
                                            anchors.fill: parent
                                            clip: true
                                            spacing: 8
                                            model: notifServer.trackedNotifications

                                            delegate: HubCard {
                                                id: hn
                                                required property var modelData
                                                theme: root
                                                width: hubNotifs.width
                                                height: hnCol.implicitHeight + 24
                                                border.color: hn.modelData.urgency === NotificationUrgency.Critical ? root.danger : root.glassEdge
                                                color: hnOpen.containsMouse ? root.overlay : root.surface

                                                // click anywhere on it: open the app it came from
                                                MouseArea {
                                                    id: hnOpen
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: root.openNotification(hn.modelData)
                                                }

                                                ColumnLayout {
                                                    id: hnCol
                                                    anchors.fill: parent
                                                    anchors.margins: 12
                                                    spacing: 3

                                                    RowLayout {
                                                        Layout.fillWidth: true
                                                        Text {
                                                            Layout.fillWidth: true
                                                            text: hn.modelData.appName
                                                            color: root.accent
                                                            font.pixelSize: 11
                                                            font.bold: true
                                                            elide: Text.ElideRight
                                                        }
                                                        Text {
                                                            text: ""
                                                            color: root.muted
                                                            font.family: root.iconFont
                                                            font.pixelSize: 12
                                                            MouseArea {
                                                                anchors.fill: parent
                                                                anchors.margins: -6
                                                                cursorShape: Qt.PointingHandCursor
                                                                onClicked: hn.modelData.dismiss()
                                                            }
                                                        }
                                                    }
                                                    Text {
                                                        Layout.fillWidth: true
                                                        text: hn.modelData.summary
                                                        color: root.fg
                                                        font.pixelSize: 13
                                                        font.bold: true
                                                        wrapMode: Text.Wrap
                                                    }
                                                    Text {
                                                        Layout.fillWidth: true
                                                        visible: text !== ""
                                                        text: hn.modelData.body
                                                        color: root.muted
                                                        font.pixelSize: 12
                                                        wrapMode: Text.Wrap
                                                        maximumLineCount: 3
                                                        elide: Text.ElideRight
                                                    }
                                                }
                                            }
                                        }

                                        Column {
                                            anchors.centerIn: parent
                                            visible: hubNotifs.count === 0
                                            spacing: 8
                                            Text {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                text: ""
                                                color: root.muted
                                                font.family: root.iconFont
                                                font.pixelSize: 40
                                            }
                                            Text {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                text: "You're all caught up"
                                                color: root.muted
                                                font.pixelSize: 14
                                            }
                                        }
                                    }
                                }

                                // ===== 5: System =====
                                ColumnLayout {
                                    spacing: 12

                                    // settings you set once
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 14
                                        Repeater {
                                            model: [
                                                    {
                                                    icon: "", title: "Theme",
                                                    sub: root.themeLabel(),
                                                    active: false, ok: true,
                                                    run: () => { root.hubTab = 8; }
                                                    },
                                                    {
                                                    icon: "", title: "Auto-hide bars",
                                                    sub: root.autoHideOn ? "On" : "Off",
                                                    active: root.autoHideOn, ok: true,
                                                    run: () => root.cycleAutoHide()
                                                    },
                                                    {
                                                    icon: "\uf0e2", title: "Reopen apps",
                                                    sub: pins.adapter.restoreSession ? "On · after restart" : "Off",
                                                    active: pins.adapter.restoreSession, ok: true,
                                                    run: () => { pins.adapter.restoreSession = !pins.adapter.restoreSession; }
                                                    }
                                            ]
                                            delegate: HubToggle {
                                                required property var modelData
                                                theme: root
                                                item: modelData
                                                Layout.fillWidth: true
                                                Layout.preferredHeight: 72
                                            }
                                        }
                                    }

                                    HubCard {
                                        theme: root
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true

                                        ColumnLayout {
                                            anchors.fill: parent
                                            anchors.margins: 16
                                            spacing: 10

                                            Text {
                                                text: "Sound output and microphone"
                                                color: root.fg
                                                font.pixelSize: 13
                                                font.bold: true
                                            }
                                            AudioRow { theme: root; Layout.fillWidth: true; input: false }
                                            AudioRow { theme: root; Layout.fillWidth: true; input: true }

                                            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: root.overlay }

                                            Text {
                                                text: root.audioStreams.length > 0 ? "Apps" : "No apps are playing audio"
                                                color: root.muted
                                                font.pixelSize: 11
                                            }

                                            ListView {
                                                id: hubStreams
                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                clip: true
                                                spacing: 8
                                                model: root.audioStreams

                                                delegate: RowLayout {
                                                    id: hs
                                                    required property var modelData
                                                    width: hubStreams.width
                                                    spacing: 10
                                                    Text {
                                                        Layout.preferredWidth: 110
                                                        text: (hs.modelData.properties && hs.modelData.properties["application.name"])
                                                            || hs.modelData.description || hs.modelData.name
                                                        color: root.fg
                                                        font.pixelSize: 12
                                                        elide: Text.ElideRight
                                                    }
                                                    ValueBar {
                                                        theme: root
                                                        Layout.fillWidth: true
                                                        value: hs.modelData.audio ? hs.modelData.audio.volume : 0
                                                        onMoved: v => {
                                                            if (hs.modelData.audio) hs.modelData.audio.volume = v;
                                                        }
                                                    }
                                                    Item { Layout.preferredWidth: 70 }
                                                }
                                            }
                                        }
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 8
                                        BarButton { theme: root; Layout.fillWidth: true; icon: ""; label: "Lock"
                                            onClicked: mouse => { root.hubOpen = false; Quickshell.execDetached(["sh", "-c", "hyprlock || loginctl lock-session"]); } }
                                        BarButton { theme: root; Layout.fillWidth: true; icon: ""; label: "Sleep"
                                            onClicked: mouse => { root.hubOpen = false; Quickshell.execDetached(["systemctl", "suspend"]); } }
                                        BarButton { theme: root; Layout.fillWidth: true; icon: ""; label: "Reload Hyprland"
                                            onClicked: mouse => { root.hubOpen = false; Quickshell.execDetached(["hyprctl", "reload"]); } }
                                        BarButton { theme: root; Layout.fillWidth: true; icon: ""; label: "Restart bar"
                                            onClicked: mouse => Quickshell.reload(true) }
                                        BarButton { theme: root; Layout.fillWidth: true; icon: ""; label: "Config"
                                            onClicked: mouse => { root.hubOpen = false; Quickshell.execDetached(["xdg-open", Quickshell.env("HOME") + "/.config"]); } }
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 8
                                        ConfirmButton {
                                            theme: root
                                            Layout.fillWidth: true
                                            label: "Log out"
                                            onConfirmed: root.powerAction("logout")
                                        }
                                        ConfirmButton {
                                            theme: root
                                            Layout.fillWidth: true
                                            label: "Reboot"
                                            onConfirmed: root.powerAction("reboot")
                                        }
                                        ConfirmButton {
                                            theme: root
                                            Layout.fillWidth: true
                                            label: "Shut down"
                                            onConfirmed: root.powerAction("poweroff")
                                        }
                                    }
                                }

                                // ===== 6: Capture =====
                                ColumnLayout {
                                    spacing: 12

                                    RowLayout {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        spacing: 12

                                        // ---- Screenshot ----
                                        HubCard {
                                            theme: root
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            Layout.preferredWidth: 1

                                            ColumnLayout {
                                                anchors.fill: parent
                                                anchors.margins: 16
                                                spacing: 12

                                                RowLayout {
                                                    spacing: 8
                                                    Text { text: "\uf030"; color: root.accent; font.family: root.iconFont; font.pixelSize: 15 }
                                                    Text { text: "Screenshot"; color: root.fg; font.pixelSize: 15; font.bold: true }
                                                }

                                                GridLayout {
                                                    Layout.fillWidth: true
                                                    columns: 2
                                                    rowSpacing: 10
                                                    columnSpacing: 10

                                                    Repeater {
                                                        model: [
                                                            { icon: "\uf125", title: "Area", sub: "Drag a box", mode: "area" },
                                                            { icon: "\uf2d0", title: "Window", sub: "Click a window", mode: "window" },
                                                            { icon: "\uf108", title: "This screen", sub: "The monitor you're on", mode: "screen" },
                                                            { icon: "\uf26c", title: "All screens", sub: "Every monitor", mode: "all" }
                                                        ]
                                                        delegate: Rectangle {
                                                            id: cap
                                                            required property var modelData
                                                            Layout.fillWidth: true
                                                            Layout.preferredWidth: 1
                                                            Layout.preferredHeight: 74
                                                            radius: 18
                                                            color: capMouse.containsMouse ? root.overlay : root.bg
                                                            border.width: 1
                                                            border.color: root.glassEdge
                                                            scale: capMouse.pressed ? 0.95 : (capMouse.containsMouse ? 1.03 : 1)
                                                            Behavior on color { ColorAnimation { duration: root.animMs } }
                                                            Behavior on scale { NumberAnimation { duration: root.animMs; easing.type: Easing.OutBack } }

                                                            RowLayout {
                                                                anchors.fill: parent
                                                                anchors.margins: 12
                                                                spacing: 10
                                                                Rectangle {
                                                                    Layout.preferredWidth: 40
                                                                    Layout.preferredHeight: 40
                                                                    radius: 20
                                                                    color: root.overlay
                                                                    Text { anchors.centerIn: parent; text: cap.modelData.icon; color: root.accent; font.family: root.iconFont; font.pixelSize: 16 }
                                                                }
                                                                ColumnLayout {
                                                                    Layout.fillWidth: true
                                                                    spacing: 1
                                                                    Text { Layout.fillWidth: true; text: cap.modelData.title; color: root.fg; font.pixelSize: 13; font.bold: true; elide: Text.ElideRight }
                                                                    Text { Layout.fillWidth: true; text: cap.modelData.sub; color: root.muted; font.pixelSize: 11; elide: Text.ElideRight }
                                                                }
                                                            }
                                                            MouseArea {
                                                                id: capMouse
                                                                anchors.fill: parent
                                                                hoverEnabled: true
                                                                cursorShape: Qt.PointingHandCursor
                                                                onClicked: root.shot(cap.modelData.mode)
                                                            }
                                                        }
                                                    }
                                                }

                                                // delay
                                                RowLayout {
                                                    Layout.fillWidth: true
                                                    spacing: 8
                                                    Text { text: "Delay"; color: root.muted; font.pixelSize: 12 }
                                                    Item { Layout.fillWidth: true }
                                                    Repeater {
                                                        model: [0, 3, 5, 10]
                                                        delegate: Rectangle {
                                                            id: dly
                                                            required property int modelData
                                                            readonly property bool on: root.shotDelay === dly.modelData
                                                            width: 52
                                                            height: 30
                                                            radius: 10
                                                            color: dly.on ? root.accent : (dlyMouse.containsMouse ? root.overlay : root.bg)
                                                            border.width: 1
                                                            border.color: root.glassEdge
                                                            Behavior on color { ColorAnimation { duration: root.animMs } }
                                                            Text { anchors.centerIn: parent; text: dly.modelData === 0 ? "Now" : dly.modelData + "s"; color: dly.on ? root.bg : root.fg; font.pixelSize: 12; font.bold: dly.on }
                                                            MouseArea { id: dlyMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.shotDelay = dly.modelData }
                                                        }
                                                    }
                                                }
                                                Item { Layout.fillHeight: true }
                                            }
                                        }

                                        // ---- Screen recording ----
                                        HubCard {
                                            theme: root
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            Layout.preferredWidth: 1

                                            ColumnLayout {
                                                anchors.fill: parent
                                                anchors.margins: 16
                                                spacing: 12

                                                RowLayout {
                                                    spacing: 8
                                                    Text { text: "\uf03d"; color: root.recording ? root.danger : root.accent; font.family: root.iconFont; font.pixelSize: 15 }
                                                    Text { text: "Screen recording"; color: root.fg; font.pixelSize: 15; font.bold: true }
                                                }

                                                // not installed
                                                ColumnLayout {
                                                    visible: !root.canRecord
                                                    Layout.fillWidth: true
                                                    Layout.fillHeight: true
                                                    spacing: 6
                                                    Item { Layout.fillHeight: true }
                                                    Text {
                                                        Layout.fillWidth: true
                                                        horizontalAlignment: Text.AlignHCenter
                                                        wrapMode: Text.Wrap
                                                        text: "Recording needs wf-recorder.\nInstall it in a terminal with:"
                                                        color: root.muted
                                                        font.pixelSize: 13
                                                    }
                                                    Text {
                                                        Layout.alignment: Qt.AlignHCenter
                                                        text: "sudo pacman -S wf-recorder"
                                                        color: root.accent
                                                        font.pixelSize: 13
                                                        font.family: "monospace"
                                                    }
                                                    Item { Layout.fillHeight: true }
                                                }

                                                // recording now
                                                ColumnLayout {
                                                    visible: root.canRecord && root.recording
                                                    Layout.fillWidth: true
                                                    Layout.fillHeight: true
                                                    spacing: 10
                                                    Item { Layout.fillHeight: true }
                                                    Rectangle {
                                                        Layout.alignment: Qt.AlignHCenter
                                                        width: 22
                                                        height: 22
                                                        radius: 11
                                                        color: root.danger
                                                        SequentialAnimation on opacity {
                                                            running: root.recording
                                                            loops: Animation.Infinite
                                                            NumberAnimation { to: 0.3; duration: 700 }
                                                            NumberAnimation { to: 1; duration: 700 }
                                                        }
                                                    }
                                                    Text {
                                                        Layout.alignment: Qt.AlignHCenter
                                                        text: root.fmt(root.recSeconds)
                                                        color: root.fg
                                                        font.pixelSize: 34
                                                        font.bold: true
                                                    }
                                                    BarButton {
                                                        theme: root
                                                        Layout.alignment: Qt.AlignHCenter
                                                        icon: "\uf04d"
                                                        label: "Stop recording"
                                                        onClicked: mouse => root.stopRecording()
                                                    }
                                                    Item { Layout.fillHeight: true }
                                                }

                                                // ready to record
                                                ColumnLayout {
                                                    visible: root.canRecord && !root.recording
                                                    Layout.fillWidth: true
                                                    Layout.fillHeight: true
                                                    spacing: 10

                                                    Repeater {
                                                        model: [
                                                            { icon: "\uf125", title: "Record an area", sub: "Drag a box, then it starts", mode: "area" },
                                                            { icon: "\uf108", title: "Record this screen", sub: "The monitor you're on", mode: "screen" }
                                                        ]
                                                        delegate: Rectangle {
                                                            id: rcap
                                                            required property var modelData
                                                            Layout.fillWidth: true
                                                            Layout.preferredHeight: 64
                                                            radius: 18
                                                            color: rcapMouse.containsMouse ? root.overlay : root.bg
                                                            border.width: 1
                                                            border.color: root.glassEdge
                                                            scale: rcapMouse.pressed ? 0.95 : (rcapMouse.containsMouse ? 1.02 : 1)
                                                            Behavior on color { ColorAnimation { duration: root.animMs } }
                                                            Behavior on scale { NumberAnimation { duration: root.animMs; easing.type: Easing.OutBack } }

                                                            RowLayout {
                                                                anchors.fill: parent
                                                                anchors.margins: 12
                                                                spacing: 10
                                                                Rectangle {
                                                                    Layout.preferredWidth: 40
                                                                    Layout.preferredHeight: 40
                                                                    radius: 20
                                                                    color: Qt.rgba(root.danger.r, root.danger.g, root.danger.b, 0.18)
                                                                    Text { anchors.centerIn: parent; text: rcap.modelData.icon; color: root.danger; font.family: root.iconFont; font.pixelSize: 16 }
                                                                }
                                                                ColumnLayout {
                                                                    Layout.fillWidth: true
                                                                    spacing: 1
                                                                    Text { Layout.fillWidth: true; text: rcap.modelData.title; color: root.fg; font.pixelSize: 13; font.bold: true; elide: Text.ElideRight }
                                                                    Text { Layout.fillWidth: true; text: rcap.modelData.sub; color: root.muted; font.pixelSize: 11; elide: Text.ElideRight }
                                                                }
                                                            }
                                                            MouseArea {
                                                                id: rcapMouse
                                                                anchors.fill: parent
                                                                hoverEnabled: true
                                                                cursorShape: Qt.PointingHandCursor
                                                                onClicked: root.record(rcap.modelData.mode)
                                                            }
                                                        }
                                                    }

                                                    // sound
                                                    RowLayout {
                                                        Layout.fillWidth: true
                                                        spacing: 8
                                                        Text { text: "Sound"; color: root.muted; font.pixelSize: 12 }
                                                        Item { Layout.fillWidth: true }
                                                        Repeater {
                                                            model: [
                                                                { key: "none", name: "None" },
                                                                { key: "system", name: "Computer" },
                                                                { key: "mic", name: "Mic" }
                                                            ]
                                                            delegate: Rectangle {
                                                                id: aud
                                                                required property var modelData
                                                                readonly property bool on: root.recAudio === aud.modelData.key
                                                                width: audText.implicitWidth + 22
                                                                height: 30
                                                                radius: 10
                                                                color: aud.on ? root.accent : (audMouse.containsMouse ? root.overlay : root.bg)
                                                                border.width: 1
                                                                border.color: root.glassEdge
                                                                Behavior on color { ColorAnimation { duration: root.animMs } }
                                                                Text { id: audText; anchors.centerIn: parent; text: aud.modelData.name; color: aud.on ? root.bg : root.fg; font.pixelSize: 12; font.bold: aud.on }
                                                                MouseArea { id: audMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.recAudio = aud.modelData.key }
                                                            }
                                                        }
                                                    }
                                                    Item { Layout.fillHeight: true }
                                                }
                                            }
                                        }
                                    }

                                    // ---- Recent screenshots ----
                                    HubCard {
                                        theme: root
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 128

                                        FolderListModel {
                                            id: recentShots
                                            folder: "file://" + Quickshell.env("HOME") + "/Pictures/Screenshots"
                                            nameFilters: ["*.png", "*.jpg"]
                                            showDirs: false
                                            sortField: FolderListModel.Time
                                        }

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.margins: 12
                                            spacing: 10

                                            ListView {
                                                id: shotStrip
                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                orientation: ListView.Horizontal
                                                spacing: 8
                                                clip: true
                                                model: recentShots
                                                delegate: Rectangle {
                                                    id: rs
                                                    required property url fileUrl
                                                    required property int index
                                                    visible: rs.index < 8
                                                    width: visible ? 170 : 0
                                                    height: shotStrip.height
                                                    radius: 12
                                                    color: root.overlay
                                                    border.width: rsMouse.containsMouse ? 2 : 0
                                                    border.color: root.accent
                                                    Image {
                                                        anchors.fill: parent
                                                        anchors.margins: 3
                                                        source: rs.fileUrl
                                                        asynchronous: true
                                                        fillMode: Image.PreserveAspectCrop
                                                        sourceSize.width: 340
                                                    }
                                                    MouseArea {
                                                        id: rsMouse
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: { root.hubOpen = false; Quickshell.execDetached(["xdg-open", rs.fileUrl.toString()]); }
                                                    }
                                                }

                                                Text {
                                                    anchors.centerIn: parent
                                                    visible: recentShots.count === 0
                                                    text: "Your screenshots will show up here"
                                                    color: root.muted
                                                    font.pixelSize: 12
                                                }
                                            }

                                            ColumnLayout {
                                                Layout.preferredWidth: 150
                                                Layout.maximumWidth: 150
                                                Layout.fillWidth: false
                                                spacing: 8
                                                BarButton {
                                                    theme: root
                                                    Layout.fillWidth: true
                                                    icon: "\uf07b"
                                                    label: "Screenshots"
                                                    onClicked: mouse => { root.hubOpen = false; Quickshell.execDetached(["sh", "-c", "mkdir -p \"$HOME/Pictures/Screenshots\" && xdg-open \"$HOME/Pictures/Screenshots\""]); }
                                                }
                                                BarButton {
                                                    theme: root
                                                    Layout.fillWidth: true
                                                    icon: "\uf07b"
                                                    label: "Recordings"
                                                    onClicked: mouse => { root.hubOpen = false; Quickshell.execDetached(["sh", "-c", "mkdir -p \"$HOME/Videos/Recordings\" && xdg-open \"$HOME/Videos/Recordings\""]); }
                                                }
                                            }
                                        }
                                    }
                                }

                                // ===== 7: Sports =====
                                ColumnLayout {
                                    spacing: 10

                                    // ---- top row: pages, favourite team, leagues, refresh ----
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 6

                                        Repeater {
                                            model: [
                                                { id: "games", name: "Games", icon: "" },
                                                { id: "standings", name: "Standings", icon: "" },
                                                { id: "teams", name: "Teams", icon: "" }
                                            ]
                                            delegate: SportChip {
                                                required property var modelData
                                                theme: root
                                                icon: modelData.icon
                                                label: modelData.name
                                                active: root.sportsView === modelData.id
                                                onClicked: root.sportsShow(modelData.id)
                                            }
                                        }

                                        SportChip {
                                            visible: root.sportsFavId !== ""
                                            theme: root
                                            icon: ""
                                            label: root.sportsFavAbbr
                                            active: root.sportsView === "team" && root.sportsTeam !== null && root.sportsTeam.id === root.sportsFavId
                                            onClicked: root.sportsOpenTeam(root.sportsFavId)
                                        }

                                        Item { Layout.fillWidth: true }

                                        Repeater {
                                            model: root.sportsLeagues
                                            delegate: SportChip {
                                                required property var modelData
                                                theme: root
                                                label: modelData.name
                                                active: root.sportsLeague === modelData.id
                                                onClicked: root.sportsSetLeague(modelData.id)
                                            }
                                        }

                                        SportChip {
                                            id: sportsRefreshBtn
                                            theme: root
                                            icon: ""
                                            onClicked: root.sportsRefresh()
                                            RotationAnimation {
                                                target: sportsRefreshBtn
                                                running: root.sportsLoading
                                                from: 0
                                                to: 360
                                                duration: 900
                                                loops: Animation.Infinite
                                                onStopped: sportsRefreshBtn.rotation = 0
                                            }
                                        }
                                    }

                                    // ---- the page for the chosen view ----
                                    StackLayout {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        currentIndex: ["games", "standings", "teams", "team", "player", "game"].indexOf(root.sportsView)

                                        // =========== Games ===========
                                        ColumnLayout {
                                            spacing: 8

                                            RowLayout {
                                                Layout.fillWidth: true
                                                spacing: 6
                                                SportChip { theme: root; icon: ""; onClicked: root.sportsDay -= 1 }
                                                Text {
                                                    Layout.fillWidth: true
                                                    horizontalAlignment: Text.AlignHCenter
                                                    text: root.sportsDayLabel
                                                    color: root.fg
                                                    font.pixelSize: 15
                                                    font.bold: true
                                                }
                                                SportChip { theme: root; label: "Today"; visible: root.sportsDay !== 0; onClicked: root.sportsDay = 0 }
                                                SportChip { theme: root; icon: ""; onClicked: root.sportsDay += 1 }
                                            }

                                            Item {
                                                Layout.fillWidth: true
                                                Layout.fillHeight: true

                                                GridView {
                                                    id: gamesGrid
                                                    anchors.fill: parent
                                                    clip: true
                                                    cellWidth: Math.floor(width / 2)
                                                    cellHeight: 122
                                                    boundsBehavior: Flickable.StopAtBounds
                                                    model: root.sportsGames

                                                    delegate: Item {
                                                        id: gameCard
                                                        required property var modelData
                                                        readonly property var g: modelData
                                                        readonly property bool live: g.state === "in"
                                                        readonly property bool fav: root.sportsFavId !== "" && (g.home.id === root.sportsFavId || g.away.id === root.sportsFavId)
                                                        width: gamesGrid.cellWidth
                                                        height: gamesGrid.cellHeight

                                                        HubCard {
                                                            theme: root
                                                            anchors.fill: parent
                                                            anchors.margins: 5
                                                            radius: 16
                                                            border.color: gameCard.fav ? root.accent : root.glassEdge
                                                            color: gameOpen.containsMouse ? root.overlay : root.surface

                                                            // click the card: live box score (team names still open the team)
                                                            MouseArea {
                                                                id: gameOpen
                                                                anchors.fill: parent
                                                                hoverEnabled: true
                                                                cursorShape: Qt.PointingHandCursor
                                                                onClicked: root.sportsOpenGame(gameCard.g)
                                                            }

                                                            ColumnLayout {
                                                                anchors.fill: parent
                                                                anchors.leftMargin: 14
                                                                anchors.rightMargin: 14
                                                                anchors.topMargin: 10
                                                                anchors.bottomMargin: 10
                                                                spacing: 2

                                                                Repeater {
                                                                    model: [gameCard.g.away, gameCard.g.home]
                                                                    delegate: Item {
                                                                        id: gt
                                                                        required property var modelData
                                                                        readonly property bool lost: gameCard.g.state === "post" && !modelData.winner
                                                                        Layout.fillWidth: true
                                                                        Layout.preferredHeight: 32

                                                                        RowLayout {
                                                                            anchors.fill: parent
                                                                            spacing: 10
                                                                            TeamLogo {
                                                                                theme: root
                                                                                Layout.preferredWidth: 28
                                                                                Layout.preferredHeight: 28
                                                                                source: gt.modelData.logo
                                                                                abbr: gt.modelData.abbr
                                                                            }
                                                                            Text {
                                                                                text: gt.modelData.name
                                                                                color: gt.lost ? root.muted : root.fg
                                                                                font.pixelSize: 14
                                                                                font.bold: !gt.lost
                                                                                elide: Text.ElideRight
                                                                                Layout.maximumWidth: 170
                                                                            }
                                                                            Text {
                                                                                text: gt.modelData.record
                                                                                color: root.muted
                                                                                font.pixelSize: 11
                                                                            }
                                                                            Item { Layout.fillWidth: true }
                                                                            Text {
                                                                                text: gt.modelData.score
                                                                                color: gt.lost ? root.muted : root.fg
                                                                                font.pixelSize: 20
                                                                                font.bold: true
                                                                            }
                                                                        }
                                                                        MouseArea {
                                                                            anchors.fill: parent
                                                                            cursorShape: Qt.PointingHandCursor
                                                                            onClicked: root.sportsOpenTeam(gt.modelData.id)
                                                                        }
                                                                    }
                                                                }

                                                                // status line
                                                                RowLayout {
                                                                    Layout.fillWidth: true
                                                                    Layout.topMargin: 4
                                                                    spacing: 6
                                                                    Rectangle {
                                                                        visible: gameCard.live
                                                                        Layout.preferredWidth: 8
                                                                        Layout.preferredHeight: 8
                                                                        radius: 4
                                                                        color: root.danger
                                                                        SequentialAnimation on opacity {
                                                                            running: gameCard.live && root.sportsVisible
                                                                            loops: Animation.Infinite
                                                                            NumberAnimation { to: 0.25; duration: 700 }
                                                                            NumberAnimation { to: 1; duration: 700 }
                                                                        }
                                                                    }
                                                                    Text {
                                                                        text: gameCard.g.state === "pre" ? root.sportsTime(gameCard.g.date) : gameCard.g.detail
                                                                        color: gameCard.live ? root.danger : root.muted
                                                                        font.pixelSize: 12
                                                                        font.bold: gameCard.live
                                                                    }
                                                                    Item { Layout.fillWidth: true }
                                                                    Text {
                                                                        text: gameCard.g.tv
                                                                        color: root.muted
                                                                        font.pixelSize: 11
                                                                        elide: Text.ElideRight
                                                                        Layout.maximumWidth: 180
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                }

                                                Column {
                                                    anchors.centerIn: parent
                                                    spacing: 8
                                                    visible: root.sportsGames.length === 0
                                                    Text {
                                                        anchors.horizontalCenter: parent.horizontalCenter
                                                        text: "󰠆"
                                                        color: root.muted
                                                        font.family: root.iconFont
                                                        font.pixelSize: 40
                                                    }
                                                    Text {
                                                        anchors.horizontalCenter: parent.horizontalCenter
                                                        text: root.sportsLoading ? "Loading games…" : (root.sportsStatus || "No games on this day")
                                                        color: root.muted
                                                        font.pixelSize: 14
                                                    }
                                                }
                                            }
                                        }

                                        // =========== Standings ===========
                                        ColumnLayout {
                                            spacing: 8

                                            ListView {
                                                Layout.fillWidth: true
                                                Layout.preferredHeight: 32
                                                orientation: ListView.Horizontal
                                                spacing: 6
                                                clip: true
                                                boundsBehavior: Flickable.StopAtBounds
                                                model: root.sportsConfs
                                                delegate: SportChip {
                                                    required property var modelData
                                                    required property int index
                                                    theme: root
                                                    label: modelData.name
                                                    active: root.sportsConf === index
                                                    onClicked: root.sportsConf = index
                                                }
                                            }

                                            HubCard {
                                                theme: root
                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                clip: true

                                                ColumnLayout {
                                                    anchors.fill: parent
                                                    anchors.margins: 12
                                                    spacing: 4

                                                    // column headings (same widths as the rows below)
                                                    RowLayout {
                                                        Layout.fillWidth: true
                                                        Layout.leftMargin: 8
                                                        Layout.rightMargin: 8
                                                        spacing: 0
                                                        Repeater {
                                                            model: [
                                                                { t: "#", w: 34, a: Text.AlignLeft },
                                                                { t: "Team", w: -1, a: Text.AlignLeft },
                                                                { t: "W", w: 52, a: Text.AlignRight },
                                                                { t: "L", w: 52, a: Text.AlignRight },
                                                                { t: "PCT", w: 64, a: Text.AlignRight },
                                                                { t: "GB", w: 56, a: Text.AlignRight },
                                                                { t: "STRK", w: 64, a: Text.AlignRight },
                                                                { t: "L10", w: 64, a: Text.AlignRight }
                                                            ]
                                                            delegate: Text {
                                                                required property var modelData
                                                                Layout.preferredWidth: modelData.w > 0 ? modelData.w : -1
                                                                Layout.fillWidth: modelData.w < 0
                                                                horizontalAlignment: modelData.a
                                                                text: modelData.t
                                                                color: root.muted
                                                                font.pixelSize: 11
                                                                font.bold: true
                                                            }
                                                        }
                                                    }

                                                    ListView {
                                                        id: standList
                                                        Layout.fillWidth: true
                                                        Layout.fillHeight: true
                                                        clip: true
                                                        boundsBehavior: Flickable.StopAtBounds
                                                        model: root.sportsConfs.length > root.sportsConf ? root.sportsConfs[root.sportsConf].rows : []

                                                        delegate: Rectangle {
                                                            id: sr
                                                            required property var modelData
                                                            required property int index
                                                            readonly property bool fav: modelData.id === root.sportsFavId
                                                            width: standList.width
                                                            height: 38
                                                            radius: 10
                                                            color: srMouse.containsMouse ? root.overlay : (sr.index % 2 === 0 ? Qt.rgba(1, 1, 1, 0.04) : "transparent")
                                                            border.width: sr.fav ? 1 : 0
                                                            border.color: root.accent

                                                            // NBA: line under 6th (playoffs) and 10th (play-in)
                                                            Rectangle {
                                                                visible: root.sportsLeague === "nba" && (sr.index === 5 || sr.index === 9)
                                                                anchors.bottom: parent.bottom
                                                                anchors.left: parent.left
                                                                anchors.right: parent.right
                                                                anchors.leftMargin: 8
                                                                anchors.rightMargin: 8
                                                                height: 1
                                                                color: root.glassEdge
                                                            }

                                                            RowLayout {
                                                                anchors.fill: parent
                                                                anchors.leftMargin: 8
                                                                anchors.rightMargin: 8
                                                                spacing: 0
                                                                Text { Layout.preferredWidth: 34; text: sr.index + 1; color: root.muted; font.pixelSize: 13 }
                                                                RowLayout {
                                                                    Layout.fillWidth: true
                                                                    spacing: 10
                                                                    TeamLogo {
                                                                        theme: root
                                                                        Layout.preferredWidth: 24
                                                                        Layout.preferredHeight: 24
                                                                        source: sr.modelData.logo
                                                                        abbr: sr.modelData.abbr
                                                                    }
                                                                    Text {
                                                                        Layout.fillWidth: true
                                                                        text: sr.modelData.name
                                                                        color: root.fg
                                                                        font.pixelSize: 13
                                                                        font.bold: sr.fav
                                                                        elide: Text.ElideRight
                                                                    }
                                                                }
                                                                Text { Layout.preferredWidth: 52; horizontalAlignment: Text.AlignRight; text: sr.modelData.w; color: root.fg; font.pixelSize: 13; font.bold: true }
                                                                Text { Layout.preferredWidth: 52; horizontalAlignment: Text.AlignRight; text: sr.modelData.l; color: root.fg; font.pixelSize: 13 }
                                                                Text { Layout.preferredWidth: 64; horizontalAlignment: Text.AlignRight; text: sr.modelData.pct; color: root.muted; font.pixelSize: 13 }
                                                                Text { Layout.preferredWidth: 56; horizontalAlignment: Text.AlignRight; text: sr.modelData.gb; color: root.muted; font.pixelSize: 13 }
                                                                Text {
                                                                    Layout.preferredWidth: 64
                                                                    horizontalAlignment: Text.AlignRight
                                                                    text: sr.modelData.strk
                                                                    color: sr.modelData.strk.charAt(0) === "W" ? root.fg : root.muted
                                                                    font.pixelSize: 13
                                                                }
                                                                Text { Layout.preferredWidth: 64; horizontalAlignment: Text.AlignRight; text: sr.modelData.l10; color: root.muted; font.pixelSize: 13 }
                                                            }
                                                            MouseArea {
                                                                id: srMouse
                                                                anchors.fill: parent
                                                                hoverEnabled: true
                                                                cursorShape: Qt.PointingHandCursor
                                                                onClicked: root.sportsOpenTeam(sr.modelData.id)
                                                            }
                                                        }
                                                    }
                                                }

                                                Text {
                                                    anchors.centerIn: parent
                                                    visible: root.sportsConfs.length === 0
                                                    text: root.sportsLoading ? "Loading standings…" : (root.sportsStatus || "No standings yet")
                                                    color: root.muted
                                                    font.pixelSize: 14
                                                }
                                            }
                                        }

                                        // =========== Teams ===========
                                        ColumnLayout {
                                            spacing: 8

                                            // search
                                            Rectangle {
                                                Layout.fillWidth: true
                                                Layout.preferredHeight: 36
                                                radius: 12
                                                color: root.surface
                                                border.width: 1
                                                border.color: teamSearch.activeFocus ? root.accent : root.glassEdge
                                                Text {
                                                    id: teamSearchIcon
                                                    anchors.left: parent.left
                                                    anchors.leftMargin: 12
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: ""
                                                    font.family: root.iconFont
                                                    font.pixelSize: 13
                                                    color: root.muted
                                                }
                                                TextInput {
                                                    id: teamSearch
                                                    anchors.left: teamSearchIcon.right
                                                    anchors.leftMargin: 10
                                                    anchors.right: parent.right
                                                    anchors.rightMargin: 12
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    color: root.fg
                                                    font.pixelSize: 13
                                                    clip: true
                                                    text: root.sportsTeamFilter
                                                    onTextEdited: root.sportsTeamFilter = text
                                                    Keys.onEscapePressed: { text = ""; root.sportsTeamFilter = ""; hubKeys.forceActiveFocus(); }
                                                    Text {
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        visible: teamSearch.text === ""
                                                        text: "Find a team"
                                                        color: root.muted
                                                        font.pixelSize: 13
                                                    }
                                                }
                                            }

                                            Item {
                                                Layout.fillWidth: true
                                                Layout.fillHeight: true

                                                GridView {
                                                    id: teamGrid
                                                    anchors.fill: parent
                                                    clip: true
                                                    cellWidth: Math.floor(width / 6)
                                                    cellHeight: 112
                                                    boundsBehavior: Flickable.StopAtBounds
                                                    model: root.sportsAllTeams

                                                    delegate: Item {
                                                        id: tc
                                                        required property var modelData
                                                        width: teamGrid.cellWidth
                                                        height: teamGrid.cellHeight

                                                        Rectangle {
                                                            anchors.fill: parent
                                                            anchors.margins: 4
                                                            radius: 16
                                                            color: tcMouse.containsMouse ? root.overlay : root.surface
                                                            border.width: 1
                                                            border.color: tc.modelData.id === root.sportsFavId ? root.accent : root.glassEdge
                                                            scale: tcMouse.pressed ? 0.95 : 1
                                                            Behavior on color { ColorAnimation { duration: 120 } }
                                                            Behavior on scale { NumberAnimation { duration: 120 } }

                                                            Column {
                                                                anchors.centerIn: parent
                                                                width: parent.width - 16
                                                                spacing: 8
                                                                TeamLogo {
                                                                    theme: root
                                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                                    width: 46
                                                                    height: 46
                                                                    source: tc.modelData.logo
                                                                    abbr: tc.modelData.abbr
                                                                }
                                                                Text {
                                                                    width: parent.width
                                                                    horizontalAlignment: Text.AlignHCenter
                                                                    text: tc.modelData.short
                                                                    color: root.fg
                                                                    font.pixelSize: 12
                                                                    font.bold: true
                                                                    elide: Text.ElideRight
                                                                }
                                                            }
                                                            MouseArea {
                                                                id: tcMouse
                                                                anchors.fill: parent
                                                                hoverEnabled: true
                                                                cursorShape: Qt.PointingHandCursor
                                                                onClicked: root.sportsOpenTeam(tc.modelData.id)
                                                            }
                                                        }
                                                    }
                                                }

                                                Text {
                                                    anchors.centerIn: parent
                                                    visible: root.sportsAllTeams.length === 0
                                                    text: root.sportsLoading ? "Loading teams…" : (root.sportsStatus || "No teams match")
                                                    color: root.muted
                                                    font.pixelSize: 14
                                                }
                                            }
                                        }

                                        // =========== One team ===========
                                        ColumnLayout {
                                            spacing: 10

                                            RowLayout {
                                                Layout.fillWidth: true
                                                spacing: 12
                                                SportChip { theme: root; icon: ""; label: "Back"; onClicked: root.sportsShow(root.sportsBackTo) }
                                                TeamLogo {
                                                    theme: root
                                                    Layout.preferredWidth: 48
                                                    Layout.preferredHeight: 48
                                                    source: root.sportsTeam ? (root.sportsTeam.logo || "") : ""
                                                    abbr: root.sportsTeam ? (root.sportsTeam.abbr || "") : ""
                                                }
                                                Column {
                                                    Layout.fillWidth: true
                                                    spacing: 2
                                                    Text {
                                                        text: root.sportsTeam ? (root.sportsTeam.name || "Loading…") : ""
                                                        color: root.fg
                                                        font.pixelSize: 20
                                                        font.bold: true
                                                    }
                                                    Text {
                                                        text: root.sportsTeam ? [root.sportsTeam.record, root.sportsTeam.standing].filter(x => x).join("  ·  ") : ""
                                                        color: root.muted
                                                        font.pixelSize: 12
                                                    }
                                                }
                                                SportChip {
                                                    theme: root
                                                    icon: ""
                                                    label: root.sportsTeam && root.sportsTeam.id === root.sportsFavId ? "My team" : "Set as my team"
                                                    active: root.sportsTeam !== null && root.sportsTeam.id === root.sportsFavId
                                                    onClicked: root.sportsToggleFav()
                                                }
                                            }

                                            RowLayout {
                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                spacing: 12

                                                // ---- roster ----
                                                HubCard {
                                                    theme: root
                                                    Layout.fillWidth: true
                                                    Layout.fillHeight: true
                                                    Layout.preferredWidth: 3
                                                    clip: true

                                                    ColumnLayout {
                                                        anchors.fill: parent
                                                        anchors.margins: 12
                                                        spacing: 6
                                                        Text { text: "Roster"; color: root.fg; font.pixelSize: 14; font.bold: true }

                                                        ListView {
                                                            id: rosterList
                                                            Layout.fillWidth: true
                                                            Layout.fillHeight: true
                                                            clip: true
                                                            spacing: 2
                                                            boundsBehavior: Flickable.StopAtBounds
                                                            model: root.sportsRoster

                                                            delegate: Rectangle {
                                                                id: rp
                                                                required property var modelData
                                                                width: rosterList.width
                                                                height: 40
                                                                radius: 10
                                                                color: rpMouse.containsMouse ? root.overlay : "transparent"

                                                                RowLayout {
                                                                    anchors.fill: parent
                                                                    anchors.leftMargin: 6
                                                                    anchors.rightMargin: 10
                                                                    spacing: 10
                                                                    Rectangle {
                                                                        Layout.preferredWidth: 30
                                                                        Layout.preferredHeight: 30
                                                                        radius: 15
                                                                        color: root.overlay
                                                                        Text {
                                                                            anchors.centerIn: parent
                                                                            text: rp.modelData.jersey || "–"
                                                                            color: root.fg
                                                                            font.pixelSize: 12
                                                                            font.bold: true
                                                                        }
                                                                    }
                                                                    Text {
                                                                        Layout.fillWidth: true
                                                                        text: rp.modelData.name
                                                                        color: root.fg
                                                                        font.pixelSize: 13
                                                                        elide: Text.ElideRight
                                                                    }
                                                                    Text {
                                                                        visible: rp.modelData.injury !== ""
                                                                        text: rp.modelData.injury
                                                                        color: root.danger
                                                                        font.pixelSize: 11
                                                                        font.bold: true
                                                                    }
                                                                    Text { text: rp.modelData.pos; color: root.muted; font.pixelSize: 12; Layout.preferredWidth: 28 }
                                                                    Text { text: rp.modelData.height; color: root.muted; font.pixelSize: 12; Layout.preferredWidth: 48; horizontalAlignment: Text.AlignRight }
                                                                }
                                                                MouseArea {
                                                                    id: rpMouse
                                                                    anchors.fill: parent
                                                                    hoverEnabled: true
                                                                    cursorShape: Qt.PointingHandCursor
                                                                    onClicked: root.sportsOpenPlayerFrom(rp.modelData, "team")
                                                                }
                                                            }
                                                        }
                                                    }
                                                    Text {
                                                        anchors.centerIn: parent
                                                        visible: root.sportsRoster.length === 0
                                                        text: root.sportsLoading ? "Loading roster…" : "No roster"
                                                        color: root.muted
                                                        font.pixelSize: 13
                                                    }
                                                }

                                                // ---- schedule ----
                                                HubCard {
                                                    theme: root
                                                    Layout.fillWidth: true
                                                    Layout.fillHeight: true
                                                    Layout.preferredWidth: 2
                                                    clip: true

                                                    Flickable {
                                                        anchors.fill: parent
                                                        anchors.margins: 12
                                                        contentHeight: schedCol.implicitHeight
                                                        clip: true
                                                        boundsBehavior: Flickable.StopAtBounds

                                                        Column {
                                                            id: schedCol
                                                            width: parent.width
                                                            spacing: 6

                                                            Repeater {
                                                                model: [
                                                                    { title: "Coming up", list: root.sportsUpcoming },
                                                                    { title: "Recent", list: root.sportsRecent }
                                                                ]
                                                                delegate: Column {
                                                                    id: sec
                                                                    required property var modelData
                                                                    width: schedCol.width
                                                                    spacing: 4
                                                                    visible: modelData.list.length > 0
                                                                    topPadding: 4
                                                                    Text { text: sec.modelData.title; color: root.fg; font.pixelSize: 14; font.bold: true; bottomPadding: 2 }

                                                                    Repeater {
                                                                        model: sec.modelData.list
                                                                        delegate: Rectangle {
                                                                            id: sg
                                                                            required property var modelData
                                                                            readonly property bool live: modelData.state === "in"
                                                                            width: sec.width
                                                                            height: 38
                                                                            radius: 10
                                                                            color: sgMouse.containsMouse ? root.overlay : Qt.rgba(1, 1, 1, 0.04)

                                                                            RowLayout {
                                                                                anchors.fill: parent
                                                                                anchors.leftMargin: 8
                                                                                anchors.rightMargin: 10
                                                                                spacing: 8
                                                                                // W / L badge, or the date
                                                                                Rectangle {
                                                                                    visible: sg.modelData.state === "post"
                                                                                    Layout.preferredWidth: 22
                                                                                    Layout.preferredHeight: 22
                                                                                    radius: 7
                                                                                    color: sg.modelData.won ? root.accent : root.overlay
                                                                                    Text {
                                                                                        anchors.centerIn: parent
                                                                                        text: sg.modelData.won ? "W" : "L"
                                                                                        color: sg.modelData.won ? root.bg : root.fg
                                                                                        font.pixelSize: 11
                                                                                        font.bold: true
                                                                                    }
                                                                                }
                                                                                Text {
                                                                                    visible: sg.modelData.state !== "post"
                                                                                    Layout.preferredWidth: 54
                                                                                    text: sg.live ? "LIVE" : Qt.formatDate(new Date(sg.modelData.date), "ddd d")
                                                                                    color: sg.live ? root.danger : root.muted
                                                                                    font.pixelSize: 12
                                                                                    font.bold: sg.live
                                                                                }
                                                                                Text {
                                                                                    text: sg.modelData.home ? "vs" : "@"
                                                                                    color: root.muted
                                                                                    font.pixelSize: 11
                                                                                }
                                                                                TeamLogo {
                                                                                    theme: root
                                                                                    Layout.preferredWidth: 22
                                                                                    Layout.preferredHeight: 22
                                                                                    source: sg.modelData.oppLogo
                                                                                    abbr: sg.modelData.opp
                                                                                }
                                                                                Text {
                                                                                    Layout.fillWidth: true
                                                                                    text: sg.modelData.oppName
                                                                                    color: root.fg
                                                                                    font.pixelSize: 13
                                                                                    elide: Text.ElideRight
                                                                                }
                                                                                Text {
                                                                                    text: sg.modelData.state === "pre" ? root.sportsTime(sg.modelData.date)
                                                                                        : sg.modelData.us + "–" + sg.modelData.them
                                                                                    color: sg.live ? root.danger : root.muted
                                                                                    font.pixelSize: 12
                                                                                    font.bold: sg.modelData.state !== "pre"
                                                                                }
                                                                            }
                                                                            MouseArea {
                                                                                id: sgMouse
                                                                                anchors.fill: parent
                                                                                hoverEnabled: true
                                                                                cursorShape: Qt.PointingHandCursor
                                                                                onClicked: {
                                                                                    const me = { id: root.sportsTeam.id, abbr: root.sportsTeam.abbr, name: root.sportsTeam.name, logo: root.sportsTeam.logo, score: sg.modelData.us, record: "" };
                                                                                    const them = { id: sg.modelData.oppId, abbr: sg.modelData.opp, name: sg.modelData.oppName, logo: sg.modelData.oppLogo, score: sg.modelData.them, record: "" };
                                                                                    root.sportsOpenGame({ id: sg.modelData.id, date: sg.modelData.date, state: sg.modelData.state, detail: sg.modelData.detail,
                                                                                                          away: sg.modelData.home ? them : me, home: sg.modelData.home ? me : them });
                                                                                }
                                                                            }
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                    Text {
                                                        anchors.centerIn: parent
                                                        visible: root.sportsUpcoming.length === 0 && root.sportsRecent.length === 0
                                                        text: root.sportsLoading ? "Loading schedule…" : "No games scheduled"
                                                        color: root.muted
                                                        font.pixelSize: 13
                                                    }
                                                }
                                            }
                                        }

                                        // =========== One player ===========
                                        ColumnLayout {
                                            spacing: 10

                                            RowLayout {
                                                Layout.fillWidth: true
                                                spacing: 12
                                                SportChip {
                                                    theme: root
                                                    icon: ""
                                                    label: root.sportsPlayerFrom === "game" ? "Game" : (root.sportsTeam && root.sportsTeam.abbr ? root.sportsTeam.abbr : "Back")
                                                    onClicked: root.sportsView = root.sportsPlayerFrom
                                                }
                                                Item { Layout.fillWidth: true }
                                            }

                                            HubCard {
                                                theme: root
                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                clip: true

                                                ColumnLayout {
                                                    anchors.fill: parent
                                                    anchors.margins: 18
                                                    spacing: 16

                                                    RowLayout {
                                                        Layout.fillWidth: true
                                                        spacing: 22

                                                        // headshot on a soft team-coloured card
                                                        Rectangle {
                                                            id: shotCard
                                                            Layout.preferredWidth: 170
                                                            Layout.preferredHeight: 170
                                                            radius: 22
                                                            color: root.overlay
                                                            border.width: 1
                                                            border.color: root.glassEdge
                                                            clip: true
                                                            Rectangle {
                                                                anchors.fill: parent
                                                                radius: parent.radius
                                                                visible: root.sportsTeam !== null && (root.sportsTeam.color || "") !== ""
                                                                color: root.sportsTeam && root.sportsTeam.color ? root.sportsTeam.color : "transparent"
                                                                opacity: 0.45
                                                            }
                                                            Image {
                                                                id: shotImg
                                                                anchors.fill: parent
                                                                anchors.topMargin: 10
                                                                source: root.sportsPlayer ? root.sportsPlayer.headshot : ""
                                                                sourceSize.width: 340
                                                                fillMode: Image.PreserveAspectCrop
                                                                verticalAlignment: Image.AlignBottom
                                                                asynchronous: true
                                                                smooth: true
                                                                mipmap: true
                                                            }
                                                            Text {
                                                                anchors.centerIn: parent
                                                                visible: shotImg.status !== Image.Ready
                                                                text: root.sportsPlayer ? (root.sportsPlayer.jersey || "") : ""
                                                                color: root.fg
                                                                font.pixelSize: 54
                                                                font.bold: true
                                                            }
                                                        }

                                                        ColumnLayout {
                                                            Layout.fillWidth: true
                                                            spacing: 6
                                                            Text {
                                                                text: root.sportsPlayer ? root.sportsPlayer.name : ""
                                                                color: root.fg
                                                                font.pixelSize: 26
                                                                font.bold: true
                                                            }
                                                            Text {
                                                                text: root.sportsPlayer ? ["#" + (root.sportsPlayer.jersey || "–"), root.sportsPlayer.pos,
                                                                    (root.sportsPlayerFrom === "game" ? (root.sportsPlayer.team || "") : (root.sportsTeam ? root.sportsTeam.name : ""))].filter(x => x).join("  ·  ") : ""
                                                                color: root.muted
                                                                font.pixelSize: 14
                                                            }
                                                            Text {
                                                                visible: root.sportsPlayer !== null && root.sportsPlayer.injury !== ""
                                                                text: root.sportsPlayer ? root.sportsPlayer.injury : ""
                                                                color: root.danger
                                                                font.pixelSize: 13
                                                                font.bold: true
                                                            }

                                                            Row {
                                                                Layout.topMargin: 10
                                                                spacing: 10
                                                                Repeater {
                                                                    model: root.sportsPlayer ? [
                                                                        { k: "Height", v: root.sportsPlayer.height },
                                                                        { k: "Weight", v: root.sportsPlayer.weight },
                                                                        { k: "Age", v: root.sportsPlayer.age },
                                                                        { k: "Seasons", v: root.sportsPlayer.exp }
                                                                    ].filter(x => x.v) : []
                                                                    delegate: Rectangle {
                                                                        id: bio
                                                                        required property var modelData
                                                                        width: 104
                                                                        height: 58
                                                                        radius: 14
                                                                        color: Qt.rgba(1, 1, 1, 0.05)
                                                                        border.width: 1
                                                                        border.color: root.glassEdge
                                                                        Column {
                                                                            anchors.centerIn: parent
                                                                            spacing: 3
                                                                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: bio.modelData.v; color: root.fg; font.pixelSize: 15; font.bold: true }
                                                                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: bio.modelData.k; color: root.muted; font.pixelSize: 11 }
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }

                                                    // ---- stats table ----
                                                    ColumnLayout {
                                                        Layout.fillWidth: true
                                                        Layout.fillHeight: true
                                                        spacing: 4
                                                        visible: root.sportsPlayerStats !== null && root.sportsPlayerStats.labels.length > 0

                                                        RowLayout {
                                                            Layout.fillWidth: true
                                                            Layout.leftMargin: 10
                                                            Layout.rightMargin: 10
                                                            spacing: 0
                                                            Text { Layout.preferredWidth: 130; text: "Averages"; color: root.muted; font.pixelSize: 11; font.bold: true }
                                                            Repeater {
                                                                model: root.sportsPlayerStats ? root.sportsPlayerStats.labels : []
                                                                delegate: Text {
                                                                    required property var modelData
                                                                    Layout.fillWidth: true
                                                                    Layout.preferredWidth: 1
                                                                    horizontalAlignment: Text.AlignRight
                                                                    text: modelData
                                                                    color: root.muted
                                                                    font.pixelSize: 11
                                                                    font.bold: true
                                                                }
                                                            }
                                                        }
                                                        Repeater {
                                                            model: root.sportsPlayerStats ? root.sportsPlayerStats.rows : []
                                                            delegate: Rectangle {
                                                                id: srow
                                                                required property var modelData
                                                                required property int index
                                                                Layout.fillWidth: true
                                                                Layout.preferredHeight: 36
                                                                radius: 10
                                                                color: srow.index % 2 === 0 ? Qt.rgba(1, 1, 1, 0.05) : "transparent"
                                                                RowLayout {
                                                                    anchors.fill: parent
                                                                    anchors.leftMargin: 10
                                                                    anchors.rightMargin: 10
                                                                    spacing: 0
                                                                    Text { Layout.preferredWidth: 130; text: srow.modelData.name; color: root.fg; font.pixelSize: 13; font.bold: true; elide: Text.ElideRight }
                                                                    Repeater {
                                                                        model: srow.modelData.stats
                                                                        delegate: Text {
                                                                            required property var modelData
                                                                            Layout.fillWidth: true
                                                                            Layout.preferredWidth: 1
                                                                            horizontalAlignment: Text.AlignRight
                                                                            text: modelData
                                                                            color: root.fg
                                                                            font.pixelSize: 13
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                        }
                                                        Item { Layout.fillHeight: true }
                                                    }

                                                    Text {
                                                        Layout.fillWidth: true
                                                        Layout.fillHeight: true
                                                        horizontalAlignment: Text.AlignHCenter
                                                        verticalAlignment: Text.AlignVCenter
                                                        visible: root.sportsPlayerStats === null || root.sportsPlayerStats.labels.length === 0
                                                        text: root.sportsPlayerStats === null ? "Loading stats…" : "No stats for this player yet"
                                                        color: root.muted
                                                        font.pixelSize: 13
                                                    }
                                                }
                                            }
                                        }

                                        // =========== One game: live box score ===========
                                        ColumnLayout {
                                            spacing: 10

                                            RowLayout {
                                                Layout.fillWidth: true
                                                spacing: 8
                                                SportChip {
                                                    theme: root
                                                    icon: ""
                                                    label: "Back"
                                                    onClicked: root.sportsShow(root.sportsBackTo === "team" ? "team" : root.sportsBackTo)
                                                }
                                                Item { Layout.fillWidth: true }
                                                Text {
                                                    visible: root.sportsGame !== null && root.sportsGame.state === "in"
                                                    text: "Live · updates every 15 s"
                                                    color: root.muted
                                                    font.pixelSize: 11
                                                }
                                            }

                                            // ---- scoreboard: away  score  [status + quarters]  score  home ----
                                            HubCard {
                                                theme: root
                                                Layout.fillWidth: true
                                                Layout.preferredHeight: 108

                                                RowLayout {
                                                    anchors.fill: parent
                                                    anchors.leftMargin: 22
                                                    anchors.rightMargin: 22
                                                    spacing: 16

                                                    Repeater {
                                                        model: ["away", "status", "home"]
                                                        delegate: Item {
                                                            id: sbPart
                                                            required property string modelData
                                                            required property int index
                                                            readonly property var t: root.sportsGame ? (modelData === "away" ? root.sportsGame.away : modelData === "home" ? root.sportsGame.home : null) : null
                                                            readonly property string score: !root.sportsBox ? (t ? t.score : "") : (modelData === "away" ? root.sportsBox.away : root.sportsBox.home)
                                                            readonly property bool lost: root.sportsGame !== null && root.sportsGame.state === "post" && sbPart.t !== null
                                                                && Number(sbPart.score) < Number(modelData === "away" ? (root.sportsBox ? root.sportsBox.home : root.sportsGame.home.score) : (root.sportsBox ? root.sportsBox.away : root.sportsGame.away.score))
                                                            Layout.fillWidth: modelData !== "status"
                                                            Layout.fillHeight: true
                                                            Layout.preferredWidth: modelData === "status" ? sbStatus.implicitWidth : 1

                                                            // a team: logo + name, big score toward the middle
                                                            RowLayout {
                                                                anchors.fill: parent
                                                                visible: sbPart.modelData !== "status"
                                                                layoutDirection: sbPart.modelData === "home" ? Qt.RightToLeft : Qt.LeftToRight
                                                                spacing: 14
                                                                TeamLogo {
                                                                    theme: root
                                                                    Layout.preferredWidth: 52
                                                                    Layout.preferredHeight: 52
                                                                    source: sbPart.t ? sbPart.t.logo : ""
                                                                    abbr: sbPart.t ? sbPart.t.abbr : ""
                                                                }
                                                                Column {
                                                                    spacing: 2
                                                                    Text {
                                                                        text: sbPart.t ? sbPart.t.name : ""
                                                                        color: sbPart.lost ? root.muted : root.fg
                                                                        font.pixelSize: 16
                                                                        font.bold: true
                                                                    }
                                                                    Text {
                                                                        text: sbPart.t ? (sbPart.t.record || sbPart.t.abbr) : ""
                                                                        color: root.muted
                                                                        font.pixelSize: 11
                                                                    }
                                                                }
                                                                Item { Layout.fillWidth: true }
                                                                Text {
                                                                    text: sbPart.score
                                                                    color: sbPart.lost ? root.muted : root.fg
                                                                    font.pixelSize: 38
                                                                    font.bold: true
                                                                }
                                                            }

                                                            // the middle: status and the score by quarter
                                                            Column {
                                                                id: sbStatus
                                                                anchors.centerIn: parent
                                                                visible: sbPart.modelData === "status"
                                                                spacing: 6
                                                                Row {
                                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                                    spacing: 6
                                                                    Rectangle {
                                                                        visible: root.sportsGame !== null && root.sportsGame.state === "in"
                                                                        anchors.verticalCenter: parent.verticalCenter
                                                                        width: 8
                                                                        height: 8
                                                                        radius: 4
                                                                        color: root.danger
                                                                        SequentialAnimation on opacity {
                                                                            running: root.sportsGame !== null && root.sportsGame.state === "in" && root.sportsVisible
                                                                            loops: Animation.Infinite
                                                                            NumberAnimation { to: 0.25; duration: 700 }
                                                                            NumberAnimation { to: 1; duration: 700 }
                                                                        }
                                                                    }
                                                                    Text {
                                                                        text: !root.sportsGame ? "" : root.sportsGame.state === "pre" ? root.sportsTime(root.sportsGame.date)
                                                                            : (root.sportsBox && root.sportsBox.detail ? root.sportsBox.detail : root.sportsGame.detail)
                                                                        color: root.sportsGame && root.sportsGame.state === "in" ? root.danger : root.fg
                                                                        font.pixelSize: 13
                                                                        font.bold: true
                                                                    }
                                                                }
                                                                // Q1 Q2 Q3 Q4 (OT)
                                                                Grid {
                                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                                    visible: root.sportsBox !== null && root.sportsBox.lines.length > 0
                                                                    columns: root.sportsBox ? root.sportsBox.lines.length + 1 : 1
                                                                    columnSpacing: 10
                                                                    rowSpacing: 2
                                                                    Repeater {
                                                                        model: {
                                                                            if (!root.sportsBox || !root.sportsGame) return [];
                                                                            const L = root.sportsBox.lines, out = [{ t: "", h: true }];
                                                                            L.forEach(l => out.push({ t: l.label, h: true }));
                                                                            out.push({ t: root.sportsGame.away.abbr, h: true });
                                                                            L.forEach(l => out.push({ t: l.away, h: false }));
                                                                            out.push({ t: root.sportsGame.home.abbr, h: true });
                                                                            L.forEach(l => out.push({ t: l.home, h: false }));
                                                                            return out;
                                                                        }
                                                                        delegate: Text {
                                                                            required property var modelData
                                                                            horizontalAlignment: Text.AlignHCenter
                                                                            width: 24
                                                                            text: modelData.t
                                                                            color: modelData.h ? root.muted : root.fg
                                                                            font.pixelSize: 11
                                                                            font.bold: !modelData.h
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }

                                            // ---- which team's players ----
                                            RowLayout {
                                                Layout.fillWidth: true
                                                spacing: 6
                                                Repeater {
                                                    model: root.sportsBox ? root.sportsBox.teams : []
                                                    delegate: SportChip {
                                                        required property var modelData
                                                        required property int index
                                                        theme: root
                                                        label: modelData.name
                                                        active: root.sportsBoxSide === index
                                                        onClicked: root.sportsBoxSide = index
                                                    }
                                                }
                                                Item { Layout.fillWidth: true }
                                            }

                                            // ---- the box score ----
                                            HubCard {
                                                id: boxCard
                                                theme: root
                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                clip: true
                                                readonly property var team: root.sportsBox && root.sportsBox.teams.length > root.sportsBoxSide ? root.sportsBox.teams[root.sportsBoxSide] : null
                                                readonly property int ptsCol: boxCard.team ? boxCard.team.labels.indexOf("PTS") : -1

                                                ColumnLayout {
                                                    anchors.fill: parent
                                                    anchors.margins: 10
                                                    spacing: 2
                                                    visible: boxCard.team !== null && boxCard.team.players.length > 0

                                                    // headings
                                                    RowLayout {
                                                        Layout.fillWidth: true
                                                        Layout.leftMargin: 8
                                                        Layout.rightMargin: 8
                                                        spacing: 0
                                                        Text { Layout.preferredWidth: 170; text: "Player"; color: root.muted; font.pixelSize: 11; font.bold: true }
                                                        Repeater {
                                                            model: boxCard.team ? boxCard.team.labels : []
                                                            delegate: Text {
                                                                required property var modelData
                                                                Layout.fillWidth: true
                                                                Layout.preferredWidth: 1
                                                                horizontalAlignment: Text.AlignRight
                                                                text: modelData
                                                                color: root.muted
                                                                font.pixelSize: 11
                                                                font.bold: true
                                                            }
                                                        }
                                                    }

                                                    ListView {
                                                        id: boxList
                                                        Layout.fillWidth: true
                                                        Layout.fillHeight: true
                                                        clip: true
                                                        boundsBehavior: Flickable.StopAtBounds
                                                        model: boxCard.team ? boxCard.team.players.concat([{ totals: true }]) : []

                                                        delegate: Rectangle {
                                                            id: bp
                                                            required property var modelData
                                                            required property int index
                                                            readonly property bool isTotal: modelData.totals === true
                                                            readonly property bool benchStart: !isTotal && !modelData.starter && index > 0 && boxCard.team.players[index - 1].starter
                                                            width: boxList.width
                                                            height: (bp.benchStart ? 22 : 0) + 34
                                                            radius: 8
                                                            color: "transparent"

                                                            Text {
                                                                visible: bp.benchStart
                                                                x: 8
                                                                y: 4
                                                                text: "Bench"
                                                                color: root.muted
                                                                font.pixelSize: 11
                                                                font.bold: true
                                                            }

                                                            Rectangle {
                                                                anchors.left: parent.left
                                                                anchors.right: parent.right
                                                                anchors.bottom: parent.bottom
                                                                height: 34
                                                                radius: 8
                                                                color: bpMouse.containsMouse && !bp.isTotal ? root.overlay : (bp.isTotal ? Qt.rgba(1, 1, 1, 0.07) : (bp.index % 2 === 0 ? Qt.rgba(1, 1, 1, 0.035) : "transparent"))

                                                                RowLayout {
                                                                    anchors.fill: parent
                                                                    anchors.leftMargin: 8
                                                                    anchors.rightMargin: 8
                                                                    spacing: 0

                                                                    Row {
                                                                        Layout.preferredWidth: 170
                                                                        spacing: 8
                                                                        Text {
                                                                            width: 22
                                                                            visible: !bp.isTotal
                                                                            anchors.verticalCenter: parent.verticalCenter
                                                                            horizontalAlignment: Text.AlignRight
                                                                            text: bp.isTotal ? "" : bp.modelData.jersey
                                                                            color: root.muted
                                                                            font.pixelSize: 11
                                                                        }
                                                                        Text {
                                                                            width: bp.isTotal ? 160 : 132
                                                                            anchors.verticalCenter: parent.verticalCenter
                                                                            text: bp.isTotal ? "Team" : bp.modelData.short + (bp.modelData.pos ? "  " + bp.modelData.pos : "")
                                                                            color: root.fg
                                                                            font.pixelSize: 12
                                                                            font.bold: bp.isTotal
                                                                            elide: Text.ElideRight
                                                                        }
                                                                    }

                                                                    // didn't play: one muted line instead of numbers
                                                                    Text {
                                                                        Layout.fillWidth: true
                                                                        visible: !bp.isTotal && (bp.modelData.dnp || bp.modelData.stats.length === 0)
                                                                        text: "Didn't play" + (bp.modelData.reason ? "  ·  " + bp.modelData.reason.toLowerCase() : "")
                                                                        color: root.muted
                                                                        font.pixelSize: 11
                                                                        font.italic: true
                                                                    }

                                                                    Repeater {
                                                                        model: bp.isTotal ? boxCard.team.totals : (bp.modelData.dnp ? [] : bp.modelData.stats)
                                                                        delegate: Text {
                                                                            required property var modelData
                                                                            required property int index
                                                                            Layout.fillWidth: true
                                                                            Layout.preferredWidth: 1
                                                                            horizontalAlignment: Text.AlignRight
                                                                            text: modelData
                                                                            color: index === boxCard.ptsCol ? root.fg : (bp.isTotal ? root.fg : Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.82))
                                                                            font.pixelSize: 12
                                                                            font.bold: index === boxCard.ptsCol || bp.isTotal
                                                                        }
                                                                    }
                                                                }

                                                                MouseArea {
                                                                    id: bpMouse
                                                                    anchors.fill: parent
                                                                    enabled: !bp.isTotal
                                                                    hoverEnabled: true
                                                                    cursorShape: Qt.PointingHandCursor
                                                                    onClicked: root.sportsOpenPlayerFrom(bp.modelData, "game")
                                                                }
                                                            }
                                                        }
                                                    }
                                                }

                                                Text {
                                                    anchors.centerIn: parent
                                                    visible: boxCard.team === null || boxCard.team.players.length === 0
                                                    horizontalAlignment: Text.AlignHCenter
                                                    text: root.sportsLoading && !root.sportsBox ? "Loading the box score…"
                                                        : root.sportsGame && root.sportsGame.state === "pre" ? "Player stats show up here at tip-off"
                                                        : (root.sportsStatus || "No player stats for this game yet")
                                                    color: root.muted
                                                    font.pixelSize: 13
                                                }
                                            }
                                        }
                                    }
                                }

                                // ===== 8: Themes =====
                                Flickable {
                                    id: themesPage
                                    clip: true
                                    contentWidth: width
                                    contentHeight: themesCol.implicitHeight + 6
                                    boundsBehavior: Flickable.StopAtBounds

                                    ColumnLayout {
                                        id: themesCol
                                        width: themesPage.width
                                        spacing: 12

                                        // ---- Quick looks: one click sets everything ----
                                        Text { text: "Quick looks"; color: root.fg; font.pixelSize: 15; font.bold: true }
                                        Flow {
                                            Layout.fillWidth: true
                                            spacing: 8
                                            Repeater {
                                                model: root.themePresets
                                                delegate: Rectangle {
                                                    id: pre
                                                    required property var modelData
                                                    readonly property bool current: root.colorSource === modelData.source
                                                        && root.themeStyle === modelData.style && root.themeShade === modelData.shade
                                                        && (modelData.source !== "custom" || pins.adapter.customColor.toLowerCase() === modelData.color)
                                                    width: preRow.implicitWidth + 24
                                                    height: 34
                                                    radius: 17
                                                    color: pre.current ? root.accent : (preMouse.containsMouse ? root.overlay : root.surface)
                                                    border.width: 1
                                                    border.color: root.glassEdge
                                                    scale: preMouse.pressed ? 0.94 : 1
                                                    Behavior on color { ColorAnimation { duration: root.animMs } }
                                                    Behavior on scale { NumberAnimation { duration: root.animMs; easing.type: Easing.OutBack } }
                                                    Row {
                                                        id: preRow
                                                        anchors.centerIn: parent
                                                        spacing: 7
                                                        Rectangle {
                                                            anchors.verticalCenter: parent.verticalCenter
                                                            width: 14; height: 14; radius: 7
                                                            border.width: 1
                                                            border.color: Qt.rgba(1, 1, 1, 0.5)
                                                            color: pre.modelData.source === "wallpaper" ? root.seed
                                                                : (pre.modelData.color || root.seed)
                                                        }
                                                        Text {
                                                            anchors.verticalCenter: parent.verticalCenter
                                                            text: pre.modelData.name
                                                            color: pre.current ? root.bg : root.fg
                                                            font.pixelSize: 12
                                                            font.bold: pre.current
                                                        }
                                                    }
                                                    MouseArea {
                                                        id: preMouse
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: root.setTheme(pre.modelData.source, pre.modelData.style, pre.modelData.shade,
                                                            pre.modelData.tint, pre.modelData.source === "custom" ? pre.modelData.color : "")
                                                    }
                                                }
                                            }
                                        }

                                        // ---- Style: how the bars are drawn ----
                                        Text { text: "Style"; color: root.fg; font.pixelSize: 15; font.bold: true; Layout.topMargin: 4 }
                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 10
                                            Repeater {
                                                model: root.themeStyles
                                                delegate: Rectangle {
                                                    id: stCard
                                                    required property var modelData
                                                    readonly property bool current: root.themeStyle === modelData.id
                                                    readonly property var a: root.styleTable[modelData.id]
                                                    Layout.fillWidth: true
                                                    Layout.preferredHeight: 92
                                                    radius: 18
                                                    // a colourful backdrop so you can see how see-through each style is
                                                    gradient: Gradient {
                                                        orientation: Gradient.Horizontal
                                                        GradientStop { position: 0; color: root.wallPalette.length > 0 ? root.wallPalette[0] : "#5c6bc0" }
                                                        GradientStop { position: 1; color: root.wallPalette.length > 1 ? root.wallPalette[1] : "#ff79c6" }
                                                    }
                                                    border.width: stCard.current ? 2 : 1
                                                    border.color: stCard.current ? root.accent : root.glassEdge
                                                    scale: stMouse.pressed ? 0.95 : (stMouse.containsMouse ? 1.03 : 1)
                                                    Behavior on scale { NumberAnimation { duration: root.animMs; easing.type: Easing.OutBack } }

                                                    // a tiny pill drawn in this style
                                                    Rectangle {
                                                        anchors.fill: parent
                                                        anchors.margins: 9
                                                        radius: 13
                                                        color: root.dark ? Qt.hsla(root.hue, root.tsat * 0.35, 0.10, stCard.a[0])
                                                                         : Qt.hsla(root.hue, root.tsat * 0.25, 0.97, stCard.a[3])
                                                        border.width: 1
                                                        border.color: stCard.modelData.id === "neon"
                                                            ? Qt.rgba(root.accentBase.r, root.accentBase.g, root.accentBase.b, stCard.a[6])
                                                            : Qt.rgba(1, 1, 1, root.dark ? stCard.a[6] : Math.min(0.9, stCard.a[6] * 2.9))
                                                        Column {
                                                            anchors.centerIn: parent
                                                            spacing: 2
                                                            Text {
                                                                anchors.horizontalCenter: parent.horizontalCenter
                                                                text: stCard.modelData.name
                                                                color: root.fg
                                                                font.pixelSize: 13
                                                                font.bold: true
                                                            }
                                                            Text {
                                                                anchors.horizontalCenter: parent.horizontalCenter
                                                                text: stCard.modelData.sub
                                                                color: root.muted
                                                                font.pixelSize: 10
                                                            }
                                                        }
                                                    }
                                                    Rectangle {
                                                        visible: stCard.current
                                                        anchors.top: parent.top
                                                        anchors.right: parent.right
                                                        anchors.margins: 5
                                                        width: 18; height: 18; radius: 9
                                                        color: root.accent
                                                        Text { anchors.centerIn: parent; text: ""; font.family: root.iconFont; font.pixelSize: 9; color: root.bg }
                                                    }
                                                    MouseArea {
                                                        id: stMouse
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: pins.adapter.themeStyle = stCard.modelData.id
                                                    }
                                                }
                                            }
                                        }

                                        // ---- Colours from / brightness / how strong ----
                                        RowLayout {
                                            Layout.fillWidth: true
                                            Layout.topMargin: 4
                                            spacing: 18

                                            Column {
                                                spacing: 6
                                                Text { text: "Colours from"; color: root.muted; font.pixelSize: 11 }
                                                Row {
                                                    spacing: 6
                                                    Repeater {
                                                        model: [ { id: "neutral", name: "Neutral", icon: "" },
                                                                 { id: "wallpaper", name: "Wallpaper", icon: "" },
                                                                 { id: "custom", name: "My colour", icon: "" } ]
                                                        delegate: SportChip {
                                                            required property var modelData
                                                            theme: root
                                                            label: modelData.name
                                                            icon: modelData.icon
                                                            active: root.colorSource === modelData.id
                                                            onClicked: pins.adapter.colorSource = modelData.id
                                                        }
                                                    }
                                                }
                                            }
                                            Column {
                                                spacing: 6
                                                Text { text: "Brightness"; color: root.muted; font.pixelSize: 11 }
                                                Row {
                                                    spacing: 6
                                                    Repeater {
                                                        model: [ { id: "dark", name: "Dark", icon: "" },
                                                                 { id: "light", name: "Light", icon: "" },
                                                                 { id: "auto", name: "Auto", icon: "" } ]
                                                        delegate: SportChip {
                                                            required property var modelData
                                                            theme: root
                                                            label: modelData.name
                                                            icon: modelData.icon
                                                            active: root.themeShade === modelData.id
                                                            onClicked: pins.adapter.themeShade = modelData.id
                                                        }
                                                    }
                                                }
                                            }
                                            Column {
                                                spacing: 6
                                                opacity: root.glassTheme ? 0.4 : 1
                                                Text { text: "Colour strength"; color: root.muted; font.pixelSize: 11 }
                                                Row {
                                                    spacing: 6
                                                    Repeater {
                                                        model: [ { v: 0, name: "Accent only" }, { v: 0.5, name: "Subtle" }, { v: 1, name: "Full" } ]
                                                        delegate: SportChip {
                                                            required property var modelData
                                                            theme: root
                                                            label: modelData.name
                                                            active: Math.abs(root.themeTint - modelData.v) < 0.01
                                                            onClicked: pins.adapter.themeTint = modelData.v
                                                        }
                                                    }
                                                }
                                            }
                                            Item { Layout.fillWidth: true }
                                        }

                                        // ---- Colours in your wallpaper ----
                                        RowLayout {
                                            Layout.fillWidth: true
                                            Layout.topMargin: 4
                                            spacing: 10
                                            Text { text: "From your wallpaper"; color: root.fg; font.pixelSize: 15; font.bold: true }
                                            Item { Layout.fillWidth: true }
                                            SportChip {
                                                theme: root
                                                label: "Match my wallpaper"
                                                icon: ""
                                                active: root.colorSource === "wallpaper"
                                                onClicked: pins.adapter.colorSource = "wallpaper"
                                            }
                                        }
                                        Row {
                                            spacing: 10
                                            Repeater {
                                                model: root.wallPalette
                                                delegate: Rectangle {
                                                    id: sw
                                                    required property string modelData
                                                    readonly property bool current: root.colorSource === "custom" && root.customColor.toLowerCase() === sw.modelData.toLowerCase()
                                                    width: 40
                                                    height: 40
                                                    radius: 40 / 2
                                                    color: sw.modelData
                                                    border.width: sw.current ? 3 : 1
                                                    border.color: sw.current ? root.fg : Qt.rgba(1, 1, 1, 0.35)
                                                    scale: swMouse.pressed ? 0.85 : (swMouse.containsMouse ? 1.15 : 1)
                                                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                                                    Text {
                                                        anchors.centerIn: parent
                                                        visible: sw.current
                                                        text: "\uf00c"
                                                        font.family: root.iconFont
                                                        font.pixelSize: 40 * 0.38
                                                        color: sw.color.hslLightness > 0.6 ? "#1b1b1f" : "white"
                                                    }
                                                    MouseArea {
                                                        id: swMouse
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: root.pickColor(sw.modelData)
                                                    }
                                                }
                                            }
                                            Text {
                                                visible: root.wallPalette.length === 0
                                                text: "Pick a wallpaper and its colours show up here"
                                                color: root.muted
                                                font.pixelSize: 12
                                            }
                                        }

                                        // ---- Lots of colours to pick from ----
                                        RowLayout {
                                            Layout.fillWidth: true
                                            Layout.topMargin: 4
                                            spacing: 10
                                            Text { text: "Colours"; color: root.fg; font.pixelSize: 15; font.bold: true }
                                            Item { Layout.fillWidth: true }
                                            // type your own: #ff8800
                                            Rectangle {
                                                implicitWidth: 150
                                                implicitHeight: 32
                                                radius: 16
                                                color: root.surface
                                                border.width: 1
                                                border.color: hexIn.activeFocus ? root.accent : root.glassEdge
                                                Rectangle {
                                                    id: hexDot
                                                    anchors.left: parent.left
                                                    anchors.leftMargin: 8
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    width: 18; height: 18; radius: 9
                                                    color: pins.adapter.customColor
                                                    border.width: 1
                                                    border.color: Qt.rgba(1, 1, 1, 0.5)
                                                }
                                                TextInput {
                                                    id: hexIn
                                                    anchors.left: hexDot.right
                                                    anchors.leftMargin: 8
                                                    anchors.right: parent.right
                                                    anchors.rightMargin: 10
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    color: root.fg
                                                    font.pixelSize: 13
                                                    font.family: "JetBrainsMono Nerd Font"
                                                    clip: true
                                                    maximumLength: 7
                                                    validator: RegularExpressionValidator { regularExpression: /#?[0-9a-fA-F]{0,6}/ }
                                                    onAccepted: {
                                                        let v = text.trim();
                                                        if (v[0] !== "#") v = "#" + v;
                                                        if (/^#[0-9a-fA-F]{6}$/.test(v)) { root.pickColor(v.toLowerCase()); text = ""; }
                                                    }
                                                    Keys.onEscapePressed: { text = ""; hubKeys.forceActiveFocus(); }
                                                    Text {
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        visible: hexIn.text === ""
                                                        text: "#hex + Enter"
                                                        color: root.muted
                                                        font.pixelSize: 12
                                                    }
                                                }
                                            }
                                        }
                                        Flow {
                                            Layout.fillWidth: true
                                            spacing: 9
                                            Repeater {
                                                model: root.themeSwatches
                                                delegate: Rectangle {
                                                    id: sw
                                                    required property string modelData
                                                    readonly property bool current: root.colorSource === "custom" && root.customColor.toLowerCase() === sw.modelData.toLowerCase()
                                                    width: 32
                                                    height: 32
                                                    radius: 32 / 2
                                                    color: sw.modelData
                                                    border.width: sw.current ? 3 : 1
                                                    border.color: sw.current ? root.fg : Qt.rgba(1, 1, 1, 0.35)
                                                    scale: swMouse.pressed ? 0.85 : (swMouse.containsMouse ? 1.15 : 1)
                                                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                                                    Text {
                                                        anchors.centerIn: parent
                                                        visible: sw.current
                                                        text: "\uf00c"
                                                        font.family: root.iconFont
                                                        font.pixelSize: 32 * 0.38
                                                        color: sw.color.hslLightness > 0.6 ? "#1b1b1f" : "white"
                                                    }
                                                    MouseArea {
                                                        id: swMouse
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: root.pickColor(sw.modelData)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ---------- App launcher (search menu) ----------
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: launcher
            required property var modelData
            screen: modelData

            // Only show on the monitor that has focus. It stays up a moment after closing,
            // while the card shrinks back into the dock pill.
            readonly property bool focusedHere: !Hyprland.focusedMonitor || Hyprland.focusedMonitor.name === modelData.name
            property bool grown: false
            visible: focusedHere && (root.launcherOpen || card.height > card.pillH + 1)
            Connections {
                target: root
                function onLauncherOpenChanged() { launcher.grown = root.launcherOpen; }
            }

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell-launcher"
            WlrLayershell.keyboardFocus: root.launcherOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            exclusionMode: ExclusionMode.Ignore
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            color: "transparent"
            // gentle dim behind the launcher
            Rectangle {
                anchors.fill: parent
                color: "black"
                opacity: launcher.grown ? 0.16 : 0
                Behavior on opacity { NumberAnimation { duration: root.animMs * 2 } }
            }

            readonly property string query: searchInput.text
            readonly property bool searching: query.trim() !== ""
            // while typing, the "All" tab lights up because search covers every app
            readonly property int shownTab: searching ? 0 : root.launcherTab
            readonly property var results: {
                DesktopEntries.applications.values;      // re-run once apps finish loading
                pins.adapter.pinned;
                return root.appsForTab(shownTab, query);
            }
            readonly property var tabs: [
                { name: "All", icon: "" },
                { name: "Recent", icon: "" },
                { name: "Frequent", icon: "" },
                { name: "Pinned", icon: "" }
            ]

            onVisibleChanged: {
                if (visible) {
                    searchInput.text = "";
                    grid.currentIndex = 0;
                    searchInput.forceActiveFocus();
                }
            }
            onResultsChanged: grid.currentIndex = 0

            function launchCurrent() {
                if (grid.currentIndex < 0 || grid.currentIndex >= results.length) return;
                const e = results[grid.currentIndex];
                root.launcherOpen = false;
                root.launchApp(e);
            }

            function move(step) {
                if (results.length === 0) return;
                grid.currentIndex = Math.max(0, Math.min(results.length - 1, grid.currentIndex + step));
            }

            function switchTab(delta) {
                searchInput.text = "";
                root.launcherTab = (root.launcherTab + delta + tabs.length) % tabs.length;
            }

            // the name the dock uses: the app's window class when it has one, so the running dot works
            function pinKey(entry) {
                return entry ? (entry.startupClass || entry.id) : "";
            }

            // right-click menu for the pinned apps along the bottom
            property var menuItems: []
            property real menuX: 0
            onGrownChanged: menuItems = []
            function openPinMenu(item, key, entry, wins) {
                const out = [];
                out.push({ text: "Open new window", action: () => { root.launcherOpen = false; root.launchApp(entry); } });
                const acts = entry ? entry.actions : [];
                for (let i = 0; i < acts.length && i < 3; i++) {
                    const a = acts[i];
                    out.push({ text: a.name, action: () => { root.launcherOpen = false; a.execute(); } });
                }
                if (wins.length > 0)
                    out.push({ text: wins.length > 1 ? "Close all windows" : "Close window", danger: true,
                               action: () => { for (const w of wins) w.close(); } });
                out.push({ text: "Unpin", action: () => root.unpin(key) });
                menuX = item.mapToItem(card, item.width / 2, 0).x;
                menuItems = out;
            }

            function togglePin(entry) {
                const key = pinKey(entry);
                if (key === "") return;
                if (root.isPinned(key)) root.unpin(key);
                else root.pin(key);
            }

            // Click outside the card to close
            MouseArea {
                anchors.fill: parent
                onClicked: root.launcherOpen = false
            }

            // The card grows out of the dock pill at the bottom, and shrinks back into it when closed
            Rectangle {
                id: card
                readonly property real pillW: root.dockPillW
                readonly property real pillH: 22
                readonly property real pillGap: -10         // the tab hangs off the bottom edge like this
                width: launcher.grown ? 760 : pillW
                height: launcher.grown ? 640 : pillH
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: launcher.grown ? 14 : pillGap
                radius: launcher.grown ? 28 : 11
                Behavior on width { NumberAnimation { duration: root.animMs * 2.6; easing.type: Easing.OutBack; easing.overshoot: 0.6 } }
                Behavior on height { NumberAnimation { duration: root.animMs * 2.6; easing.type: Easing.OutBack; easing.overshoot: 0.6 } }
                Behavior on anchors.bottomMargin { NumberAnimation { duration: root.animMs * 2.6; easing.type: Easing.OutCubic } }
                Behavior on radius { NumberAnimation { duration: root.animMs * 2 } }
                color: root.popupBg
                border.color: root.glassEdge
                border.width: 1
                clip: true

                GlassShine { radius: parent.radius; dark: root.dark }
                // a soft wash of the wallpaper's accent colour from the bottom
                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    gradient: Gradient {
                        GradientStop { position: 0.55; color: "transparent" }
                        GradientStop { position: 1.0; color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, root.dark ? 0.10 : 0.08) }
                    }
                }
                // thin bright edge along the top

                // Swallow clicks inside the card (and close the little right-click menu)
                MouseArea { anchors.fill: parent; onClicked: launcher.menuItems = [] }

                ColumnLayout {
                    width: 760 - 40
                    height: 640 - 40
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 20
                    spacing: 14
                    opacity: launcher.grown ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: launcher.grown ? root.animMs * 3 : root.animMs; easing.type: Easing.OutCubic } }

                    // ---- Search box ----
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 54
                        radius: 18
                        color: root.surface
                        border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.7)
                        border.width: 1

                        Text {
                            id: searchIcon
                            anchors.left: parent.left
                            anchors.leftMargin: 18
                            anchors.verticalCenter: parent.verticalCenter
                            text: ""
                            color: root.accent
                            font.family: root.iconFont
                            font.pixelSize: 17
                        }

                        Buddy {
                            id: searchBuddy
                            theme: root
                            slot: 5
                            size: 34
                            anchors.right: parent.right
                            anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        TextInput {
                            id: searchInput
                            anchors.left: searchIcon.right
                            anchors.leftMargin: 14
                            anchors.right: parent.right
                            anchors.rightMargin: 56      // room for the sticker spot
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            verticalAlignment: TextInput.AlignVCenter
                            color: root.fg
                            font.pixelSize: 17
                            clip: true
                            selectByMouse: true

                            Keys.onPressed: event => {
                                const ctrl = event.modifiers & Qt.ControlModifier;
                                const cols = Math.max(1, Math.floor(grid.width / grid.cellWidth));
                                if (event.key === Qt.Key_Escape) {
                                    root.launcherOpen = false;
                                } else if (ctrl && event.key === Qt.Key_Tab) {
                                    launcher.switchTab(1);
                                } else if (ctrl && event.key === Qt.Key_Backtab) {
                                    launcher.switchTab(-1);
                                } else if (event.key === Qt.Key_Down) {
                                    launcher.move(cols);
                                } else if (event.key === Qt.Key_Up) {
                                    launcher.move(-cols);
                                } else if (event.key === Qt.Key_Tab) {
                                    launcher.move(1);
                                } else if (event.key === Qt.Key_Backtab) {
                                    launcher.move(-1);
                                } else if (event.key === Qt.Key_Right && searchInput.text === "") {
                                    launcher.move(1);
                                } else if (event.key === Qt.Key_Left && searchInput.text === "") {
                                    launcher.move(-1);
                                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    launcher.launchCurrent();
                                } else {
                                    return;
                                }
                                event.accepted = true;
                            }

                            Text {
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                visible: searchInput.text === ""
                                text: "Search apps..."
                                color: root.muted
                                font.pixelSize: 17
                            }
                        }
                    }

                    // ---- Tabs ----
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 44
                        radius: 14
                        color: root.surface
                        border.width: 1
                        border.color: root.glassEdge

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 4
                            spacing: 4

                            Repeater {
                                model: launcher.tabs

                                delegate: Rectangle {
                                    id: lTab
                                    required property var modelData
                                    required property int index
                                    readonly property bool current: launcher.shownTab === lTab.index
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    radius: 11
                                    color: lTab.current ? root.accent : (lTabMouse.containsMouse ? root.overlay : "transparent")
                                    scale: lTabMouse.pressed ? 0.95 : 1
                                    Behavior on color { ColorAnimation { duration: root.animMs } }
                                    Behavior on scale { NumberAnimation { duration: root.animMs; easing.type: Easing.OutBack } }

                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 8

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: lTab.modelData.icon
                                            color: lTab.current ? root.bg : root.accent
                                            font.family: root.iconFont
                                            font.pixelSize: 14
                                        }
                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: lTab.modelData.name
                                            color: lTab.current ? root.bg : root.fg
                                            font.pixelSize: 13
                                            font.bold: lTab.current
                                        }
                                    }

                                    MouseArea {
                                        id: lTabMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            searchInput.text = "";
                                            root.launcherTab = lTab.index;
                                            searchInput.forceActiveFocus();
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ---- App grid ----
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        GridView {
                            id: grid
                            anchors.fill: parent
                            clip: true
                            cellWidth: Math.floor(width / 6)
                            cellHeight: 112
                            model: launcher.results
                            currentIndex: 0
                            keyNavigationEnabled: false
                            boundsBehavior: Flickable.StopAtBounds
                            onCurrentIndexChanged: if (currentIndex >= 0) positionViewAtIndex(currentIndex, GridView.Contain)

                            delegate: Item {
                                id: tileItem
                                required property var modelData
                                required property int index
                                readonly property bool current: GridView.isCurrentItem
                                readonly property bool pinned: root.isPinned(launcher.pinKey(tileItem.modelData))
                                width: grid.cellWidth
                                height: grid.cellHeight

                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: 5
                                    radius: 18
                                    color: tileItem.current ? root.overlay : (tileMouse.containsMouse ? root.surface : "transparent")
                                    border.width: tileItem.current || tileMouse.containsMouse ? 1 : 0
                                    border.color: root.glassEdge
                                    scale: tileMouse.pressed ? 0.94 : (tileMouse.containsMouse ? 1.05 : 1)
                                    Behavior on color { ColorAnimation { duration: root.animMs } }
                                    Behavior on scale { NumberAnimation { duration: root.animMs; easing.type: Easing.OutBack } }

                                    Column {
                                        anchors.centerIn: parent
                                        spacing: 8

                                        IconImage {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            implicitSize: 50
                                            source: Quickshell.iconPath(tileItem.modelData.icon, "application-x-executable")
                                        }
                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            width: grid.cellWidth - 22
                                            horizontalAlignment: Text.AlignHCenter
                                            text: tileItem.modelData.name
                                            color: root.fg
                                            font.pixelSize: 12
                                            elide: Text.ElideRight
                                        }
                                    }

                                    // pin marker in the corner
                                    Text {
                                        visible: tileItem.pinned
                                        anchors.top: parent.top
                                        anchors.right: parent.right
                                        anchors.margins: 9
                                        text: ""
                                        color: root.accent
                                        font.family: root.iconFont
                                        font.pixelSize: 11
                                    }

                                    MouseArea {
                                        id: tileMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                                        onEntered: grid.currentIndex = tileItem.index
                                        onClicked: mouse => {
                                            if (mouse.button === Qt.RightButton) {
                                                launcher.togglePin(tileItem.modelData);
                                            } else {
                                                root.launcherOpen = false;
                                                root.launchApp(tileItem.modelData);
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: launcher.results.length === 0
                            horizontalAlignment: Text.AlignHCenter
                            text: launcher.searching ? "No matching apps"
                                : (launcher.shownTab === 3 ? "Nothing pinned yet\nRight-click any app to pin it to the taskbar"
                                : "Nothing here yet\nApps you open will show up in this tab")
                            color: root.muted
                            font.pixelSize: 13
                            lineHeight: 1.3
                        }
                    }

                    // ---- Taskbar: your pinned apps along the bottom ----
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 1
                        color: root.glassEdge
                    }
                    Item {
                        Layout.fillWidth: true
                        implicitHeight: 58

                        Row {
                            id: taskRow
                            anchors.centerIn: parent
                            spacing: 6

                            Repeater {
                                model: pins.adapter.pinned

                                delegate: Item {
                                    id: tpin
                                    required property string modelData
                                    readonly property var entry: {
                                        DesktopEntries.applications.values;
                                        return DesktopEntries.heuristicLookup(modelData);
                                    }
                                    readonly property var wins: root.windowsFor(modelData)
                                    readonly property bool running: wins.length > 0
                                    readonly property bool isActive: {
                                        for (let i = 0; i < wins.length; i++)
                                            if (wins[i].activated) return true;
                                        return false;
                                    }
                                    visible: !!entry
                                    width: visible ? 54 : 0
                                    height: 54

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 16
                                        color: tpinMouse.containsMouse ? root.overlay : (tpin.isActive ? root.surface : "transparent")
                                        Behavior on color { ColorAnimation { duration: root.animMs } }
                                    }
                                    IconImage {
                                        anchors.centerIn: parent
                                        implicitSize: 38
                                        scale: tpinMouse.pressed ? 0.85 : (tpinMouse.containsMouse ? 1.15 : 1)
                                        Behavior on scale { NumberAnimation { duration: root.animMs; easing.type: Easing.OutBack } }
                                        source: tpin.entry ? Quickshell.iconPath(tpin.entry.icon, "application-x-executable") : ""
                                    }
                                    // dot under open apps (longer for the focused one)
                                    Rectangle {
                                        visible: tpin.running
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        anchors.bottom: parent.bottom
                                        anchors.bottomMargin: 2
                                        width: tpin.isActive ? 14 : 5
                                        height: 3
                                        radius: 2
                                        color: root.accent
                                    }
                                    MouseArea {
                                        id: tpinMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                                        onClicked: mouse => {
                                            if (mouse.button === Qt.RightButton) {
                                                launcher.openPinMenu(tpin, tpin.modelData, tpin.entry, tpin.wins);
                                                return;
                                            }
                                            root.launcherOpen = false;
                                            if (mouse.button === Qt.MiddleButton || !tpin.running) root.launchApp(tpin.entry);
                                            else {
                                                // already open: bring it up (or the next one if it's focused)
                                                let next = 0;
                                                for (let i = 0; i < tpin.wins.length; i++)
                                                    if (tpin.wins[i].activated) { next = (i + 1) % tpin.wins.length; break; }
                                                tpin.wins[next].activate();
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        Text {
                            anchors.centerIn: parent
                            visible: taskRow.width === 0
                            text: "Right-click any app above to pin it here"
                            color: root.muted
                            font.pixelSize: 12
                        }
                    }
                }

                // ---- right-click menu for the taskbar apps ----
                Rectangle {
                    id: pinMenu
                    visible: launcher.menuItems.length > 0
                    x: Math.max(10, Math.min(card.width - width - 10, launcher.menuX - width / 2))
                    y: card.height - 92 - height
                    width: 200
                    height: pinMenuCol.implicitHeight + 12
                    radius: 14
                    color: root.bg
                    border.width: 1
                    border.color: root.glassEdge
                    z: 50
                    Column {
                        id: pinMenuCol
                        anchors.centerIn: parent
                        width: parent.width - 12
                        Repeater {
                            model: launcher.menuItems
                            delegate: Rectangle {
                                id: pmi
                                required property var modelData
                                width: pinMenuCol.width
                                height: 32
                                radius: 9
                                color: pmiMouse.containsMouse ? root.overlay : "transparent"
                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 10
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: pmi.modelData.text
                                    color: pmi.modelData.danger ? root.danger : root.fg
                                    font.pixelSize: 13
                                }
                                MouseArea {
                                    id: pmiMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        const act = pmi.modelData.action;
                                        launcher.menuItems = [];
                                        act();
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ---------- Control center (left panel) ----------
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: cc
            required property var modelData
            screen: modelData

            // Opens on whichever monitor has focus
            readonly property bool open: root.panelOpen
                && (!Hyprland.focusedMonitor || Hyprland.focusedMonitor.name === modelData.name)

            visible: open || card.x > -card.width - 4
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "quickshell-panel"
            exclusionMode: ExclusionMode.Ignore
            anchors {
                top: true
                bottom: true
                left: true
            }
            margins {
                top: 66
                bottom: 54
                left: 10
            }
            implicitWidth: 440
            color: "transparent"
            mask: Region { item: card }

            HyprlandFocusGrab {
                windows: [cc]
                active: cc.open
                onCleared: {
                    root.closeAll();
                    root.panelOpen = false;
                    root.panelClosedAt = Date.now();
                }
            }

            Rectangle {
                id: card
                width: 420
                height: parent.height
                x: cc.open ? 0 : -width - 20
                opacity: cc.open ? 1 : 0
                radius: 20
                color: root.popupBg
                border.width: 1
                border.color: root.glassEdge

                GlassShine { radius: parent.radius; dark: root.dark }

                Behavior on x { NumberAnimation { duration: root.animMs * 2; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: root.animMs * 2; easing.type: Easing.OutCubic } }

                readonly property var tiles: [
                    {
                        title: "Theme",
                        sub: root.themeLabel(),
                        active: false,
                        run: () => root.cycleTheme()
                    },
                    {
                        title: "Auto-hide bars",
                        sub: root.autoHideOn ? "On" : "Off",
                        active: root.autoHideOn,
                        run: () => root.cycleAutoHide()
                    },
                    {
                        title: "Wallpaper",
                        sub: "Pick a random one",
                        active: false,
                        run: () => root.randomWallpaper()
                    },
                    {
                        title: "Do not disturb",
                        sub: root.dnd ? "On" : "Off",
                        active: root.dnd,
                        run: () => { root.dnd = !root.dnd; }
                    }
                ]

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 12

                    // ---- Tabs ----
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 40
                        radius: 12
                        color: root.surface

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 4
                            spacing: 4

                            Repeater {
                                model: ["Settings", "Volume", "Performance"]

                                delegate: Rectangle {
                                    id: tabBtn
                                    required property string modelData
                                    required property int index
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    radius: 9
                                    color: root.tab === tabBtn.index ? root.accent : "transparent"
                                    Behavior on color { ColorAnimation { duration: root.animMs } }

                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 7

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: ["\uf013", "\uf028", "\uf0e4"][tabBtn.index]
                                            color: root.tab === tabBtn.index ? root.bg : root.accent
                                            font.family: root.iconFont
                                            font.pixelSize: 14
                                        }
                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: tabBtn.modelData
                                            color: root.tab === tabBtn.index ? root.bg : root.fg
                                            font.pixelSize: 13
                                            font.bold: root.tab === tabBtn.index
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: root.tab = tabBtn.index
                                    }
                                }
                            }
                        }
                    }

                    // ---- Tab pages ----
                    StackLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 210
                        currentIndex: root.tab

                        // Page 0: settings tiles
                        ColumnLayout {
                            spacing: 10

                            GridLayout {
                                Layout.fillWidth: true
                                columns: 2
                                rowSpacing: 8
                                columnSpacing: 8

                                Repeater {
                                    model: card.tiles

                                    delegate: Rectangle {
                                        id: tile
                                        required property var modelData
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 62
                                        radius: 14
                                        color: tile.modelData.active ? root.accent
                                             : (tileMouse.containsMouse ? root.overlay : root.surface)
                                        Behavior on color { ColorAnimation { duration: root.animMs } }

                                        ColumnLayout {
                                            anchors.fill: parent
                                            anchors.margins: 12
                                            spacing: 2

                                            Text {
                                                Layout.fillWidth: true
                                                text: tile.modelData.title
                                                color: tile.modelData.active ? root.bg : root.fg
                                                font.pixelSize: 14
                                                font.bold: true
                                                elide: Text.ElideRight
                                            }
                                            Text {
                                                Layout.fillWidth: true
                                                text: tile.modelData.sub
                                                color: tile.modelData.active ? root.bg : root.muted
                                                font.pixelSize: 11
                                                elide: Text.ElideRight
                                            }
                                        }

                                        MouseArea {
                                            id: tileMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onClicked: tile.modelData.run()
                                        }
                                    }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Text {
                                    text: "Wallpaper colors"
                                    color: root.muted
                                    font.pixelSize: 11
                                    Layout.fillWidth: true
                                }

                                Repeater {
                                    model: 5

                                    delegate: Rectangle {
                                        id: swatch
                                        required property int index
                                        Layout.preferredWidth: 22
                                        Layout.preferredHeight: 22
                                        radius: 11
                                        color: [root.seed, root.accent, root.fg, root.muted, root.bg][swatch.index]
                                        border.width: 1
                                        border.color: root.glassEdge
                                    }
                                }
                            }

                            Item { Layout.fillHeight: true }
                        }

                        // Page 1: volume
                        ColumnLayout {
                            spacing: 10

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Text {
                                    Layout.preferredWidth: 60
                                    text: "Output"
                                    color: root.fg
                                    font.pixelSize: 13
                                }
                                ValueBar {
                                    theme: root
                                    Layout.fillWidth: true
                                    value: root.sink && root.sink.audio ? root.sink.audio.volume : 0
                                    onMoved: v => {
                                        if (root.sink && root.sink.audio) root.sink.audio.volume = v;
                                    }
                                }
                                IconButton {
                                    theme: root
                                    implicitWidth: 66
                                    implicitHeight: 28
                                    label: root.sink && root.sink.audio && root.sink.audio.muted ? "Unmute" : "Mute"
                                    onClicked: {
                                        if (root.sink && root.sink.audio) root.sink.audio.muted = !root.sink.audio.muted;
                                    }
                                }
                            }

                            Text {
                                text: root.audioStreams.length > 0 ? "Apps" : "No apps are playing audio"
                                color: root.muted
                                font.pixelSize: 11
                            }

                            ListView {
                                id: streamList
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                clip: true
                                spacing: 8
                                model: root.audioStreams

                                delegate: RowLayout {
                                    id: sRow
                                    required property var modelData
                                    width: streamList.width
                                    spacing: 8

                                    Text {
                                        Layout.preferredWidth: 100
                                        text: (sRow.modelData.properties && sRow.modelData.properties["application.name"])
                                            || sRow.modelData.description || sRow.modelData.name
                                        color: root.fg
                                        font.pixelSize: 12
                                        elide: Text.ElideRight
                                    }
                                    ValueBar {
                                        theme: root
                                        Layout.fillWidth: true
                                        value: sRow.modelData.audio ? sRow.modelData.audio.volume : 0
                                        onMoved: v => {
                                            if (sRow.modelData.audio) sRow.modelData.audio.volume = v;
                                        }
                                    }
                                }
                            }
                        }

                        // Page 2: performance
                        ColumnLayout {
                            spacing: 14

                            Repeater {
                                model: 3

                                delegate: ColumnLayout {
                                    id: perf
                                    required property int index
                                    readonly property real amount: perf.index === 0 ? root.cpuUsage
                                        : (perf.index === 1 ? root.memUsage : root.swapUsage)
                                    Layout.fillWidth: true
                                    spacing: 4

                                    RowLayout {
                                        Layout.fillWidth: true

                                        Text {
                                            Layout.fillWidth: true
                                            text: ["CPU", "Memory", "Swap"][perf.index]
                                            color: root.fg
                                            font.pixelSize: 13
                                        }
                                        Text {
                                            text: Math.round(perf.amount * 100) + "%"
                                            color: root.muted
                                            font.pixelSize: 12
                                        }
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        implicitHeight: 8
                                        radius: 4
                                        color: root.surface

                                        Rectangle {
                                            width: parent.width * Math.max(0, Math.min(1, perf.amount))
                                            height: parent.height
                                            radius: 4
                                            color: root.accent
                                            Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                                        }
                                    }
                                }
                            }

                            Text {
                                text: "Load average   " + root.loadAvg
                                color: root.muted
                                font.pixelSize: 12
                            }

                            Item { Layout.fillHeight: true }
                        }
                    }

                    // ---- Media ----
                    Rectangle {
                        visible: root.player !== null
                        Layout.fillWidth: true
                        implicitHeight: 84
                        radius: 14
                        color: root.surface

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 12

                            Rectangle {
                                Layout.preferredWidth: 64
                                Layout.preferredHeight: 64
                                radius: 10
                                color: root.overlay
                                clip: true

                                Image {
                                    anchors.fill: parent
                                    source: root.player ? root.player.trackArtUrl : ""
                                    fillMode: Image.PreserveAspectCrop
                                    visible: status === Image.Ready
                                }
                                Text {
                                    anchors.centerIn: parent
                                    text: "♪"
                                    color: root.muted
                                    font.pixelSize: 22
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    Layout.fillWidth: true
                                    text: root.player ? (root.player.trackTitle || root.player.identity) : ""
                                    color: root.fg
                                    font.pixelSize: 13
                                    font.bold: true
                                    elide: Text.ElideRight
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: root.player ? root.player.trackArtist : ""
                                    color: root.muted
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                }
                                RowLayout {
                                    spacing: 6

                                    IconButton {
                                        theme: root
                                        implicitWidth: 38
                                        implicitHeight: 26
                                        label: "|◀"
                                        dim: !(root.player && root.player.canGoPrevious)
                                        onClicked: if (root.player && root.player.canGoPrevious) root.player.previous()
                                    }
                                    IconButton {
                                        theme: root
                                        implicitWidth: 46
                                        implicitHeight: 26
                                        label: root.playing(root.player) ? "❚❚" : "▶"
                                        dim: !(root.player && root.player.canTogglePlaying)
                                        onClicked: if (root.player && root.player.canTogglePlaying) root.player.togglePlaying()
                                    }
                                    IconButton {
                                        theme: root
                                        implicitWidth: 38
                                        implicitHeight: 26
                                        label: "▶|"
                                        dim: !(root.player && root.player.canGoNext)
                                        onClicked: if (root.player && root.player.canGoNext) root.player.next()
                                    }
                                }
                            }
                        }
                    }

                    // ---- Notifications ----
                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            Layout.fillWidth: true
                            text: "Notifications"
                            color: root.fg
                            font.pixelSize: 14
                            font.bold: true
                        }
                        IconButton {
                            theme: root
                            implicitWidth: 84
                            implicitHeight: 28
                            label: "Clear all"
                            onClicked: root.clearNotifications()
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        ListView {
                            id: notifList
                            anchors.fill: parent
                            clip: true
                            spacing: 8
                            model: notifServer.trackedNotifications

                            delegate: Rectangle {
                                id: nCard
                                required property var modelData
                                width: notifList.width
                                height: nCol.implicitHeight + 20
                                radius: 14
                                border.width: nCard.modelData.urgency === NotificationUrgency.Critical ? 1 : 0
                                border.color: root.danger
                                color: nOpen.containsMouse ? root.overlay : root.surface

                                // click anywhere on it: open the app it came from
                                MouseArea {
                                    id: nOpen
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.openNotification(nCard.modelData)
                                }

                                ColumnLayout {
                                    id: nCol
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 2

                                    RowLayout {
                                        Layout.fillWidth: true

                                        Text {
                                            Layout.fillWidth: true
                                            text: nCard.modelData.appName
                                            color: root.muted
                                            font.pixelSize: 11
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            text: "×"
                                            color: root.muted
                                            font.pixelSize: 16

                                            MouseArea {
                                                anchors.fill: parent
                                                anchors.margins: -6
                                                onClicked: nCard.modelData.dismiss()
                                            }
                                        }
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        text: nCard.modelData.summary
                                        color: root.fg
                                        font.pixelSize: 13
                                        font.bold: true
                                        wrapMode: Text.Wrap
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        visible: text !== ""
                                        text: nCard.modelData.body
                                        color: root.muted
                                        font.pixelSize: 12
                                        wrapMode: Text.Wrap
                                        maximumLineCount: 3
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: notifList.count === 0
                            text: "No notifications"
                            color: root.muted
                            font.pixelSize: 13
                        }
                    }
                }
            }
        }
    }

    // ---------- Notification pop-ups (top right) ----------
    PanelWindow {
        id: toastWin
        visible: toastModel.count > 0
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell-toast"
        exclusionMode: ExclusionMode.Ignore
        anchors {
            top: true
            right: true
        }
        margins {
            top: 66
            right: 12
        }
        implicitWidth: 360
        implicitHeight: toastCol.implicitHeight
        color: "transparent"
        mask: Region { item: toastCol }

        Column {
            id: toastCol
            width: 360
            spacing: 8

            Repeater {
                model: toastModel

                delegate: Item {
                    id: toast
                    required property int tid
                    required property int nid
                    required property string summary
                    required property string body
                    required property string appName
                    required property bool critical
                    readonly property string icon: root.findIcon([toast.appName, toast.appName.toLowerCase(), toast.appName.toLowerCase().replace(/ /g, "-")])
                    width: toastCol.width
                    height: toastCard.height

                    // slides in from the right with a little bounce
                    Rectangle {
                        id: toastCard
                        width: parent.width
                        height: toastRow.implicitHeight + 30
                        radius: 22
                        color: root.popupBg
                        border.width: 1
                        border.color: toast.critical ? root.danger : root.glassEdge
                        opacity: 0
                        x: 40
                        scale: toastHover.hovered ? 1.02 : 1
                        NumberAnimation on opacity { running: true; from: 0; to: 1; duration: root.animMs * 2 }
                        NumberAnimation on x { running: true; from: 40; to: 0; duration: root.animMs * 3; easing.type: Easing.OutBack }
                        Behavior on scale { NumberAnimation { duration: root.animMs; easing.type: Easing.OutBack } }

                        GlassShine { radius: parent.radius; dark: root.dark }

                        HoverHandler { id: toastHover }

                        // time left: a thin bright line along the bottom that shrinks
                        // (hovering the pop-up pauses it)
                        Rectangle {
                            id: toastLife
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 6
                            x: 22
                            height: 2
                            radius: 1
                            width: (parent.width - 44) * toast.timeLeft
                            color: toast.critical ? root.danger : Qt.rgba(1, 1, 1, root.dark ? 0.45 : 0.8)
                        }

                        RowLayout {
                            id: toastRow
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 14
                            spacing: 12

                            // app icon in a little glass bubble
                            Rectangle {
                                Layout.preferredWidth: 40
                                Layout.preferredHeight: 40
                                Layout.alignment: Qt.AlignTop
                                radius: 14
                                color: root.overlay
                                border.width: 1
                                border.color: root.glassEdge
                                GlassShine { radius: parent.radius; dark: root.dark; strength: 0.7 }
                                IconImage {
                                    anchors.centerIn: parent
                                    visible: toast.icon !== ""
                                    implicitSize: 26
                                    source: toast.icon
                                }
                                Text {
                                    anchors.centerIn: parent
                                    visible: toast.icon === ""
                                    text: "\uf0f3"
                                    color: toast.critical ? root.danger : root.accent
                                    font.family: root.iconFont
                                    font.pixelSize: 16
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    Layout.fillWidth: true
                                    text: toast.appName
                                    color: root.muted
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: toast.summary
                                    color: root.fg
                                    font.pixelSize: 14
                                    font.bold: true
                                    wrapMode: Text.Wrap
                                }
                                Text {
                                    Layout.fillWidth: true
                                    visible: text !== ""
                                    text: toast.body
                                    color: root.muted
                                    font.pixelSize: 12
                                    wrapMode: Text.Wrap
                                    maximumLineCount: 3
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        // click: open the app it came from
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.openNotification(root.notifById(toast.nid));
                                root.removeToast(toast.tid);
                            }
                        }

                        // small × in the corner: just close the pop-up
                        Rectangle {
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.margins: 10
                            width: 22
                            height: 22
                            radius: 11
                            visible: toastHover.hovered
                            color: toastX.containsMouse ? root.overlay : "transparent"
                            Text {
                                anchors.centerIn: parent
                                text: "\uf00d"
                                color: root.muted
                                font.family: root.iconFont
                                font.pixelSize: 11
                            }
                            MouseArea {
                                id: toastX
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.removeToast(toast.tid)
                            }
                        }
                    }

                    // 6 seconds on screen, paused while hovered
                    property real timeLeft: 1
                    Timer {
                        interval: 50
                        repeat: true
                        running: !toastHover.hovered
                        onTriggered: {
                            toast.timeLeft -= 50 / 6000;
                            if (toast.timeLeft <= 0) {
                                running = false;
                                root.removeToast(toast.tid);
                            }
                        }
                    }
                }
            }
        }
    }

    // ---------- Weather panel (right) ----------
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: wcc
            required property var modelData
            screen: modelData

            // Opens on whichever monitor has focus
            readonly property bool open: root.weatherOpen
                && (!Hyprland.focusedMonitor || Hyprland.focusedMonitor.name === modelData.name)

            visible: open || wcard.x < wcc.width - 4
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "quickshell-weather"
            exclusionMode: ExclusionMode.Ignore
            anchors {
                top: true
                bottom: true
                right: true
            }
            margins {
                top: 66
                bottom: 54
                right: 10
            }
            implicitWidth: 380
            color: "transparent"
            mask: Region { item: wcard }

            HyprlandFocusGrab {
                windows: [wcc]
                active: wcc.open
                onCleared: {
                    root.closeAll();
                    root.weatherClosedAt = Date.now();
                }
            }

            Rectangle {
                id: wcard
                width: 360
                height: parent.height
                x: wcc.open ? 20 : wcc.width + 20
                opacity: wcc.open ? 1 : 0
                radius: 20
                color: root.popupBg
                border.width: 1
                border.color: root.glassEdge

                GlassShine { radius: parent.radius; dark: root.dark }

                Behavior on x { NumberAnimation { duration: root.animMs * 2; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: root.animMs * 2; easing.type: Easing.OutCubic } }

                readonly property string deg: "°"
                readonly property var stats: root.wxNow ? [
                    { label: "Humidity", value: root.wxNow.humidity + "%" },
                    { label: "Pressure", value: root.wxNow.pressure + " hPa" },
                    { label: "Wind", value: root.wxNow.wind + (root.weatherMetric ? " km/h" : " mph") },
                    { label: "UV index", value: String(root.wxNow.uv) },
                    { label: "Sunrise", value: root.wxNow.sunrise },
                    { label: "Sunset", value: root.wxNow.sunset }
                ] : []

                Flickable {
                    anchors.fill: parent
                    anchors.margins: 14
                    contentWidth: width
                    contentHeight: wcol.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    ColumnLayout {
                        id: wcol
                        width: parent.width
                        spacing: 12

                        // ---- Current conditions ----
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 128
                            radius: 16
                            color: root.surface

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 16
                                spacing: 12

                                ColumnLayout {
                                    spacing: 0

                                    Text {
                                        text: root.weatherName
                                        color: root.muted
                                        font.pixelSize: 12
                                    }
                                    Text {
                                        text: root.wxNow ? root.wxNow.temp + wcard.deg : "--"
                                        color: root.fg
                                        font.pixelSize: 44
                                        font.bold: true
                                    }
                                    Text {
                                        text: root.wxNow
                                            ? root.wxNow.desc + "  ·  Feels like " + root.wxNow.feels + wcard.deg
                                            : root.wxStatus
                                        color: root.muted
                                        font.pixelSize: 12
                                    }
                                    Text {
                                        visible: root.wxNow !== null
                                        text: root.wxNow ? "H " + root.wxNow.hi + wcard.deg + "   L " + root.wxNow.lo + wcard.deg : ""
                                        color: root.muted
                                        font.pixelSize: 12
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                ColumnLayout {
                                    spacing: 6

                                    Text {
                                        Layout.alignment: Qt.AlignRight
                                        text: root.wxNow ? root.wxNow.icon : "☁"
                                        color: root.accent
                                        font.pixelSize: 54
                                    }
                                    IconButton {
                                        theme: root
                                        Layout.alignment: Qt.AlignRight
                                        implicitWidth: 76
                                        implicitHeight: 26
                                        label: "Refresh"
                                        onClicked: {
                                            root.wxStatus = "Loading weather...";
                                            root.fetchWeather();
                                        }
                                    }
                                }
                            }
                        }

                        // ---- Hourly forecast ----
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: hourCol.implicitHeight + 24
                            radius: 16
                            color: root.surface

                            ColumnLayout {
                                id: hourCol
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 8

                                Text {
                                    text: "Hourly forecast"
                                    color: root.fg
                                    font.pixelSize: 13
                                    font.bold: true
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 0

                                    Repeater {
                                        model: root.wxHours

                                        delegate: ColumnLayout {
                                            id: hourItem
                                            required property var modelData
                                            Layout.fillWidth: true
                                            spacing: 2

                                            Text {
                                                Layout.alignment: Qt.AlignHCenter
                                                text: hourItem.modelData.label
                                                color: root.muted
                                                font.pixelSize: 11
                                            }
                                            Text {
                                                Layout.alignment: Qt.AlignHCenter
                                                text: hourItem.modelData.icon
                                                color: root.accent
                                                font.pixelSize: 18
                                            }
                                            Text {
                                                Layout.alignment: Qt.AlignHCenter
                                                text: hourItem.modelData.temp + wcard.deg
                                                color: root.fg
                                                font.pixelSize: 12
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // ---- Daily forecast ----
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: dayCol.implicitHeight + 24
                            radius: 16
                            color: root.surface

                            ColumnLayout {
                                id: dayCol
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 8

                                Text {
                                    text: "Daily forecast"
                                    color: root.fg
                                    font.pixelSize: 13
                                    font.bold: true
                                }

                                Repeater {
                                    model: root.wxDays

                                    delegate: RowLayout {
                                        id: dayItem
                                        required property var modelData
                                        Layout.fillWidth: true
                                        spacing: 8

                                        Text {
                                            Layout.preferredWidth: 52
                                            text: dayItem.modelData.day
                                            color: root.fg
                                            font.pixelSize: 12
                                        }
                                        Text {
                                            text: dayItem.modelData.icon
                                            color: root.accent
                                            font.pixelSize: 16
                                        }
                                        Text {
                                            Layout.fillWidth: true
                                            text: dayItem.modelData.rain > 0 ? dayItem.modelData.rain + "%" : ""
                                            color: root.muted
                                            font.pixelSize: 11
                                        }
                                        Text {
                                            text: dayItem.modelData.lo + wcard.deg
                                            color: root.muted
                                            font.pixelSize: 12
                                        }
                                        Text {
                                            Layout.preferredWidth: 34
                                            horizontalAlignment: Text.AlignRight
                                            text: dayItem.modelData.hi + wcard.deg
                                            color: root.fg
                                            font.pixelSize: 12
                                            font.bold: true
                                        }
                                    }
                                }
                            }
                        }

                        // ---- Details ----
                        GridLayout {
                            Layout.fillWidth: true
                            columns: 3
                            rowSpacing: 8
                            columnSpacing: 8

                            Repeater {
                                model: wcard.stats

                                delegate: Rectangle {
                                    id: stat
                                    required property var modelData
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 62
                                    radius: 14
                                    color: root.surface

                                    ColumnLayout {
                                        anchors.centerIn: parent
                                        spacing: 2

                                        Text {
                                            Layout.alignment: Qt.AlignHCenter
                                            text: stat.modelData.label
                                            color: root.muted
                                            font.pixelSize: 11
                                        }
                                        Text {
                                            Layout.alignment: Qt.AlignHCenter
                                            text: stat.modelData.value
                                            color: root.fg
                                            font.pixelSize: 14
                                            font.bold: true
                                        }
                                    }
                                }
                            }
                        }

                        Item { Layout.preferredHeight: 4 }
                    }
                }
            }
        }
    }

    // ---------- Desktop switch pop-up (bottom centre) ----------
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: osd
            required property var modelData
            screen: modelData

            readonly property bool mine: !Hyprland.focusedMonitor || Hyprland.focusedMonitor.name === modelData.name
            readonly property var ids: root.deskMap[modelData.name] || []
            readonly property int activeId: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : -1
            readonly property int position: ids.indexOf(activeId) + 1

            visible: (root.osdShow && mine) || osdCard.opacity > 0.01
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell-osd"
            exclusionMode: ExclusionMode.Ignore
            anchors {
                bottom: true
            }
            margins {
                bottom: 110
            }
            implicitWidth: osdCard.width
            implicitHeight: osdCard.height
            color: "transparent"
            mask: Region {}

            Rectangle {
                id: osdCard
                width: osdRow.implicitWidth + 44
                height: 56
                radius: 28
                color: root.popupBg
                border.width: 1
                border.color: root.glassEdge
                opacity: (root.osdShow && osd.mine) ? 1 : 0

                GlassShine { radius: parent.radius; dark: root.dark }
                scale: (root.osdShow && osd.mine) ? 1 : 0.9
                Behavior on opacity { NumberAnimation { duration: root.animMs * 2; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: root.animMs * 2; easing.type: Easing.OutBack } }

                Row {
                    id: osdRow
                    anchors.centerIn: parent
                    spacing: 8

                    Repeater {
                        model: osd.ids

                        delegate: Rectangle {
                            id: dot
                            required property var modelData
                            anchors.verticalCenter: parent.verticalCenter
                            width: dot.modelData === osd.activeId ? 38 : 12
                            height: 12
                            radius: 6
                            color: dot.modelData === osd.activeId ? root.accent : root.overlay
                            Behavior on width { NumberAnimation { duration: root.animMs * 2; easing.type: Easing.OutBack } }
                            Behavior on color { ColorAnimation { duration: root.animMs } }
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: osd.position > 0
                        text: "Desktop " + osd.position
                        color: root.fg
                        font.pixelSize: 14
                        font.bold: true
                    }
                }
            }
        }
    }
    // ---------- Desktop switcher window (Super+Tab) ----------
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: sw
            required property var modelData
            screen: modelData

            visible: root.switcherOpen
                && (!Hyprland.focusedMonitor || Hyprland.focusedMonitor.name === modelData.name)

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell-deskswitch"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            exclusionMode: ExclusionMode.Ignore
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            color: "#2a000000"

            readonly property int current: root.currentDeskIndex()

            onVisibleChanged: if (visible) swKeys.forceActiveFocus()

            // Click outside the card to close without switching
            MouseArea {
                anchors.fill: parent
                onClicked: root.switcherOpen = false
            }

            Item {
                id: swKeys
                focus: true
                Keys.onPressed: event => {
                    const k = event.key;
                    if (k === Qt.Key_Escape) root.switcherOpen = false;
                    else if (k === Qt.Key_Right || k === Qt.Key_Tab || k === Qt.Key_Down) root.switcherStep(1);
                    else if (k === Qt.Key_Left || k === Qt.Key_Backtab || k === Qt.Key_Up) root.switcherStep(-1);
                    else if (k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_Space) root.switcherCommit();
                    else if (k >= Qt.Key_1 && k <= Qt.Key_9 && k - Qt.Key_1 < root.deskCount) {
                        root.switcherSel = k - Qt.Key_1;
                        root.switcherCommit();
                    } else return;
                    event.accepted = true;
                }
                // Letting go of Super switches (like Alt+Tab)
                Keys.onReleased: event => {
                    const k = event.key;
                    if (k === Qt.Key_Super_L || k === Qt.Key_Super_R || k === Qt.Key_Meta) {
                        root.switcherCommit();
                        event.accepted = true;
                    }
                }
            }

            Rectangle {
                id: swCard
                anchors.centerIn: parent
                width: Math.min(swRow.implicitWidth + 48, sw.width - 80)
                height: swCol.implicitHeight + 44
                radius: 30
                color: root.popupBg
                border.width: 1
                border.color: root.glassEdge
                clip: true
                opacity: 0
                scale: 0.92
                NumberAnimation on opacity { running: sw.visible; from: 0; to: 1; duration: root.animMs * 1.5; easing.type: Easing.OutCubic }
                NumberAnimation on scale { running: sw.visible; from: 0.92; to: 1; duration: root.animMs * 2; easing.type: Easing.OutBack }

                GlassShine { radius: parent.radius; dark: root.dark }
                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    gradient: Gradient {
                        GradientStop { position: 0.55; color: "transparent" }
                        GradientStop { position: 1.0; color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, root.dark ? 0.12 : 0.08) }
                    }
                }

                MouseArea { anchors.fill: parent }   // clicks inside don't close it

                Column {
                    id: swCol
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 22
                    spacing: 16

                    // ---- Title ----
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 10
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: ""
                            color: root.accent
                            font.family: root.iconFont
                            font.pixelSize: 16
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Desktops"
                            color: root.fg
                            font.pixelSize: 17
                            font.bold: true
                        }
                        Buddy { theme: root; slot: 3; size: 30; anchors.verticalCenter: parent.verticalCenter }
                    }

                    // ---- One card per desktop, plus "+" ----
                    Flickable {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: Math.min(swRow.implicitWidth, sw.width - 128)
                        height: swRow.implicitHeight
                        contentWidth: swRow.implicitWidth
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        Row {
                            id: swRow
                            spacing: 16
                            padding: 8

                            Repeater {
                                model: root.deskCount

                                delegate: Rectangle {
                                    id: dcard
                                    required property int index
                                    readonly property bool sel: root.switcherSel === dcard.index
                                    readonly property bool isCurrent: sw.current === dcard.index
                                    readonly property var apps: {
                                        Hyprland.workspaces.values;      // refresh when windows move
                                        return sw.visible ? root.deskApps(dcard.index) : [];
                                    }
                                    width: 210
                                    height: 170
                                    radius: 22
                                    color: dcard.sel ? root.overlay : root.surface
                                    border.width: dcard.sel ? 3 : 1
                                    border.color: dcard.sel ? root.accent : root.glassEdge
                                    scale: dcard.sel ? 1.06 : (dcardHover.hovered ? 1.02 : 1)
                                    Behavior on scale { NumberAnimation { duration: root.animMs * 1.5; easing.type: Easing.OutBack } }
                                    Behavior on color { ColorAnimation { duration: root.animMs } }

                                    HoverHandler { id: dcardHover }

                                    // gloss on each card
                                    Rectangle {
                                        anchors.fill: parent
                                        radius: parent.radius
                                        gradient: Gradient {
                                            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, root.dark ? 0.07 : 0.3) }
                                            GradientStop { position: 0.45; color: Qt.rgba(1, 1, 1, 0) }
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.switcherSel = dcard.index;
                                            root.switcherCommit();
                                        }
                                    }

                                    // number + name
                                    Row {
                                        x: 14
                                        y: 14
                                        spacing: 10
                                        Rectangle {
                                            width: 34
                                            height: 34
                                            radius: 17
                                            color: dcard.sel || dcard.isCurrent ? root.accent : root.overlay
                                            Text {
                                                anchors.centerIn: parent
                                                text: dcard.index + 1
                                                color: dcard.sel || dcard.isCurrent ? root.bg : root.fg
                                                font.pixelSize: 15
                                                font.bold: true
                                            }
                                        }
                                        Column {
                                            anchors.verticalCenter: parent.verticalCenter
                                            Text {
                                                text: "Desktop " + (dcard.index + 1)
                                                color: root.fg
                                                font.pixelSize: 13
                                                font.bold: true
                                            }
                                            Text {
                                                text: dcard.isCurrent ? "You're here"
                                                    : (dcard.apps.length === 0 ? "Empty"
                                                    : dcard.apps.length + (dcard.apps.length === 1 ? " window" : " windows"))
                                                color: dcard.isCurrent ? root.accent : root.muted
                                                font.pixelSize: 11
                                            }
                                        }
                                    }

                                    // delete (×), shows on hover when there's more than one desktop
                                    Rectangle {
                                        visible: dcardHover.hovered && root.deskCount > 1
                                        anchors.top: parent.top
                                        anchors.right: parent.right
                                        anchors.margins: 10
                                        width: 26
                                        height: 26
                                        radius: 13
                                        color: delMouse.containsMouse ? root.danger : root.overlay
                                        Text {
                                            anchors.centerIn: parent
                                            text: ""
                                            color: delMouse.containsMouse ? root.bg : root.fg
                                            font.family: root.iconFont
                                            font.pixelSize: 11
                                        }
                                        MouseArea {
                                            id: delMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                root.removeDeskIndex(dcard.index);
                                                root.switcherSel = Math.min(root.switcherSel, root.deskCount - 1);
                                            }
                                        }
                                    }

                                    // app icons on this desktop
                                    Grid {
                                        x: 14
                                        y: 62
                                        columns: 4
                                        spacing: 8
                                        visible: dcard.apps.length > 0

                                        Repeater {
                                            model: dcard.apps.slice(0, dcard.apps.length > 8 ? 7 : 8)
                                            delegate: Rectangle {
                                                id: appIco
                                                required property var modelData
                                                width: 38
                                                height: 38
                                                radius: 11
                                                color: root.bg
                                                border.width: 1
                                                border.color: root.glassEdge
                                                IconImage {
                                                    anchors.centerIn: parent
                                                    implicitSize: 26
                                                    source: Quickshell.iconPath(appIco.modelData.appId, "application-x-executable")
                                                }
                                            }
                                        }
                                        Rectangle {
                                            visible: dcard.apps.length > 8
                                            width: 38
                                            height: 38
                                            radius: 11
                                            color: root.overlay
                                            Text {
                                                anchors.centerIn: parent
                                                text: "+" + (dcard.apps.length - 7)
                                                color: root.fg
                                                font.pixelSize: 12
                                                font.bold: true
                                            }
                                        }
                                    }

                                    Text {
                                        visible: dcard.apps.length === 0
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        y: 92
                                        text: ""
                                        color: root.muted
                                        opacity: 0.5
                                        font.family: root.iconFont
                                        font.pixelSize: 30
                                    }
                                }
                            }

                            // ---- add a desktop ----
                            Rectangle {
                                visible: root.deskCount < root.maxDesktops
                                width: 110
                                height: 170
                                radius: 22
                                color: addMouse.containsMouse ? root.overlay : "transparent"
                                border.width: 2
                                border.color: addMouse.containsMouse ? root.accent : root.glassEdge
                                scale: addMouse.pressed ? 0.95 : (addMouse.containsMouse ? 1.03 : 1)
                                Behavior on scale { NumberAnimation { duration: root.animMs; easing.type: Easing.OutBack } }
                                Behavior on color { ColorAnimation { duration: root.animMs } }

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 6
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "+"
                                        color: root.accent
                                        font.pixelSize: 34
                                    }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "New desktop"
                                        color: root.fg
                                        font.pixelSize: 12
                                    }
                                }
                                MouseArea {
                                    id: addMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.switcherOpen = false;
                                        root.addDesktop(root.focusedMonitorName());
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Hold Super + Tab to move      let go to switch      ← →  1–9  Enter  click      Esc  cancel"
                        color: root.muted
                        font.pixelSize: 11
                        opacity: 0.85
                    }
                }
            }
        }
    }

    // ---------- Left panel: Lyrics, Display, Clipboard, Notes (pull tab on the left edge) ----------
    // Click the tab on the left edge to open big, colourful lyrics that follow Spotify.
    // It stays on screen until you press its close button, and takes its colours from the theme.
    readonly property bool lyricsOpen: pins.adapter.lyricsOpen
    property string lyricsScreen: ""      // which monitor the panel is on
    onLyricsOpenChanged: if (lyricsOpen) fetchLyrics()

    // colours for the lyrics, taken from the theme (and the wallpaper on the neutral glass theme)
    readonly property var lyricsColors: {
        const lift = c => {
            const col = Qt.color(c);
            return Qt.hsla(col.hslHue < 0 ? 0 : col.hslHue, Math.max(0.45, col.hslSaturation),
                           dark ? Math.max(0.68, col.hslLightness) : Math.min(0.40, col.hslLightness), 1);
        };
        if (glassTheme) {
            const p = wallPalette;
            if (p.length >= 2) return [dark ? "#ffffff" : "#1b1c20", lift(p[0]), lift(p[1])];
            return [dark ? "#ffffff" : "#1b1c20", dark ? "#c9d6ff" : "#3a4a7a", dark ? "#ffd6f0" : "#7a3a5a"];
        }
        const l = dark ? 0.72 : 0.38, s = Math.max(0.55, sat);
        return [accentBase, Qt.hsla((hue + 0.08) % 1, s, l, 1), Qt.hsla((hue + 0.92) % 1, s, l, 1)];
    }

    function openLyricsPanel(screenName) {
        lyricsScreen = screenName;
        pins.adapter.lyricsOpen = true;
    }
    function closeLyricsPanel() {
        pins.adapter.lyricsOpen = false;
    }
    // "some words" -> each word tinted a step further along lyricsColors (as rich text)
    function gradientWords(line) {
        const words = line.split(" ");
        const c = lyricsColors.map(x => Qt.color(x));
        const mix = (a, b, f) => Qt.rgba(a.r + (b.r - a.r) * f, a.g + (b.g - a.g) * f, a.b + (b.b - a.b) * f, 1);
        const hex = v => ("0" + Math.round(v * 255).toString(16)).slice(-2);
        const esc = s => s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
        const out = [];
        for (let i = 0; i < words.length; i++) {
            const f = words.length > 1 ? i / (words.length - 1) : 0;
            const col = f < 0.5 ? mix(c[0], c[1], f * 2) : mix(c[1], c[2], (f - 0.5) * 2);
            out.push('<font color="#' + hex(col.r) + hex(col.g) + hex(col.b) + '">' + esc(words[i]) + "</font>");
        }
        return out.join(" ");
    }

    // ----- Left panel tabs -----
    readonly property var leftTabs: [
        { id: "lyrics",  name: "Lyrics",    icon: "" },
        { id: "display", name: "Display",   icon: "" },
        { id: "clip",    name: "Clipboard", icon: "" },
        { id: "notes",   name: "Notes",     icon: "" }
    ]
    readonly property string leftTab: pins.adapter.leftTab || "lyrics"

    // ----- Display tab: screen colours (a Hyprland screen shader) -----
    readonly property int dispSat: pins.adapter.dispSat
    readonly property int dispCon: pins.adapter.dispCon
    readonly property int dispTemp: pins.adapter.dispTemp
    readonly property int dispBri: pins.adapter.dispBri
    readonly property var displayPresets: [
        { name: "Normal",    sat: 100, con: 100, temp: 6500, bri: 100 },
        { name: "Vivid",     sat: 140, con: 110, temp: 6500, bri: 100 },
        { name: "Cinema",    sat: 115, con: 115, temp: 5600, bri: 95 },
        { name: "Soft",      sat: 80,  con: 90,  temp: 6000, bri: 105 },
        { name: "Warm",      sat: 105, con: 100, temp: 4500, bri: 100 },
        { name: "Night",     sat: 90,  con: 95,  temp: 3400, bri: 85 },
        { name: "Grayscale", sat: 0,   con: 105, temp: 6500, bri: 100 }
    ]
    property bool dispFlip: false

    function setDisplay(s, c, t, b) {
        pins.adapter.dispSat = s;
        pins.adapter.dispCon = c;
        pins.adapter.dispTemp = t;
        pins.adapter.dispBri = b;
        displayTimer.restart();
    }
    function setDisplayValue(key, v) {
        if (key === "sat") pins.adapter.dispSat = v;
        else if (key === "con") pins.adapter.dispCon = v;
        else if (key === "temp") pins.adapter.dispTemp = v;
        else pins.adapter.dispBri = v;
        displayTimer.restart();
    }
    // colour of light at a temperature (Kelvin), as red/green/blue multipliers
    function kelvinRgb(k) {
        const f = kk => {
            const t = kk / 100;
            const r = t <= 66 ? 255 : 329.698727446 * Math.pow(t - 60, -0.1332047592);
            const g = t <= 66 ? 99.4708025861 * Math.log(t) - 161.1195681661 : 288.1221695283 * Math.pow(t - 60, -0.0755148492);
            const b = t >= 66 ? 255 : (t <= 19 ? 0 : 138.5177312231 * Math.log(t - 10) - 305.0447927307);
            return [r, g, b].map(v => Math.max(0, Math.min(255, v)));
        };
        const c = f(k), w = f(6500);
        return c.map((v, i) => Math.min(1, v / w[i]));
    }
    function displayShader() {
        const n = v => Number(v).toFixed(4);
        const w = kelvinRgb(dispTemp);
        return [
            "#version 300 es",
            "// Made by the JoeOS bar (Display tab). Do not edit by hand.",
            "precision highp float;",
            "in vec2 v_texcoord;",
            "uniform sampler2D tex;",
            "out vec4 fragColor;",
            "void main() {",
            "    vec4 c = texture(tex, v_texcoord);",
            "    vec3 col = c.rgb;",
            "    float l = dot(col, vec3(0.2126, 0.7152, 0.0722));",
            "    col = mix(vec3(l), col, " + n(dispSat / 100) + ");",
            "    col = (col - 0.5) * " + n(dispCon / 100) + " + 0.5;",
            "    col *= " + n(dispBri / 100) + ";",
            "    col *= vec3(" + n(w[0]) + ", " + n(w[1]) + ", " + n(w[2]) + ");",
            "    fragColor = vec4(clamp(col, 0.0, 1.0), c.a);",
            "}"
        ].join("\n");
    }
    function applyDisplay() {
        const lua = p => 'hl.config({ decoration = { screen_shader = "' + p + '" } })';
        const plain = dispSat === 100 && dispCon === 100 && dispTemp >= 6500 && dispBri === 100;
        if (plain || gameMode) {
            Quickshell.execDetached(["hyprctl", "eval", lua("")]);
            return;
        }
        // Hyprland only re-reads a shader when the file name changes, so swap between two
        dispFlip = !dispFlip;
        const path = Quickshell.env("HOME") + "/.cache/joeos/screen-" + (dispFlip ? "a" : "b") + ".frag";
        Quickshell.execDetached(["sh", "-c",
            'mkdir -p "$(dirname "$2")" && printf "%s\\n" "$1" > "$2" && hyprctl eval "$3"',
            "sh", displayShader(), path, lua(path)]);
    }
    Timer {
        id: displayTimer
        interval: 120
        onTriggered: root.applyDisplay()
    }
    // put the screen colours back after starting up, and after game mode reloads Hyprland
    Timer {
        id: displayRestore
        interval: 3000
        running: true
        onTriggered: root.applyDisplay()
    }

    // ----- Clipboard tab (cliphist) -----
    property var clipItems: []
    property bool clipHave: true
    property string clipJustCopied: ""
    Process {
        id: clipList
        command: ["sh", "-c", "command -v cliphist >/dev/null 2>&1 || { echo NOCLIP; exit 0; }; cliphist list 2>/dev/null | head -n 200"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim() === "NOCLIP") {
                    root.clipHave = false;
                    root.clipItems = [];
                    return;
                }
                root.clipHave = true;
                const out = [];
                const lines = text.split("\n");
                for (let i = 0; i < lines.length; i++) {
                    const line = lines[i];
                    const tab = line.indexOf("\t");
                    if (tab < 0) continue;
                    const body = line.slice(tab + 1);
                    out.push({ line: line, text: body, image: /^\[\[ binary data/.test(body) });
                }
                root.clipItems = out;
            }
        }
    }
    function clipRefresh() { if (!clipList.running) clipList.running = true; }
    function clipCopy(line) {
        Quickshell.execDetached(["sh", "-c", 'printf "%s" "$1" | cliphist decode | wl-copy', "sh", line]);
        clipJustCopied = line;
        clipCopiedTimer.restart();
    }
    function clipDelete(line) {
        Quickshell.execDetached(["sh", "-c", 'printf "%s" "$1" | cliphist delete', "sh", line]);
        clipItems = clipItems.filter(x => x.line !== line);
    }
    function clipWipe() {
        Quickshell.execDetached(["cliphist", "wipe"]);
        clipItems = [];
    }
    Timer { id: clipCopiedTimer; interval: 1400; onTriggered: root.clipJustCopied = "" }
    Timer {
        interval: 2000
        repeat: true
        triggeredOnStart: true
        running: root.lyricsOpen && root.leftTab === "clip"
        onTriggered: root.clipRefresh()
    }
    // keep a history from now on (starts cliphist's watcher if it isn't running)
    Timer {
        interval: 4000
        running: true
        onTriggered: Quickshell.execDetached(["sh", "-c",
            'command -v cliphist >/dev/null && command -v wl-paste >/dev/null || exit 0; '
            + 'pgrep -f "wl-paste --type text --watch cliphist" >/dev/null || setsid -f wl-paste --type text --watch cliphist store; '
            + 'pgrep -f "wl-paste --type image --watch cliphist" >/dev/null || setsid -f wl-paste --type image --watch cliphist store'])
    }

    // ----- Notes tab -----
    property string notesText: ""
    readonly property string notesPath: Quickshell.env("HOME") + "/.local/state/joeos-notes.txt"
    FileView {
        id: notesFile
        path: root.notesPath
        onLoaded: root.notesText = text()
    }
    Timer {
        id: notesSave
        interval: 600
        onTriggered: Quickshell.execDetached(["sh", "-c", 'mkdir -p "$(dirname "$2")" && printf "%s" "$1" > "$2"',
            "sh", root.notesText, root.notesPath])
    }

    Variants {
        model: Quickshell.screens

        Scope {
            id: lyrScope
            required property var modelData
            readonly property bool here: root.lyricsOpen
                && (root.lyricsScreen === "" ? modelData === Quickshell.screens[0] : root.lyricsScreen === modelData.name)

            // ----- the tab, same look as the one for the right bar -----
            PanelWindow {
                id: lyrTabWin
                screen: lyrScope.modelData
                anchors {
                    top: true
                    bottom: true
                    left: true
                }
                implicitWidth: 34
                exclusionMode: ExclusionMode.Ignore
                color: "transparent"
                WlrLayershell.namespace: "quickshell-lyrics-tab"
                mask: Region { item: lyrTab }

                Rectangle {
                    id: lyrTab
                    anchors.verticalCenter: parent.verticalCenter
                    x: lyrScope.here ? -width - 4 : -10
                    width: lyrTabMouse.containsMouse ? 26 : 22
                    height: Math.max(160, parent.height * 0.34) + (lyrTabMouse.containsMouse ? 24 : 0)
                    radius: 11
                    color: root.popupBg
                    border.width: 1
                    border.color: root.glassEdge
                    Behavior on x { NumberAnimation { duration: root.animMs * 2; easing.type: Easing.OutCubic } }
                    Behavior on height { NumberAnimation { duration: root.animMs * 1.5; easing.type: Easing.OutCubic } }
                    Behavior on width { NumberAnimation { duration: root.animMs; easing.type: Easing.OutCubic } }

                    GlassShine { radius: parent.radius; dark: root.dark }

                    MouseArea {
                        id: lyrTabMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.openLyricsPanel(lyrScope.modelData.name)
                    }
                }
            }

            // ----- the panel -----
            PanelWindow {
                id: lyrWin
                screen: lyrScope.modelData
                visible: true
                anchors {
                    top: true
                    bottom: true
                    left: true
                }
                implicitWidth: 500
                exclusionMode: ExclusionMode.Ignore
                color: "transparent"
                WlrLayershell.layer: WlrLayer.Top
                WlrLayershell.namespace: "quickshell-lyrics"
                WlrLayershell.keyboardFocus: lyrScope.here && (root.leftTab === "clip" || root.leftTab === "notes")
                    ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None   // only takes typing on Clipboard / Notes, when you click in
                // only the card catches the mouse; everything else goes to the windows underneath
                readonly property bool showing: lyrScope.here || lyrCard.x > -lyrCard.width
                mask: showing ? lyrCardMask : lyrOffMask
                Region { id: lyrCardMask; item: lyrCard }
                Region { id: lyrOffMask }

                // Spotify only reports where it is in the song when asked
                Timer {
                    interval: 200
                    repeat: true
                    running: lyrScope.here && root.leftTab === "lyrics" && root.playing(root.spotify)
                    onTriggered: root.spotify.positionChanged()
                }

                Rectangle {
                    id: lyrCard
                    anchors.verticalCenter: parent.verticalCenter
                    width: 440
                    height: Math.min(760, parent.height * 0.76)
                    x: lyrScope.here ? 14 : -width - 30
                    opacity: lyrScope.here ? 1 : 0
                    radius: 30
                    color: root.popupBg
                    border.width: 1
                    border.color: root.glassEdge
                    clip: true
                    Behavior on x { NumberAnimation { duration: root.animMs * 3; easing.type: Easing.OutBack; easing.overshoot: 0.7 } }
                    Behavior on opacity { NumberAnimation { duration: root.animMs * 2 } }

                    // soft colour glow behind the words, in the theme's colours
                    Item {
                        id: lyrGlow
                        anchors.fill: parent
                        visible: false
                        layer.enabled: true
                        Rectangle {
                            width: 300; height: 300; radius: 150
                            x: -80; y: lyrCard.height * 0.18
                            color: root.lyricsColors[1]
                            opacity: 0.55
                            SequentialAnimation on x {
                                running: lyrScope.here && root.animMs > 0
                                loops: Animation.Infinite
                                NumberAnimation { to: 40; duration: 9000; easing.type: Easing.InOutSine }
                                NumberAnimation { to: -80; duration: 9000; easing.type: Easing.InOutSine }
                            }
                        }
                        Rectangle {
                            width: 280; height: 280; radius: 140
                            x: lyrCard.width - 200; y: lyrCard.height * 0.55
                            color: root.lyricsColors[2]
                            opacity: 0.5
                            SequentialAnimation on y {
                                running: lyrScope.here && root.animMs > 0
                                loops: Animation.Infinite
                                NumberAnimation { to: lyrCard.height * 0.35; duration: 11000; easing.type: Easing.InOutSine }
                                NumberAnimation { to: lyrCard.height * 0.55; duration: 11000; easing.type: Easing.InOutSine }
                            }
                        }
                    }
                    MultiEffect {
                        anchors.fill: parent
                        source: lyrGlow
                        blurEnabled: true
                        blurMax: 64
                        blur: 1
                        opacity: root.dark ? 0.45 : 0.35
                    }

                    GlassShine { radius: parent.radius; dark: root.dark }

                    MouseArea { anchors.fill: parent }   // clicks inside don't fall through

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 14

                        // ---- tabs + close ----
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6
                            Repeater {
                                model: root.leftTabs
                                delegate: SportChip {
                                    required property var modelData
                                    theme: root
                                    icon: modelData.icon
                                    // the name shows on the open tab so they all fit
                                    label: root.leftTab === modelData.id ? modelData.name : ""
                                    active: root.leftTab === modelData.id
                                    onClicked: pins.adapter.leftTab = modelData.id
                                }
                            }
                            Item { Layout.fillWidth: true }
                            // close: the only way to put it away
                            Rectangle {
                                Layout.preferredWidth: 34
                                Layout.preferredHeight: 34
                                radius: 17
                                color: lyrClose.containsMouse ? root.overlay : root.surface
                                border.width: 1
                                border.color: root.glassEdge
                                scale: lyrClose.pressed ? 0.88 : 1
                                Behavior on color { ColorAnimation { duration: root.animMs } }
                                Behavior on scale { NumberAnimation { duration: root.animMs; easing.type: Easing.OutBack } }
                                Text {
                                    anchors.centerIn: parent
                                    text: "\uf00d"
                                    color: root.fg
                                    font.family: root.iconFont
                                    font.pixelSize: 14
                                }
                                MouseArea {
                                    id: lyrClose
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.closeLyricsPanel()
                                }
                            }
                        }

                        StackLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            currentIndex: Math.max(0, root.leftTabs.findIndex(x => x.id === root.leftTab))

                            // ===== Lyrics =====
                            ColumnLayout {
                                spacing: 14
                        // ---- song ----
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            Item {
                                Layout.preferredWidth: 56
                                Layout.preferredHeight: 56
                                Rectangle { anchors.fill: parent; radius: 14; color: root.overlay }
                                Text {
                                    anchors.centerIn: parent
                                    text: ""
                                    color: root.muted
                                    font.family: root.iconFont
                                    font.pixelSize: 20
                                    visible: lyrArt.status !== Image.Ready
                                }
                                Image {
                                    id: lyrArt
                                    anchors.fill: parent
                                    source: root.spotify ? (root.spotify.trackArtUrl || "") : ""
                                    sourceSize.width: 112
                                    sourceSize.height: 112
                                    fillMode: Image.PreserveAspectCrop
                                    visible: false
                                    asynchronous: true
                                }
                                Item {
                                    id: lyrArtMask
                                    anchors.fill: parent
                                    layer.enabled: true
                                    visible: false
                                    Rectangle { anchors.fill: parent; radius: 14; color: "black" }
                                }
                                MultiEffect {
                                    anchors.fill: parent
                                    source: lyrArt
                                    maskEnabled: true
                                    maskSource: lyrArtMask
                                    visible: lyrArt.status === Image.Ready
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                Text {
                                    Layout.fillWidth: true
                                    text: root.spotify ? (root.spotify.trackTitle || "") : "Nothing playing"
                                    color: root.fg
                                    font.pixelSize: 16
                                    font.bold: true
                                    elide: Text.ElideRight
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: root.spotify ? (root.spotify.trackArtist || "") : "Open Spotify and play a song"
                                    color: root.lyricsColors[1]
                                    font.pixelSize: 12
                                    elide: Text.ElideRight
                                }
                            }


                        }

                        // ---- the words ----
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            ListView {
                                id: bigLyrics
                                anchors.fill: parent
                                clip: true
                                spacing: 14
                                model: lyrScope.here ? root.lyricsLines : []
                                currentIndex: root.lyricsIndex
                                // the line being sung sits a bit above the middle
                                highlightRangeMode: root.lyricsSynced && root.lyricsIndex >= 0 ? ListView.ApplyRange : ListView.NoHighlightRange
                                preferredHighlightBegin: height * 0.34
                                preferredHighlightEnd: height * 0.46
                                highlightMoveDuration: 500
                                boundsBehavior: Flickable.StopAtBounds
                                // fade the top and bottom edges
                                layer.enabled: true
                                layer.effect: MultiEffect {
                                    maskEnabled: true
                                    maskSource: lyrFade
                                }

                                delegate: Item {
                                    id: bl
                                    required property var modelData
                                    required property int index
                                    readonly property bool now: root.lyricsSynced && bl.index === root.lyricsIndex
                                    readonly property bool past: root.lyricsSynced && bl.index < root.lyricsIndex
                                    readonly property string words: bl.modelData.text === "" ? "♪" : bl.modelData.text
                                    width: bigLyrics.width
                                    height: blText.implicitHeight
                                    opacity: !root.lyricsSynced ? 0.95 : (bl.now ? 1 : (bl.past ? 0.32 : 0.62))
                                    scale: bl.now ? 1 : 0.94
                                    transformOrigin: Item.Left
                                    Behavior on opacity { NumberAnimation { duration: 300 } }
                                    Behavior on scale { NumberAnimation { duration: 350; easing.type: Easing.OutBack } }

                                    // every line: plain, in the theme's text colour
                                    Text {
                                        id: blText
                                        width: parent.width
                                        text: bl.words
                                        wrapMode: Text.Wrap
                                        color: root.lyricsSynced ? root.fg : root.lyricsColors[bl.index % 3]
                                        font.pixelSize: 24
                                        font.bold: true
                                        visible: !bl.now
                                    }
                                    // the line being sung: each word coloured along the theme's colours
                                    Text {
                                        width: parent.width
                                        visible: bl.now
                                        text: bl.now ? root.gradientWords(bl.words) : ""
                                        textFormat: Text.StyledText
                                        wrapMode: Text.Wrap
                                        font.pixelSize: 24
                                        font.bold: true
                                        style: Text.Raised
                                        styleColor: Qt.rgba(0, 0, 0, root.dark ? 0.35 : 0.08)
                                    }

                                    // click a line to jump the song there
                                    MouseArea {
                                        anchors.fill: parent
                                        enabled: root.lyricsSynced && bl.modelData.t >= 0
                                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                        onClicked: {
                                            const p = root.spotify;
                                            if (p && p.canSeek) p.position = bl.modelData.t;
                                        }
                                    }
                                }
                            }

                            // top and bottom fade for the list
                            Item {
                                id: lyrFade
                                anchors.fill: bigLyrics
                                visible: false
                                layer.enabled: true
                                Rectangle {
                                    anchors.fill: parent
                                    gradient: Gradient {
                                        GradientStop { position: 0.0; color: "transparent" }
                                        GradientStop { position: 0.10; color: "black" }
                                        GradientStop { position: 0.88; color: "black" }
                                        GradientStop { position: 1.0; color: "transparent" }
                                    }
                                }
                            }

                            // loading / nothing found
                            Column {
                                anchors.centerIn: parent
                                visible: root.lyricsStatus !== "ok" || !root.spotify
                                spacing: 10
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: root.lyricsStatus === "loading" ? "" : ""
                                    color: root.lyricsColors[1]
                                    font.family: root.iconFont
                                    font.pixelSize: 36
                                    RotationAnimation on rotation {
                                        running: root.lyricsStatus === "loading"
                                        loops: Animation.Infinite
                                        from: 0
                                        to: 360
                                        duration: 1200
                                    }
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    horizontalAlignment: Text.AlignHCenter
                                    text: !root.spotify ? "Play something on Spotify"
                                        : root.lyricsStatus === "loading" ? "Finding lyrics…"
                                        : root.lyricsStatus === "error" ? "Couldn't reach the lyrics service.\nCheck your internet."
                                        : "No lyrics found for this song"
                                    color: root.muted
                                    font.pixelSize: 14
                                }
                            }
                        }

                        // ---- bottom: play controls ----
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10
                            Text {
                                Layout.fillWidth: true
                                text: !root.spotify ? "" : (root.lyricsSynced ? "Synced · click a line to jump to it" : (root.lyricsStatus === "ok" ? "These lyrics aren't timed" : ""))
                                color: root.muted
                                font.pixelSize: 11
                                elide: Text.ElideRight
                            }
                            Repeater {
                                model: [
                                    { icon: "", act: "prev" },
                                    { icon: "", act: "toggle" },
                                    { icon: "", act: "next" }
                                ]
                                delegate: Rectangle {
                                    id: lyrBtn
                                    required property var modelData
                                    readonly property bool big: modelData.act === "toggle"
                                    Layout.preferredWidth: big ? 42 : 34
                                    Layout.preferredHeight: big ? 42 : 34
                                    radius: width / 2
                                    color: big ? root.accent : (lyrBtnMouse.containsMouse ? root.overlay : root.surface)
                                    border.width: big ? 0 : 1
                                    border.color: root.glassEdge
                                    opacity: root.spotify ? 1 : 0.4
                                    scale: lyrBtnMouse.pressed ? 0.88 : 1
                                    Behavior on scale { NumberAnimation { duration: root.animMs; easing.type: Easing.OutBack } }
                                    Text {
                                        anchors.centerIn: parent
                                        text: lyrBtn.big ? (root.playing(root.spotify) ? "" : "") : lyrBtn.modelData.icon
                                        color: lyrBtn.big ? root.bg : root.fg
                                        font.family: root.iconFont
                                        font.pixelSize: lyrBtn.big ? 15 : 12
                                    }
                                    MouseArea {
                                        id: lyrBtnMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            const p = root.spotify;
                                            if (!p) return;
                                            if (lyrBtn.modelData.act === "prev") p.previous();
                                            else if (lyrBtn.modelData.act === "next") p.next();
                                            else p.togglePlaying();
                                        }
                                    }
                                }
                            }
                        }
                                                }

                            // ===== Display: screen colours =====
                            Flickable {
                                clip: true
                                contentWidth: width
                                contentHeight: dispCol.implicitHeight
                                boundsBehavior: Flickable.StopAtBounds

                                ColumnLayout {
                                    id: dispCol
                                    width: parent.width
                                    spacing: 12

                                    Text { text: "Screen colours"; color: root.fg; font.pixelSize: 17; font.bold: true }
                                    Text {
                                        Layout.fillWidth: true
                                        text: root.gameMode ? "Paused while game mode is on, so games run at full speed."
                                            : "Changes every monitor. Pick a look, or fine-tune it below."
                                        color: root.gameMode ? root.danger : root.muted
                                        font.pixelSize: 12
                                        wrapMode: Text.Wrap
                                    }

                                    Flow {
                                        Layout.fillWidth: true
                                        spacing: 6
                                        Repeater {
                                            model: root.displayPresets
                                            delegate: SportChip {
                                                required property var modelData
                                                theme: root
                                                label: modelData.name
                                                active: root.dispSat === modelData.sat && root.dispCon === modelData.con
                                                    && root.dispTemp === modelData.temp && root.dispBri === modelData.bri
                                                onClicked: root.setDisplay(modelData.sat, modelData.con, modelData.temp, modelData.bri)
                                            }
                                        }
                                    }

                                    Repeater {
                                        model: [
                                            { key: "sat",  name: "Saturation", icon: "", lo: 0,    hi: 200,  unit: "%" },
                                            { key: "con",  name: "Contrast",   icon: "", lo: 50,   hi: 150,  unit: "%" },
                                            { key: "temp", name: "Warmth",     icon: "", lo: 6500, hi: 2500, unit: " K" },
                                            { key: "bri",  name: "Brightness", icon: "", lo: 60,   hi: 120,  unit: "%" }
                                        ]
                                        delegate: HubCard {
                                            id: dRow
                                            required property var modelData
                                            readonly property int val: modelData.key === "sat" ? root.dispSat
                                                : modelData.key === "con" ? root.dispCon
                                                : modelData.key === "temp" ? root.dispTemp : root.dispBri
                                            theme: root
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 70
                                            radius: 18
                                            ColumnLayout {
                                                anchors.fill: parent
                                                anchors.margins: 14
                                                spacing: 8
                                                RowLayout {
                                                    Layout.fillWidth: true
                                                    spacing: 8
                                                    Text { text: dRow.modelData.icon; color: root.accent; font.family: root.iconFont; font.pixelSize: 13 }
                                                    Text { Layout.fillWidth: true; text: dRow.modelData.name; color: root.fg; font.pixelSize: 13; font.bold: true }
                                                    Text {
                                                        text: dRow.modelData.key === "temp" && dRow.val >= 6500 ? "Off" : dRow.val + dRow.modelData.unit
                                                        color: root.muted
                                                        font.pixelSize: 12
                                                    }
                                                }
                                                ValueBar {
                                                    Layout.fillWidth: true
                                                    theme: root
                                                    value: (dRow.val - dRow.modelData.lo) / (dRow.modelData.hi - dRow.modelData.lo)
                                                    onMoved: v => {
                                                        let n = dRow.modelData.lo + v * (dRow.modelData.hi - dRow.modelData.lo);
                                                        n = dRow.modelData.key === "temp" ? Math.round(n / 100) * 100 : Math.round(n / 5) * 5;
                                                        root.setDisplayValue(dRow.modelData.key, n);
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    BarButton {
                                        theme: root
                                        icon: ""
                                        label: "Back to normal"
                                        onClicked: mouse => root.setDisplay(100, 100, 6500, 100)
                                    }
                                }
                            }

                            // ===== Clipboard history =====
                            ColumnLayout {
                                spacing: 10

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8
                                    Rectangle {
                                        Layout.fillWidth: true
                                        implicitHeight: 34
                                        radius: 17
                                        color: root.surface
                                        border.width: 1
                                        border.color: clipSearch.activeFocus ? root.accent : root.glassEdge
                                        Text {
                                            id: clipSearchIcon
                                            anchors.left: parent.left
                                            anchors.leftMargin: 12
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: ""
                                            font.family: root.iconFont
                                            font.pixelSize: 12
                                            color: root.muted
                                        }
                                        TextInput {
                                            id: clipSearch
                                            anchors.left: clipSearchIcon.right
                                            anchors.leftMargin: 9
                                            anchors.right: parent.right
                                            anchors.rightMargin: 12
                                            anchors.verticalCenter: parent.verticalCenter
                                            color: root.fg
                                            font.pixelSize: 13
                                            clip: true
                                            Keys.onEscapePressed: text = ""
                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                visible: clipSearch.text === ""
                                                text: "Search what you copied"
                                                color: root.muted
                                                font.pixelSize: 13
                                            }
                                        }
                                    }
                                    BarButton {
                                        theme: root
                                        icon: ""
                                        label: "Clear"
                                        visible: root.clipHave && root.clipItems.length > 0
                                        onClicked: mouse => root.clipWipe()
                                    }
                                }

                                Item {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true

                                    ListView {
                                        id: clipView
                                        anchors.fill: parent
                                        clip: true
                                        spacing: 6
                                        boundsBehavior: Flickable.StopAtBounds
                                        model: {
                                            const q = clipSearch.text.toLowerCase();
                                            return q === "" ? root.clipItems : root.clipItems.filter(x => x.text.toLowerCase().indexOf(q) >= 0);
                                        }
                                        delegate: Rectangle {
                                            id: ci
                                            required property var modelData
                                            width: clipView.width
                                            height: ciText.implicitHeight + 22
                                            radius: 14
                                            color: ciMouse.containsMouse ? root.overlay : root.surface
                                            border.width: 1
                                            border.color: root.clipJustCopied === ci.modelData.line ? root.accent : root.glassEdge
                                            Behavior on color { ColorAnimation { duration: root.animMs } }

                                            Text {
                                                id: ciText
                                                anchors.left: parent.left
                                                anchors.right: ciDel.left
                                                anchors.leftMargin: 12
                                                anchors.rightMargin: 8
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: ci.modelData.image ? "  Picture" : ci.modelData.text
                                                color: root.fg
                                                font.pixelSize: 12
                                                font.family: ci.modelData.image ? root.iconFont : Qt.application.font.family
                                                wrapMode: Text.Wrap
                                                maximumLineCount: 3
                                                elide: Text.ElideRight
                                            }
                                            MouseArea {
                                                id: ciMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: root.clipCopy(ci.modelData.line)
                                            }
                                            // delete just this one
                                            Text {
                                                id: ciDel
                                                anchors.right: parent.right
                                                anchors.rightMargin: 12
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: root.clipJustCopied === ci.modelData.line ? "" : ""
                                                color: root.clipJustCopied === ci.modelData.line ? root.accent : root.muted
                                                opacity: ciMouse.containsMouse || ciDelMouse.containsMouse || root.clipJustCopied === ci.modelData.line ? 1 : 0
                                                font.family: root.iconFont
                                                font.pixelSize: 12
                                                MouseArea {
                                                    id: ciDelMouse
                                                    anchors.fill: parent
                                                    anchors.margins: -8
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: root.clipDelete(ci.modelData.line)
                                                }
                                            }
                                        }
                                    }

                                    Column {
                                        anchors.centerIn: parent
                                        width: parent.width - 20
                                        visible: !root.clipHave || clipView.count === 0
                                        spacing: 10
                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: ""
                                            color: root.lyricsColors[1]
                                            font.family: root.iconFont
                                            font.pixelSize: 34
                                        }
                                        Text {
                                            width: parent.width
                                            horizontalAlignment: Text.AlignHCenter
                                            wrapMode: Text.Wrap
                                            text: !root.clipHave ? "Clipboard history needs cliphist. Install it with:"
                                                : (root.clipItems.length === 0 ? "Copy something and it shows up here" : "Nothing matches")
                                            color: root.muted
                                            font.pixelSize: 13
                                        }
                                        BarButton {
                                            visible: !root.clipHave
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            theme: root
                                            icon: ""
                                            label: "sudo pacman -S cliphist"
                                            onClicked: mouse => Quickshell.execDetached(["wl-copy", "sudo pacman -S cliphist"])
                                        }
                                    }
                                }
                                Text {
                                    text: root.clipHave ? "Click to copy it again" : "(click the command to copy it)"
                                    color: root.muted
                                    font.pixelSize: 11
                                }
                            }

                            // ===== Notes =====
                            ColumnLayout {
                                spacing: 10
                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { Layout.fillWidth: true; text: "Notes"; color: root.fg; font.pixelSize: 17; font.bold: true }
                                    Text { text: "Saves by itself"; color: root.muted; font.pixelSize: 11 }
                                }
                                HubCard {
                                    theme: root
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    radius: 18
                                    Flickable {
                                        id: noteFlick
                                        anchors.fill: parent
                                        anchors.margins: 14
                                        clip: true
                                        contentWidth: width
                                        contentHeight: noteEdit.implicitHeight
                                        boundsBehavior: Flickable.StopAtBounds
                                        function ensureVisible(r) {
                                            if (contentY >= r.y) contentY = r.y;
                                            else if (contentY + height <= r.y + r.height) contentY = r.y + r.height - height;
                                        }
                                        TextEdit {
                                            id: noteEdit
                                            width: noteFlick.width
                                            color: root.fg
                                            selectionColor: root.accent
                                            selectedTextColor: root.bg
                                            font.pixelSize: 14
                                            wrapMode: TextEdit.Wrap
                                            Component.onCompleted: text = root.notesText
                                            onCursorRectangleChanged: noteFlick.ensureVisible(cursorRectangle)
                                            onTextChanged: if (activeFocus && text !== root.notesText) {
                                                root.notesText = text;
                                                notesSave.restart();
                                            }
                                            Connections {
                                                target: root
                                                function onNotesTextChanged() {
                                                    if (!noteEdit.activeFocus && noteEdit.text !== root.notesText) noteEdit.text = root.notesText;
                                                }
                                            }
                                            Text {
                                                visible: noteEdit.text === ""
                                                text: "Click here and type. Ideas, to-dos, codes for games…"
                                                color: root.muted
                                                font.pixelSize: 14
                                                wrapMode: Text.Wrap
                                                width: parent.width
                                            }
                                        }
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        z: -1
                                        onClicked: noteEdit.forceActiveFocus()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ---------- Right side bar: brightness, Spotify, Discord ----------
    // A glass pill on the right edge (auto-hides like the other bars): brightness, Spotify, Vesktop. Click it and it grows
    // into a panel. Brightness uses scripts/brightness.sh (ddcutil for desktop monitors).
    property bool sideOpen: false
    property bool sideBarOpen: false      // right pill pulled out with its tab

    // Optional keybind:  hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("qs ipc call sidebar toggle"))
    IpcHandler {
        target: "sidebar"
        function toggle(): void {
            root.sideOpen = !root.sideOpen;
        }
    }

    // ----- Brightness -----
    readonly property string brightScript: Quickshell.env("HOME") + "/.config/quickshell/scripts/brightness.sh"
    property var brightDisplays: []       // [{ id, conn, name, value }]   value is 0-100
    property bool brightNoDdc: false
    property bool brightLoading: false
    property var brightPending: ({})

    Process {
        id: brightProc
        command: ["bash", root.brightScript, "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                let noDdc = false;
                const lines = text.split("\n");
                for (let i = 0; i < lines.length; i++) {
                    const l = lines[i].trim();
                    if (l === "NODDC") { noDdc = true; continue; }
                    const p = l.split("|");
                    if (p.length < 5) continue;
                    const max = Math.max(1, parseInt(p[4]) || 100);
                    out.push({ id: p[0], conn: p[1], name: p[2], value: Math.round((parseInt(p[3]) || 0) * 100 / max) });
                }
                root.brightDisplays = out;
                root.brightNoDdc = noDdc;
                root.brightLoading = false;
            }
        }
    }

    function refreshBrightness() {
        if (brightProc.running) return;
        brightLoading = true;
        brightProc.running = true;
    }

    onSideOpenChanged: {
        if (sideOpen) refreshBrightness();
        else sideView = "main";
    }

    // ----- Lyrics (right panel, from LRCLIB: https://lrclib.net) -----
    property string sideView: "main"      // "main" or "lyrics"
    property var lyricsLines: []          // [{ t: seconds (or -1), text }]
    property bool lyricsSynced: false
    property string lyricsStatus: ""      // "loading", "ok", "none", "error"
    property string lyricsKey: ""

    readonly property string spotifyKey: spotify ? (spotify.trackArtist || "") + "|" + (spotify.trackTitle || "") : ""
    onSpotifyKeyChanged: if (sideView === "lyrics" || lyricsOpen) fetchLyrics()
    onSideViewChanged: {
        if (sideView === "lyrics") fetchLyrics();
        if (sideView === "signalChat") sigMarkRead(sigCurrent);
    }

    function showLyrics() {
        sideView = "lyrics";
        sideOpen = true;
    }

    // "[01:23.45] some words" -> one entry per time stamp
    function parseLrc(text) {
        const out = [];
        const lines = text.split("\n");
        for (let i = 0; i < lines.length; i++) {
            const stamps = [];
            let rest = lines[i];
            let m;
            while ((m = /^\s*\[(\d+):(\d+(?:\.\d+)?)\]/.exec(rest)) !== null) {
                stamps.push(parseInt(m[1]) * 60 + parseFloat(m[2]));
                rest = rest.slice(m[0].length);
            }
            for (let j = 0; j < stamps.length; j++) out.push({ t: stamps[j], text: rest.trim() });
        }
        out.sort((a, b) => a.t - b.t);
        return out;
    }

    function useLyrics(item) {
        if (item && item.syncedLyrics) {
            lyricsLines = parseLrc(item.syncedLyrics);
            lyricsSynced = true;
            lyricsStatus = lyricsLines.length > 0 ? "ok" : "none";
        } else if (item && item.plainLyrics) {
            lyricsLines = item.plainLyrics.split("\n").map(l => ({ t: -1, text: l.trim() }));
            lyricsSynced = false;
            lyricsStatus = "ok";
        } else if (item && item.instrumental) {
            lyricsLines = [{ t: -1, text: "♪  Instrumental  ♪" }];
            lyricsSynced = false;
            lyricsStatus = "ok";
        } else {
            lyricsLines = [];
            lyricsStatus = "none";
        }
    }

    function lrclibGet(url, done) {
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;
            let data = null;
            try {
                data = xhr.status === 200 ? JSON.parse(xhr.responseText) : null;
            } catch (e) {
                data = null;
            }
            done(xhr.status, data);
        };
        xhr.open("GET", url);
        xhr.setRequestHeader("Lrclib-Client", "JoeOS Quickshell bar");
        xhr.send();
    }

    function fetchLyrics() {
        const p = spotify;
        if (!p || !p.trackTitle) {
            lyricsLines = [];
            lyricsStatus = "none";
            lyricsKey = "";
            return;
        }
        const key = spotifyKey;
        if (key === lyricsKey && (lyricsStatus === "ok" || lyricsStatus === "loading")) return;
        lyricsKey = key;
        lyricsStatus = "loading";
        lyricsLines = [];
        const artist = (p.trackArtist || "").split(",")[0].trim();
        const enc = encodeURIComponent;
        let url = "https://lrclib.net/api/get?track_name=" + enc(p.trackTitle) + "&artist_name=" + enc(artist);
        if (p.trackAlbum) url += "&album_name=" + enc(p.trackAlbum);
        if (p.length > 0) url += "&duration=" + Math.round(p.length);
        lrclibGet(url, (status, data) => {
            if (root.lyricsKey !== key) return;          // song changed while loading
            if (data) {
                root.useLyrics(data);
                return;
            }
            // not an exact match: search, and prefer a result with timed lyrics
            const surl = "https://lrclib.net/api/search?track_name=" + enc(p.trackTitle) + "&artist_name=" + enc(artist);
            root.lrclibGet(surl, (st2, list) => {
                if (root.lyricsKey !== key) return;
                if (st2 === 0) { root.lyricsStatus = "error"; return; }
                if (!list || list.length === 0) { root.useLyrics(null); return; }
                let pick = list[0];
                for (let i = 0; i < list.length; i++)
                    if (list[i].syncedLyrics) { pick = list[i]; break; }
                root.useLyrics(pick);
            });
        });
    }

    // Which line is being sung right now
    readonly property int lyricsIndex: {
        if (!lyricsSynced || !spotify) return -1;
        const pos = spotify.position + 0.2;
        let idx = -1;
        for (let i = 0; i < lyricsLines.length; i++) {
            if (lyricsLines[i].t <= pos) idx = i;
            else break;
        }
        return idx;
    }

    // read it once a few seconds after start, so the pill can show a number
    Timer {
        interval: 5000
        running: true
        onTriggered: root.refreshBrightness()
    }

    // The slider moves straight away; the monitor is told a moment later (DDC is slow)
    function setBrightness(id, pct) {
        pct = Math.max(0, Math.min(100, Math.round(pct)));
        const list = brightDisplays.map(d => d.id === id ? { id: d.id, conn: d.conn, name: d.name, value: pct } : d);
        brightDisplays = list;
        const pend = {};
        for (const k in brightPending) pend[k] = brightPending[k];
        pend[id] = pct;
        brightPending = pend;
        brightSetTimer.restart();
    }

    function setAllBrightness(pct) {
        for (let i = 0; i < brightDisplays.length; i++) setBrightness(brightDisplays[i].id, pct);
    }

    Timer {
        id: brightSetTimer
        interval: 250
        onTriggered: {
            const pend = root.brightPending;
            root.brightPending = {};
            for (const id in pend)
                Quickshell.execDetached(["bash", root.brightScript, "set", id, String(pend[id])]);
        }
    }

    readonly property int brightAvg: {
        if (brightDisplays.length === 0) return -1;
        let t = 0;
        for (let i = 0; i < brightDisplays.length; i++) t += brightDisplays[i].value;
        return Math.round(t / brightDisplays.length);
    }

    // ----- Spotify -----
    readonly property var spotify: {
        const list = Mpris.players.values;
        for (let i = 0; i < list.length; i++) {
            const p = list[i];
            const name = ((p.identity || "") + " " + (p.desktopEntry || "")).toLowerCase();
            if (name.indexOf("spotify") >= 0) return p;
        }
        return null;
    }
    // Spotify can be a Flatpak (com.spotify.Client), the AUR package or spotify-launcher
    readonly property var spotifyEntry: {
        const ids = ["com.spotify.Client", "spotify", "spotify-launcher"];
        for (let i = 0; i < ids.length; i++) {
            const e = DesktopEntries.heuristicLookup(ids[i]);
            if (e && /spotify/i.test(e.id + " " + e.name)) return e;
        }
        return null;
    }

    function openSpotify() {
        sideOpen = false;
        if (spotifyEntry) launchApp(spotifyEntry);
        else Quickshell.execDetached(["sh", "-c", "flatpak run com.spotify.Client || spotify || spotify-launcher"]);
    }

    // Spotify's own audio stream in PipeWire (for its volume buttons)
    readonly property var spotifyStream: {
        const list = audioStreams;
        for (let i = 0; i < list.length; i++) {
            const pr = list[i].properties || {};
            const name = (pr["application.name"] || "") + " " + (pr["application.process.binary"] || "") + " " + (list[i].name || "");
            if (/spotify/i.test(name)) return list[i];
        }
        return null;
    }

    // Music volume, 0 to 1 (-1 = not available yet, e.g. nothing playing)
    readonly property real spotifyVolume: spotifyStream && spotifyStream.audio ? spotifyStream.audio.volume
        : (spotify && spotify.volumeSupported ? spotify.volume : -1)

    function setSpotifyVolume(v) {
        v = Math.max(0, Math.min(1, v));
        if (spotifyStream && spotifyStream.audio) spotifyStream.audio.volume = v;
        else if (spotify && spotify.volumeSupported) spotify.volume = v;
    }

    function spotifyVolumeStep(d) {
        if (spotifyVolume >= 0) setSpotifyVolume(spotifyVolume + d);
    }

    // Repeat: "playlist" = repeat all, "track" = repeat one. Clicking the lit one turns repeat off.
    function spotifyRepeat(kind) {
        const p = spotify;
        if (!p || !p.loopSupported) return;
        const want = kind === "track" ? MprisLoopState.Track : MprisLoopState.Playlist;
        p.loopState = p.loopState === want ? MprisLoopState.None : want;
    }

    function spotifyShuffle() {
        if (spotify && spotify.shuffleSupported) spotify.shuffle = !spotify.shuffle;
    }

    // ----- Vesktop (Discord). Falls back to the official Discord app if Vesktop isn't installed -----
    readonly property var discordEntry: {
        const ids = ["vesktop", "dev.vencord.Vesktop", "discord", "com.discordapp.Discord", "webcord"];
        for (let i = 0; i < ids.length; i++) {
            const e = DesktopEntries.heuristicLookup(ids[i]);
            if (e) return e;
        }
        return null;
    }

    function isDiscord(s) {
        return /discord|vesktop|webcord|vencord/i.test(s || "");
    }

    readonly property bool discordRunning: {
        const list = ToplevelManager.toplevels.values;
        for (let i = 0; i < list.length; i++)
            if (isDiscord(list[i].appId)) return true;
        return false;
    }

    readonly property var discordNotifs: {
        const list = notifServer.trackedNotifications.values, out = [];
        for (let i = list.length - 1; i >= 0; i--)
            if (isDiscord(list[i].appName) || isDiscord(list[i].desktopEntry)) out.push(list[i]);
        return out;
    }

    // ----- Signal (signal-desktop package or the Flatpak) -----
    readonly property var signalEntry: {
        const ids = ["signal-desktop", "org.signal.Signal", "signal"];
        for (let i = 0; i < ids.length; i++) {
            const e = DesktopEntries.heuristicLookup(ids[i]);
            if (e && /signal/i.test(e.id + " " + e.name)) return e;
        }
        return null;
    }

    function isSignal(s) {
        return /signal/i.test(s || "");
    }

    readonly property bool signalRunning: {
        const list = ToplevelManager.toplevels.values;
        for (let i = 0; i < list.length; i++)
            if (isSignal(list[i].appId)) return true;
        return false;
    }

    readonly property var signalNotifs: {
        const list = notifServer.trackedNotifications.values, out = [];
        for (let i = list.length - 1; i >= 0; i--)
            if (isSignal(list[i].appName) || isSignal(list[i].desktopEntry)) out.push(list[i]);
        return out;
    }

    // ---------- Signal messaging (through signal-cli, linked like Signal Desktop) ----------
    // Set up once with scripts/signal-setup.sh. The bar then runs signal-cli in the background,
    // talks to it over a local socket, and keeps the last messages of each chat in
    // ~/.local/share/joeos/signal-chats.json (only on this PC).
    property string sigAccount: ""
    property bool sigCliMissing: false
    property bool sigReady: false              // connected to signal-cli
    property var sigChats: ({})                // key -> { key, name, group, id, msgs: [{ me, from, text, ts }], unread, last }
    property var sigNames: ({})                // phone number -> contact name
    property var sigGroupNames: ({})           // group id -> group name
    property var sigContacts: []               // [{ key, name, id }]
    property string sigCurrent: ""             // chat open in the panel
    property int sigReqId: 1
    property var sigPending: ({})
    property bool sigLoaded: false
    readonly property string sigSocketPath: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/joeos-signal.socket"

    // which phone number is linked (written by signal-setup.sh)
    FileView {
        path: Quickshell.env("HOME") + "/.config/joeos/signal-account"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.sigAccount = text().trim()
    }

    // saved chat history
    FileView {
        id: sigStore
        path: Quickshell.env("HOME") + "/.local/share/joeos/signal-chats.json"
        printErrors: false
        onAdapterUpdated: writeAdapter()
        onLoaded: root.sigLoadStore()
        onLoadFailed: error => root.sigLoadStore()
        adapter: JsonAdapter {
            property string chats: "{}"
        }
    }

    function sigLoadStore() {
        if (sigLoaded) return;
        sigLoaded = true;
        try {
            sigChats = JSON.parse(sigStore.adapter.chats || "{}");
        } catch (e) {
            sigChats = {};
        }
    }

    Timer {
        id: sigSaveTimer
        interval: 1500
        onTriggered: {
            Quickshell.execDetached(["mkdir", "-p", Quickshell.env("HOME") + "/.local/share/joeos"]);
            sigStore.adapter.chats = JSON.stringify(root.sigChats);
        }
    }

    Process {
        command: ["sh", "-c", "command -v signal-cli >/dev/null 2>&1 && echo yes || echo no"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.sigCliMissing = text.trim() !== "yes"
        }
    }

    // signal-cli running in the background while an account is linked
    Process {
        id: sigDaemon
        running: root.sigAccount !== "" && !root.sigCliMissing
        command: ["sh", "-c", 'rm -f "$1"; exec signal-cli -a "$2" daemon --socket="$1" --receive-mode=on-connection',
            "sh", root.sigSocketPath, root.sigAccount]
        onRunningChanged: if (!running && root.sigAccount !== "") sigRestart.restart()
    }

    Timer {
        id: sigRestart
        interval: 15000
        onTriggered: if (!sigDaemon.running && root.sigAccount !== "" && !root.sigCliMissing) sigDaemon.running = true
    }

    Socket {
        id: sigSock
        path: root.sigSocketPath
        parser: SplitParser {
            onRead: data => root.sigHandle(data)
        }
        onConnectedChanged: {
            root.sigReady = connected;
            if (connected) {
                root.sigCall("listContacts", {});
                root.sigCall("listGroups", {});
            }
        }
    }

    // keep trying to connect while signal-cli is starting up (it takes a few seconds)
    Timer {
        interval: 3000
        repeat: true
        running: sigDaemon.running && !sigSock.connected
        onTriggered: sigSock.connected = true
    }

    function sigCall(method, params) {
        if (!sigSock.connected) return;
        const id = sigReqId++;
        const pend = {};
        for (const k in sigPending) pend[k] = sigPending[k];
        pend[id] = method;
        sigPending = pend;
        sigSock.write(JSON.stringify({ jsonrpc: "2.0", method: method, params: params, id: id }) + "\n");
        sigSock.flush();
    }

    function sigContactName(c) {
        if (!c) return "";
        if (c.name) return c.name;
        if (c.nickName) return c.nickName;
        const p = c.profile || {};
        const prof = ((p.givenName || "") + " " + (p.familyName || "")).trim();
        if (prof) return prof;
        const given = ((c.givenName || "") + " " + (c.familyName || "")).trim();
        return given || c.number || c.username || "";
    }

    function sigHandle(line) {
        let msg;
        try {
            msg = JSON.parse(line);
        } catch (e) {
            return;
        }
        // answers to listContacts / listGroups
        if (msg.id !== undefined && msg.result !== undefined) {
            const what = sigPending[msg.id];
            if (what === "listContacts" && Array.isArray(msg.result)) {
                const names = {}, list = [];
                for (let i = 0; i < msg.result.length; i++) {
                    const c = msg.result[i];
                    const id = c.number || c.uuid;
                    if (!id) continue;
                    const name = sigContactName(c);
                    names[id] = name;
                    if (name && name !== id) list.push({ key: "u:" + id, name: name, id: id });
                }
                list.sort((a, b) => a.name.localeCompare(b.name));
                sigNames = names;
                sigContacts = list;
            } else if (what === "listGroups" && Array.isArray(msg.result)) {
                const g = {};
                for (let i = 0; i < msg.result.length; i++)
                    if (msg.result[i].id) g[msg.result[i].id] = msg.result[i].name || "Group";
                sigGroupNames = g;
            }
            return;
        }
        // new messages
        if (msg.method !== "receive" || !msg.params) return;
        const env = msg.params.envelope || (msg.params.result && msg.params.result.envelope);
        if (!env) return;
        const ts = env.timestamp || Date.now();
        const dm = env.dataMessage;
        if (dm && dm.message) {
            const gid = dm.groupInfo && dm.groupInfo.groupId;
            const who = env.sourceNumber || env.source || env.sourceUuid || "";
            const from = env.sourceName || sigNames[who] || who;
            if (gid) sigAdd("g:" + gid, sigGroupNames[gid] || dm.groupInfo.groupName || "Group", true, gid, { me: false, from: from, text: dm.message, ts: ts });
            else sigAdd("u:" + who, from, false, who, { me: false, from: from, text: dm.message, ts: ts });
            return;
        }
        // something you sent from your phone or Signal Desktop
        const sm = env.syncMessage && env.syncMessage.sentMessage;
        if (sm && sm.message) {
            const gid = sm.groupInfo && sm.groupInfo.groupId;
            const to = sm.destinationNumber || sm.destination || sm.destinationUuid || "";
            if (gid) sigAdd("g:" + gid, sigGroupNames[gid] || "Group", true, gid, { me: true, from: "You", text: sm.message, ts: sm.timestamp || ts });
            else if (to) sigAdd("u:" + to, sigNames[to] || to, false, to, { me: true, from: "You", text: sm.message, ts: sm.timestamp || ts });
        }
    }

    // add a message to a chat (making the chat if it's new) and save
    function sigAdd(key, name, group, id, m) {
        const all = {};
        for (const k in sigChats) all[k] = sigChats[k];
        const old = all[key];
        const msgs = old ? old.msgs.slice() : [];
        msgs.push(m);
        while (msgs.length > 80) msgs.shift();
        const viewing = sideOpen && sideView === "signalChat" && sigCurrent === key;
        all[key] = {
            key: key,
            name: (old && old.name && old.name !== old.id) ? old.name : name,
            group: group,
            id: id,
            msgs: msgs,
            unread: (old ? old.unread : 0) + (m.me || viewing ? 0 : 1),
            last: m.ts
        };
        sigChats = all;
        sigSaveTimer.restart();
    }

    function sigOpen(key, name, group, id) {
        if (!sigChats[key]) {
            const all = {};
            for (const k in sigChats) all[k] = sigChats[k];
            all[key] = { key: key, name: name, group: group, id: id, msgs: [], unread: 0, last: 0 };
            sigChats = all;
        }
        sigCurrent = key;
        sigMarkRead(key);
        sideView = "signalChat";
    }

    function sigMarkRead(key) {
        const c = sigChats[key];
        if (!c || c.unread === 0) return;
        const all = {};
        for (const k in sigChats) all[k] = sigChats[k];
        all[key] = Object.assign({}, c, { unread: 0 });
        sigChats = all;
        sigSaveTimer.restart();
    }

    function sigSend(key, text) {
        text = text.trim();
        const c = sigChats[key];
        if (!c || text === "" || !sigReady) return false;
        sigCall("send", c.group ? { groupId: c.id, message: text } : { recipient: [c.id], message: text });
        sigAdd(key, c.name, c.group, c.id, { me: true, from: "You", text: text, ts: Date.now() });
        return true;
    }

    readonly property var sigChatList: {
        const out = [];
        for (const k in sigChats) out.push(sigChats[k]);
        out.sort((a, b) => b.last - a.last);
        return out;
    }

    readonly property int sigUnreadTotal: {
        let n = 0;
        for (const k in sigChats) n += sigChats[k].unread || 0;
        return n;
    }

    function sigTime(ts) {
        if (!ts) return "";
        const d = new Date(ts), now = new Date();
        return d.toDateString() === now.toDateString() ? Qt.formatTime(d, root.use24h ? "hh:mm" : "h:mm AP") : Qt.formatDate(d, "MMM d");
    }

    function openSignal() {
        sideOpen = false;
        if (signalEntry) launchApp(signalEntry);
        else Quickshell.execDetached(["sh", "-c", "signal-desktop || flatpak run org.signal.Signal"]);
    }

    // ----- Icons for Spotify / Vesktop -----
    // Different installs (package, AUR, Flatpak) name the icon differently, so try them all and
    // keep the first one that really exists. Empty means none was found (a symbol is shown instead).
    function findIcon(names) {
        for (let i = 0; i < names.length; i++) {
            if (!names[i]) continue;
            const path = Quickshell.iconPath(names[i], true);
            if (path !== "") return path;
        }
        return "";
    }

    function runningAppId(test) {
        const list = ToplevelManager.toplevels.values;
        for (let i = 0; i < list.length; i++)
            if (test(list[i].appId)) return list[i].appId;
        return "";
    }

    readonly property string spotifyIcon: findIcon([
        spotifyEntry ? spotifyEntry.icon : "",
        spotify && spotify.desktopEntry ? spotify.desktopEntry : "",
        runningAppId(a => /spotify/i.test(a || "")),
        "spotify-client", "spotify", "com.spotify.Client", "spotify-launcher"
    ])

    readonly property string signalIcon: findIcon([
        signalEntry ? signalEntry.icon : "",
        runningAppId(a => isSignal(a)),
        "signal-desktop", "org.signal.Signal", "signal"
    ])

    readonly property string vesktopIcon: findIcon([
        discordEntry ? discordEntry.icon : "",
        runningAppId(a => isDiscord(a)),
        "vesktop", "dev.vencord.Vesktop", "discord", "com.discordapp.Discord", "webcord"
    ])

    function openDiscord() {
        sideOpen = false;
        if (discordEntry) launchApp(discordEntry);
        else Quickshell.execDetached(["sh", "-c", "vesktop || flatpak run dev.vencord.Vesktop || discord"]);
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: side
            required property var modelData
            screen: modelData

            anchors {
                top: true
                bottom: true
                right: true
            }
            implicitWidth: 96            // pill (70) + room for the tab beside it
            color: "transparent"
            WlrLayershell.namespace: "quickshell-side"

            readonly property bool focusedHere: !Hyprland.focusedMonitor || Hyprland.focusedMonitor.name === modelData.name
            readonly property bool openHere: root.sideOpen && focusedHere

            // ----- Pull tab -----
            // With auto-hide on, the pill stays tucked away until you click the little tab on the
            // right edge. Click it again to tuck it away. Windows make room while it's out.
            readonly property bool wantHide: root.autoHideOn
            readonly property bool keepOpen: !wantHide || openHere || root.sideBarOpen
            readonly property bool barShown: keepOpen

            exclusionMode: ExclusionMode.Normal
            exclusiveZone: barShown ? 70 : 0

            mask: barShown ? sideShownMask : sideTabMask
            Region { id: sideTabMask; item: sideTab }
            Region {
                id: sideShownMask
                item: sidePill
                Region { item: sideTab }
            }

            // Pulled out with the tab? Clicking anywhere else tucks it away again
            HyprlandFocusGrab {
                windows: [side, sideWin]
                active: side.wantHide && root.sideBarOpen && side.focusedHere
                onCleared: root.sideBarOpen = false
            }

            // the tab: sticks out from the right edge, rides left of the pill when it's out
            Rectangle {
                id: sideTab
                visible: side.wantHide && !side.openHere
                anchors.verticalCenter: parent.verticalCenter
                x: side.barShown ? sidePill.x - width - 4 : parent.width - width + 10
                width: sideTabMouse.containsMouse ? 26 : 22
                // a long strip: about a third of the screen, a little longer when you point at it
                height: Math.max(160, parent.height * 0.34) + (sideTabMouse.containsMouse ? 24 : 0)
                radius: 11
                color: root.popupBg
                border.width: 1
                border.color: root.glassEdge
                Behavior on x { NumberAnimation { duration: root.animMs * 2; easing.type: Easing.OutCubic } }
                Behavior on height { NumberAnimation { duration: root.animMs * 1.5; easing.type: Easing.OutCubic } }
                Behavior on width { NumberAnimation { duration: root.animMs; easing.type: Easing.OutCubic } }

                GlassShine { radius: parent.radius; dark: root.dark }

                MouseArea {
                    id: sideTabMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.sideBarOpen = !root.sideBarOpen
                }
            }

            // ===================== The pill =====================
            Rectangle {
                id: sidePill
                anchors.verticalCenter: parent.verticalCenter
                x: side.barShown ? parent.width - width - 8 : parent.width + 8
                width: 54
                height: sideCol.implicitHeight + 28
                radius: 27
                color: root.popupBg
                border.width: 1
                border.color: root.glassEdge
                opacity: side.openHere ? 0 : 1
                scale: sideMouse.pressed ? 0.96 : (sidePillHover.hovered ? 1.04 : 1)
                Behavior on x { NumberAnimation { duration: root.animMs * 2; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: root.animMs } }
                Behavior on scale { NumberAnimation { duration: root.animMs; easing.type: Easing.OutBack } }

                HoverHandler { id: sidePillHover }

                GlassShine { radius: parent.radius; dark: root.dark }

                MouseArea {
                    id: sideMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.sideOpen = true
                }

                Column {
                    id: sideCol
                    anchors.centerIn: parent
                    spacing: 14

                    // sticker spot
                    Buddy { theme: root; slot: 1; size: 30; anchors.horizontalCenter: parent.horizontalCenter }

                    // brightness: scroll to change every monitor
                    Item {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 40
                        height: brightCol2.implicitHeight

                        Column {
                            id: brightCol2
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 2

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: ""
                                color: root.accent
                                font.family: root.iconFont
                                font.pixelSize: 17
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: root.brightAvg >= 0 ? root.brightAvg : "--"
                                color: root.muted
                                font.pixelSize: 10
                                font.bold: true
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -6
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.sideOpen = true
                            onWheel: wheel => {
                                if (root.brightAvg < 0) return;
                                root.setAllBrightness(root.brightAvg + (wheel.angleDelta.y > 0 ? 5 : -5));
                            }
                        }
                    }

                    Rectangle { anchors.horizontalCenter: parent.horizontalCenter; width: 4; height: 4; radius: 2; color: root.muted }

                    // Spotify (dimmed when closed, pulses while playing). Click: lyrics
                    Item {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 26
                        height: 26
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -6
                            z: 5
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.showLyrics()
                        }
                        IconImage {
                            anchors.fill: parent
                            visible: root.spotifyIcon !== ""
                            source: root.spotifyIcon
                            opacity: root.spotify ? 1 : 0.45
                        }
                        Text {
                            anchors.centerIn: parent
                            visible: root.spotifyIcon === ""
                            text: "\uf1bc"
                            color: root.spotify ? "#1ed760" : root.muted
                            font.family: root.iconFont
                            font.pixelSize: 20
                        }
                        Rectangle {
                            visible: root.playing(root.spotify)
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.margins: -2
                            width: 9
                            height: 9
                            radius: 4.5
                            color: root.accent
                            border.width: 1
                            border.color: root.bg
                            SequentialAnimation on opacity {
                                running: root.playing(root.spotify)
                                loops: Animation.Infinite
                                NumberAnimation { to: 0.35; duration: 700 }
                                NumberAnimation { to: 1; duration: 700 }
                            }
                        }
                    }

                    // Music controls: play/pause, next, volume up/down (dim when Spotify is closed)
                    Column {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 6
                        opacity: root.spotify ? 1 : 0.35

                        Repeater {
                            model: [
                                { icon: root.playing(root.spotify) ? "\uf04c" : "\uf04b", act: () => { if (root.spotify && root.spotify.canTogglePlaying) root.spotify.togglePlaying(); } },
                                { icon: "\uf051", act: () => { if (root.spotify && root.spotify.canGoNext) root.spotify.next(); } },
                                // repeat: off -> all -> one -> off
                                {
                                    icon: "\uf01e",
                                    lit: !!(root.spotify && root.spotify.loopState !== MprisLoopState.None),
                                    one: !!(root.spotify && root.spotify.loopState === MprisLoopState.Track),
                                    act: () => {
                                        const p = root.spotify;
                                        if (!p || !p.loopSupported) return;
                                        p.loopState = p.loopState === MprisLoopState.None ? MprisLoopState.Playlist
                                            : (p.loopState === MprisLoopState.Playlist ? MprisLoopState.Track : MprisLoopState.None);
                                    }
                                },
                                { icon: "\uf067", act: () => root.spotifyVolumeStep(0.05) },
                                { icon: "\uf068", act: () => root.spotifyVolumeStep(-0.05) }
                            ]
                            delegate: Rectangle {
                                id: sBtn
                                required property var modelData
                                width: 42
                                height: 42
                                radius: 21
                                color: sBtn.modelData.lit ? root.accent : (sBtnMouse.containsMouse ? root.overlay : "transparent")
                                scale: sBtnMouse.pressed ? 0.88 : 1
                                Behavior on color { ColorAnimation { duration: root.animMs } }
                                Behavior on scale { NumberAnimation { duration: root.animMs; easing.type: Easing.OutBack } }
                                Text {
                                    anchors.centerIn: parent
                                    text: sBtn.modelData.icon
                                    color: sBtn.modelData.lit ? root.bg : root.fg
                                    font.family: root.iconFont
                                    font.pixelSize: 18
                                }
                                // "1" when repeating one song
                                Rectangle {
                                    visible: !!sBtn.modelData.one
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    width: 14
                                    height: 14
                                    radius: 7
                                    color: root.bg
                                    Text { anchors.centerIn: parent; text: "1"; color: root.accent; font.pixelSize: 9; font.bold: true }
                                }
                                MouseArea {
                                    id: sBtnMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: sBtn.modelData.act()
                                }
                            }
                        }

                        // music volume number
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            visible: root.spotifyVolume >= 0
                            text: Math.round(root.spotifyVolume * 100)
                            color: root.muted
                            font.pixelSize: 12
                            font.bold: true
                        }
                    }

                    Rectangle { anchors.horizontalCenter: parent.horizontalCenter; width: 4; height: 4; radius: 2; color: root.muted }

                    // Vesktop (badge = new messages)
                    Item {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 26
                        height: 26
                        IconImage {
                            anchors.fill: parent
                            visible: root.vesktopIcon !== ""
                            source: root.vesktopIcon
                            opacity: root.discordRunning ? 1 : 0.45
                        }
                        Text {
                            anchors.centerIn: parent
                            visible: root.vesktopIcon === ""
                            text: "\uf086"
                            color: root.discordRunning ? "#5865f2" : root.muted
                            font.family: root.iconFont
                            font.pixelSize: 19
                        }
                        Rectangle {
                            visible: root.discordNotifs.length > 0
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: -5
                            width: Math.max(15, dBadge.implicitWidth + 6)
                            height: 15
                            radius: 7.5
                            color: root.danger
                            Text {
                                id: dBadge
                                anchors.centerIn: parent
                                text: root.discordNotifs.length
                                color: "white"
                                font.pixelSize: 9
                                font.bold: true
                            }
                        }
                    }

                    Rectangle { anchors.horizontalCenter: parent.horizontalCenter; width: 4; height: 4; radius: 2; color: root.muted }

                    // Signal (badge = new messages). Click: chats
                    Item {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 26
                        height: 26
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -6
                            z: 5
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.sideView = root.sigAccount !== "" ? "signal" : "main";
                                root.sideOpen = true;
                            }
                        }
                        IconImage {
                            anchors.fill: parent
                            visible: root.signalIcon !== ""
                            source: root.signalIcon
                            opacity: root.signalRunning ? 1 : 0.45
                        }
                        Text {
                            anchors.centerIn: parent
                            visible: root.signalIcon === ""
                            text: "\uf075"
                            color: root.signalRunning ? "#3a76f0" : root.muted
                            font.family: root.iconFont
                            font.pixelSize: 19
                        }
                        Rectangle {
                            visible: root.sigUnreadTotal > 0 || root.signalNotifs.length > 0
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: -5
                            width: Math.max(15, sigBadge.implicitWidth + 6)
                            height: 15
                            radius: 7.5
                            color: root.danger
                            Text {
                                id: sigBadge
                                anchors.centerIn: parent
                                text: root.sigUnreadTotal > 0 ? root.sigUnreadTotal : root.signalNotifs.length
                                color: "white"
                                font.pixelSize: 9
                                font.bold: true
                            }
                        }
                    }
                }
            }

            // ===================== The expanded panel =====================
            // Created once and kept (invisible + click-through when closed), like the hub.
            PanelWindow {
                id: sideWin
                screen: side.screen
                visible: true
                anchors.right: true
                implicitWidth: 420
                implicitHeight: Math.max(600, side.height - 40)
                exclusionMode: ExclusionMode.Ignore
                color: "transparent"
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "quickshell-sidepanel"
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

                readonly property bool showing: side.openHere || sideCard.width > sidePill.width + 2
                mask: showing ? sideCardMask : sideOffMask
                Region { id: sideCardMask; item: sideCard }
                Region { id: sideOffMask }

                HyprlandFocusGrab {
                    windows: [sideWin]
                    active: side.openHere
                    onCleared: root.sideOpen = false
                }

                Item {
                    id: sideKeys
                    focus: true
                    Keys.onEscapePressed: root.sideOpen = false
                }
                Connections {
                    target: side
                    function onOpenHereChanged() {
                        if (side.openHere) sideKeys.forceActiveFocus();
                    }
                }

                // smoother updates while the lyrics are on screen
                Timer {
                    interval: 250
                    repeat: true
                    running: side.openHere && root.playing(root.spotify) && root.sideView === "lyrics"
                    onTriggered: root.spotify.positionChanged()
                }

                // Spotify's position only updates when asked
                Timer {
                    interval: 1000
                    repeat: true
                    running: side.openHere && root.playing(root.spotify) && root.sideView !== "lyrics"
                    onTriggered: root.spotify.positionChanged()
                }

                Rectangle {
                    id: sideCard
                    visible: sideWin.showing
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    width: side.openHere ? 380 : sidePill.width
                    height: side.openHere ? Math.min(sideContent.implicitHeight + 36, sideWin.height - 20) : sidePill.height
                    radius: side.openHere ? 30 : 23
                    color: root.popupBg
                    border.width: 1
                    border.color: root.glassEdge
                    clip: true
                    Behavior on width { NumberAnimation { duration: root.animMs * 2.6; easing.type: Easing.OutBack; easing.overshoot: 0.8 } }
                    Behavior on height { NumberAnimation { duration: root.animMs * 2.6; easing.type: Easing.OutBack; easing.overshoot: 0.8 } }
                    Behavior on radius { NumberAnimation { duration: root.animMs * 2 } }

                    GlassShine { radius: parent.radius; dark: root.dark }

                    MouseArea { anchors.fill: parent }   // clicks inside don't fall through

                    ColumnLayout {
                        id: sideContent
                        width: 344
                        anchors.right: parent.right
                        anchors.rightMargin: 18
                        y: 18
                        spacing: 12
                        opacity: side.openHere ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: side.openHere ? root.animMs * 3 : root.animMs; easing.type: Easing.OutCubic } }

                        // ---- Header ----
                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                Layout.fillWidth: true
                                text: root.sideView === "lyrics" ? "Lyrics"
                                    : (root.sideView === "signal" || root.sideView === "signalChat") ? "Signal" : "Quick controls"
                                color: root.fg
                                font.pixelSize: 16
                                font.bold: true
                            }
                            Text {
                                text: ""
                                color: root.muted
                                font.family: root.iconFont
                                font.pixelSize: 14
                                MouseArea { anchors.fill: parent; anchors.margins: -8; cursorShape: Qt.PointingHandCursor; onClicked: root.sideOpen = false }
                            }
                        }

                        // ---- Lyrics view ----
                        ColumnLayout {
                            visible: root.sideView === "lyrics"
                            Layout.fillWidth: true
                            spacing: 10

                            // back + song
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                BarButton {
                                    theme: root
                                    icon: "\uf053"
                                    label: "Back"
                                    onClicked: mouse => { root.sideView = "main"; }
                                }
                                Rectangle {
                                    Layout.preferredWidth: 40
                                    Layout.preferredHeight: 40
                                    radius: 10
                                    color: root.overlay
                                    clip: true
                                    Image {
                                        anchors.fill: parent
                                        source: root.spotify ? root.spotify.trackArtUrl : ""
                                        fillMode: Image.PreserveAspectCrop
                                        visible: status === Image.Ready
                                    }
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0
                                    Text {
                                        Layout.fillWidth: true
                                        text: root.spotify ? (root.spotify.trackTitle || "") : "Nothing playing"
                                        color: root.fg
                                        font.pixelSize: 13
                                        font.bold: true
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        text: root.spotify ? (root.spotify.trackArtist || "") : ""
                                        color: root.muted
                                        font.pixelSize: 11
                                        elide: Text.ElideRight
                                    }
                                }
                            }

                            HubCard {
                                theme: root
                                Layout.fillWidth: true
                                Layout.preferredHeight: 470

                                ListView {
                                    id: lyricView
                                    anchors.fill: parent
                                    anchors.margins: 14
                                    clip: true
                                    spacing: 10
                                    model: root.lyricsLines
                                    currentIndex: root.lyricsIndex
                                    // keep the line being sung a little above the middle
                                    highlightRangeMode: root.lyricsSynced && root.lyricsIndex >= 0 ? ListView.ApplyRange : ListView.NoHighlightRange
                                    preferredHighlightBegin: height * 0.35
                                    preferredHighlightEnd: height * 0.45
                                    highlightMoveDuration: 450
                                    boundsBehavior: Flickable.StopAtBounds

                                    delegate: Text {
                                        id: lyr
                                        required property var modelData
                                        required property int index
                                        readonly property bool now: root.lyricsSynced && lyr.index === root.lyricsIndex
                                        readonly property bool past: root.lyricsSynced && lyr.index < root.lyricsIndex
                                        width: lyricView.width
                                        text: lyr.modelData.text === "" ? "♪" : lyr.modelData.text
                                        wrapMode: Text.Wrap
                                        color: lyr.now ? root.fg : root.muted
                                        opacity: !root.lyricsSynced ? 0.9 : (lyr.now ? 1 : (lyr.past ? 0.35 : 0.6))
                                        font.pixelSize: lyr.now ? 19 : 15
                                        font.bold: lyr.now || !root.lyricsSynced
                                        Behavior on font.pixelSize { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                                        Behavior on opacity { NumberAnimation { duration: 250 } }

                                        // click a line to jump the song there
                                        MouseArea {
                                            anchors.fill: parent
                                            enabled: root.lyricsSynced && lyr.modelData.t >= 0
                                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                            onClicked: {
                                                const p = root.spotify;
                                                if (p && p.canSeek) p.position = lyr.modelData.t;
                                            }
                                        }
                                    }
                                }

                                // loading / nothing found
                                Column {
                                    anchors.centerIn: parent
                                    visible: root.lyricsStatus !== "ok"
                                    spacing: 8
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: root.lyricsStatus === "loading" ? "\uf110" : "\uf001"
                                        color: root.muted
                                        font.family: root.iconFont
                                        font.pixelSize: 30
                                        RotationAnimation on rotation {
                                            running: root.lyricsStatus === "loading"
                                            loops: Animation.Infinite
                                            from: 0
                                            to: 360
                                            duration: 1200
                                        }
                                    }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        horizontalAlignment: Text.AlignHCenter
                                        text: !root.spotify ? "Play something on Spotify"
                                            : root.lyricsStatus === "loading" ? "Finding lyrics…"
                                            : root.lyricsStatus === "error" ? "Couldn't reach the lyrics service.\nCheck your internet."
                                            : "No lyrics found for this song"
                                        color: root.muted
                                        font.pixelSize: 13
                                    }
                                }
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: root.lyricsSynced ? "Synced lyrics from LRCLIB · click a line to jump to it" : "Lyrics from LRCLIB"
                                color: root.muted
                                font.pixelSize: 10
                                opacity: 0.8
                            }
                        }

                        // ---- Signal: chat list ----
                        ColumnLayout {
                            visible: root.sideView === "signal"
                            Layout.fillWidth: true
                            spacing: 10

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10
                                BarButton {
                                    theme: root
                                    icon: ""
                                    label: "Back"
                                    onClicked: mouse => { root.sideView = "main"; }
                                }
                                Item { Layout.fillWidth: true }
                                Rectangle {
                                    width: 8
                                    height: 8
                                    radius: 4
                                    color: root.sigReady ? "#4ade80" : "#fbbf24"
                                }
                                Text {
                                    text: root.sigReady ? "Connected" : "Connecting…"
                                    color: root.muted
                                    font.pixelSize: 11
                                }
                            }

                            HubCard {
                                theme: root
                                Layout.fillWidth: true
                                Layout.preferredHeight: sideWin.height - 150

                                ListView {
                                    id: chatList
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    clip: true
                                    spacing: 4
                                    boundsBehavior: Flickable.StopAtBounds
                                    // chats first (newest on top), then contacts you haven't messaged here yet
                                    model: {
                                        const out = root.sigChatList.slice();
                                        const have = {};
                                        for (let i = 0; i < out.length; i++) have[out[i].key] = true;
                                        for (let i = 0; i < root.sigContacts.length; i++) {
                                            const c = root.sigContacts[i];
                                            if (!have[c.key]) out.push({ key: c.key, name: c.name, group: false, id: c.id, msgs: [], unread: 0, last: 0, contact: true });
                                        }
                                        return out;
                                    }

                                    delegate: Rectangle {
                                        id: chatRow
                                        required property var modelData
                                        readonly property var lastMsg: chatRow.modelData.msgs.length > 0
                                            ? chatRow.modelData.msgs[chatRow.modelData.msgs.length - 1] : null
                                        width: chatList.width
                                        height: 58
                                        radius: 14
                                        color: chatMouse.containsMouse ? root.overlay : "transparent"
                                        Behavior on color { ColorAnimation { duration: root.animMs } }

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 8
                                            anchors.rightMargin: 10
                                            spacing: 10

                                            // round avatar with the first letter
                                            Rectangle {
                                                Layout.preferredWidth: 40
                                                Layout.preferredHeight: 40
                                                radius: 20
                                                color: chatRow.modelData.group ? Qt.rgba(0.23, 0.46, 0.94, 0.35) : root.overlay
                                                border.width: 1
                                                border.color: root.glassEdge
                                                Text {
                                                    anchors.centerIn: parent
                                                    text: chatRow.modelData.group ? "" : (chatRow.modelData.name || "?").charAt(0).toUpperCase()
                                                    font.family: chatRow.modelData.group ? root.iconFont : ""
                                                    color: root.fg
                                                    font.pixelSize: chatRow.modelData.group ? 14 : 16
                                                    font.bold: true
                                                }
                                            }

                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 1
                                                Text {
                                                    Layout.fillWidth: true
                                                    text: chatRow.modelData.name || chatRow.modelData.id
                                                    color: root.fg
                                                    font.pixelSize: 13
                                                    font.bold: chatRow.modelData.unread > 0
                                                    elide: Text.ElideRight
                                                }
                                                Text {
                                                    Layout.fillWidth: true
                                                    text: chatRow.lastMsg
                                                        ? (chatRow.lastMsg.me ? "You: " : (chatRow.modelData.group ? chatRow.lastMsg.from + ": " : "")) + chatRow.lastMsg.text
                                                        : (chatRow.modelData.contact ? "Start a chat" : "No messages yet")
                                                    color: chatRow.modelData.unread > 0 ? root.fg : root.muted
                                                    font.pixelSize: 11
                                                    elide: Text.ElideRight
                                                }
                                            }

                                            ColumnLayout {
                                                spacing: 3
                                                Text {
                                                    Layout.alignment: Qt.AlignRight
                                                    text: root.sigTime(chatRow.modelData.last)
                                                    color: root.muted
                                                    font.pixelSize: 10
                                                }
                                                Rectangle {
                                                    Layout.alignment: Qt.AlignRight
                                                    visible: chatRow.modelData.unread > 0
                                                    implicitWidth: Math.max(18, unreadText.implicitWidth + 8)
                                                    implicitHeight: 18
                                                    radius: 9
                                                    color: "#3a76f0"
                                                    Text {
                                                        id: unreadText
                                                        anchors.centerIn: parent
                                                        text: chatRow.modelData.unread
                                                        color: "white"
                                                        font.pixelSize: 10
                                                        font.bold: true
                                                    }
                                                }
                                            }
                                        }

                                        MouseArea {
                                            id: chatMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.sigOpen(chatRow.modelData.key, chatRow.modelData.name, chatRow.modelData.group, chatRow.modelData.id)
                                        }
                                    }
                                }

                                Column {
                                    anchors.centerIn: parent
                                    visible: chatList.count === 0
                                    spacing: 8
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: ""
                                        color: root.muted
                                        font.family: root.iconFont
                                        font.pixelSize: 32
                                    }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        horizontalAlignment: Text.AlignHCenter
                                        text: root.sigReady ? "No chats yet.\nNew messages will show up here." : "Starting Signal…"
                                        color: root.muted
                                        font.pixelSize: 12
                                    }
                                }
                            }
                        }

                        // ---- Signal: one chat ----
                        ColumnLayout {
                            id: chatView
                            visible: root.sideView === "signalChat"
                            Layout.fillWidth: true
                            spacing: 10
                            readonly property var chat: root.sigChats[root.sigCurrent] || null

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10
                                BarButton {
                                    theme: root
                                    icon: ""
                                    label: "Chats"
                                    onClicked: mouse => { root.sideView = "signal"; }
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: chatView.chat ? (chatView.chat.name || chatView.chat.id) : ""
                                    color: root.fg
                                    font.pixelSize: 14
                                    font.bold: true
                                    elide: Text.ElideRight
                                }
                            }

                            HubCard {
                                theme: root
                                Layout.fillWidth: true
                                Layout.preferredHeight: sideWin.height - 210

                                ListView {
                                    id: msgList
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    clip: true
                                    spacing: 6
                                    boundsBehavior: Flickable.StopAtBounds
                                    model: chatView.chat ? chatView.chat.msgs : []
                                    onCountChanged: Qt.callLater(() => msgList.positionViewAtEnd())
                                    onVisibleChanged: if (visible) Qt.callLater(() => msgList.positionViewAtEnd())

                                    delegate: Item {
                                        id: bub
                                        required property var modelData
                                        width: msgList.width
                                        height: bubble.height + (bubName.visible ? bubName.implicitHeight + 2 : 0)

                                        Text {
                                            id: bubName
                                            visible: !bub.modelData.me && !!chatView.chat && chatView.chat.group
                                            x: 6
                                            text: bub.modelData.from
                                            color: root.accent
                                            font.pixelSize: 10
                                            font.bold: true
                                        }

                                        Rectangle {
                                            id: bubble
                                            y: bubName.visible ? bubName.implicitHeight + 2 : 0
                                            anchors.right: bub.modelData.me ? parent.right : undefined
                                            anchors.left: bub.modelData.me ? undefined : parent.left
                                            width: Math.min(bubText.implicitWidth + 24, msgList.width * 0.8)
                                            height: bubText.implicitHeight + bubTime.implicitHeight + 16
                                            radius: 16
                                            color: bub.modelData.me ? Qt.rgba(0.23, 0.46, 0.94, 0.85) : root.overlay
                                            border.width: 1
                                            border.color: root.glassEdge

                                            Text {
                                                id: bubText
                                                x: 12
                                                y: 7
                                                width: Math.min(implicitWidth, msgList.width * 0.8 - 24)
                                                text: bub.modelData.text
                                                wrapMode: Text.Wrap
                                                color: bub.modelData.me ? "white" : root.fg
                                                font.pixelSize: 13
                                            }
                                            Text {
                                                id: bubTime
                                                anchors.right: parent.right
                                                anchors.rightMargin: 10
                                                anchors.bottom: parent.bottom
                                                anchors.bottomMargin: 4
                                                text: root.sigTime(bub.modelData.ts)
                                                color: bub.modelData.me ? Qt.rgba(1, 1, 1, 0.75) : root.muted
                                                font.pixelSize: 9
                                            }
                                        }
                                    }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    visible: msgList.count === 0
                                    text: "Say hi 👋"
                                    color: root.muted
                                    font.pixelSize: 13
                                }
                            }

                            // ---- type + send ----
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 44
                                    radius: 22
                                    color: root.surface
                                    border.width: 1
                                    border.color: sigInput.activeFocus ? root.accent : root.glassEdge

                                    TextInput {
                                        id: sigInput
                                        anchors.fill: parent
                                        anchors.leftMargin: 16
                                        anchors.rightMargin: 16
                                        verticalAlignment: TextInput.AlignVCenter
                                        color: root.fg
                                        font.pixelSize: 13
                                        clip: true
                                        selectByMouse: true
                                        Keys.onReturnPressed: sendBtn.send()
                                        Keys.onEnterPressed: sendBtn.send()
                                        Keys.onEscapePressed: root.sideView = "signal"

                                        Text {
                                            anchors.fill: parent
                                            verticalAlignment: Text.AlignVCenter
                                            visible: sigInput.text === ""
                                            text: root.sigReady ? "Message" : "Connecting to Signal…"
                                            color: root.muted
                                            font.pixelSize: 13
                                        }
                                    }

                                    Connections {
                                        target: root
                                        function onSigCurrentChanged() {
                                            sigInput.text = "";
                                            sigInput.forceActiveFocus();
                                        }
                                    }
                                }

                                Rectangle {
                                    id: sendBtn
                                    Layout.preferredWidth: 44
                                    Layout.preferredHeight: 44
                                    radius: 22
                                    readonly property bool ok: root.sigReady && sigInput.text.trim() !== ""
                                    color: sendBtn.ok ? "#3a76f0" : root.overlay
                                    scale: sendMouse.pressed ? 0.9 : 1
                                    Behavior on color { ColorAnimation { duration: root.animMs } }
                                    Behavior on scale { NumberAnimation { duration: root.animMs; easing.type: Easing.OutBack } }

                                    function send() {
                                        if (root.sigSend(root.sigCurrent, sigInput.text)) sigInput.text = "";
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: ""
                                        color: "white"
                                        font.family: root.iconFont
                                        font.pixelSize: 15
                                    }
                                    MouseArea {
                                        id: sendMouse
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: sendBtn.send()
                                    }
                                }
                            }
                        }

                        // ---- Main view: brightness, Spotify, Vesktop, Signal (scrolls if it gets tall) ----
                        Flickable {
                            id: sideScroll
                            visible: root.sideView === "main"
                            Layout.fillWidth: true
                            Layout.preferredHeight: Math.min(sideMain.implicitHeight, sideWin.height - 130)
                            contentHeight: sideMain.implicitHeight
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds

                            ColumnLayout {
                                id: sideMain
                                width: sideScroll.width
                                spacing: 12

                                // ---- Brightness ----
                                HubCard {
                                    theme: root
                                    visible: root.sideView === "main"
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: brightCol.implicitHeight + 28

                                    ColumnLayout {
                                        id: brightCol
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.top: parent.top
                                        anchors.margins: 14
                                        spacing: 10

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 8
                                            Text { text: ""; color: root.accent; font.family: root.iconFont; font.pixelSize: 15 }
                                            Text { Layout.fillWidth: true; text: "Brightness"; color: root.fg; font.pixelSize: 14; font.bold: true }
                                            Text {
                                                visible: root.brightLoading
                                                text: "Checking…"
                                                color: root.muted
                                                font.pixelSize: 11
                                            }
                                        }

                                        // all monitors at once (only with more than one)
                                        RowLayout {
                                            visible: root.brightDisplays.length > 1
                                            Layout.fillWidth: true
                                            spacing: 10
                                            Text { Layout.preferredWidth: 84; text: "All screens"; color: root.fg; font.pixelSize: 12; font.bold: true }
                                            ValueBar {
                                                theme: root
                                                Layout.fillWidth: true
                                                value: Math.max(0, root.brightAvg) / 100
                                                onMoved: v => root.setAllBrightness(v * 100)
                                            }
                                            Text { Layout.preferredWidth: 36; horizontalAlignment: Text.AlignRight; text: root.brightAvg + "%"; color: root.fg; font.pixelSize: 12 }
                                        }

                                        Repeater {
                                            model: root.brightDisplays
                                            delegate: RowLayout {
                                                id: bRow
                                                required property var modelData
                                                Layout.fillWidth: true
                                                spacing: 10
                                                Text {
                                                    Layout.preferredWidth: 84
                                                    text: bRow.modelData.name
                                                    color: root.muted
                                                    font.pixelSize: 12
                                                    elide: Text.ElideRight
                                                }
                                                ValueBar {
                                                    theme: root
                                                    Layout.fillWidth: true
                                                    value: bRow.modelData.value / 100
                                                    onMoved: v => root.setBrightness(bRow.modelData.id, v * 100)
                                                }
                                                Text {
                                                    Layout.preferredWidth: 36
                                                    horizontalAlignment: Text.AlignRight
                                                    text: bRow.modelData.value + "%"
                                                    color: root.fg
                                                    font.pixelSize: 12
                                                }
                                            }
                                        }

                                        // nothing found
                                        Text {
                                            visible: !root.brightLoading && root.brightDisplays.length === 0
                                            Layout.fillWidth: true
                                            wrapMode: Text.Wrap
                                            text: root.brightNoDdc
                                                ? "Monitor brightness needs ddcutil. In a terminal:\nsudo pacman -S ddcutil"
                                                : "No monitors answered. Make sure DDC/CI is turned on in your monitor's own menu."
                                            color: root.muted
                                            font.pixelSize: 12
                                        }
                                    }
                                }

                                // ---- Spotify ----
                                HubCard {
                                    theme: root
                                    visible: root.sideView === "main"
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: spCol.implicitHeight + 28

                                    // click the Spotify section to see the lyrics
                                    MouseArea {
                                        anchors.fill: parent
                                        enabled: root.spotify !== null
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.showLyrics()
                                    }

                                    ColumnLayout {
                                        id: spCol
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.top: parent.top
                                        anchors.margins: 14
                                        spacing: 10

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 8
                                            IconImage {
                                                visible: root.spotifyIcon !== ""
                                                implicitSize: 18
                                                source: root.spotifyIcon
                                            }
                                            Text {
                                                visible: root.spotifyIcon === ""
                                                text: "\uf1bc"
                                                color: "#1ed760"
                                                font.family: root.iconFont
                                                font.pixelSize: 16
                                            }
                                            Text { Layout.fillWidth: true; text: "Spotify"; color: root.fg; font.pixelSize: 14; font.bold: true }
                                            Text {
                                                visible: root.spotify !== null
                                                text: root.playing(root.spotify) ? "Playing" : "Paused"
                                                color: root.playing(root.spotify) ? root.accent : root.muted
                                                font.pixelSize: 11
                                            }
                                            BarButton {
                                                visible: root.spotify !== null
                                                theme: root
                                                icon: "\uf130"
                                                label: "Lyrics"
                                                onClicked: mouse => root.showLyrics()
                                            }
                                        }

                                        // now playing
                                        RowLayout {
                                            visible: root.spotify !== null
                                            Layout.fillWidth: true
                                            spacing: 12

                                            Rectangle {
                                                Layout.preferredWidth: 76
                                                Layout.preferredHeight: 76
                                                radius: 14
                                                color: root.overlay
                                                clip: true
                                                Image {
                                                    anchors.fill: parent
                                                    source: root.spotify ? root.spotify.trackArtUrl : ""
                                                    fillMode: Image.PreserveAspectCrop
                                                    visible: status === Image.Ready
                                                }
                                                GlassShine { radius: parent.radius; dark: root.dark; strength: 0.7 }
                                            }

                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 2
                                                Text {
                                                    Layout.fillWidth: true
                                                    text: root.spotify ? (root.spotify.trackTitle || "Unknown song") : ""
                                                    color: root.fg
                                                    font.pixelSize: 14
                                                    font.bold: true
                                                    elide: Text.ElideRight
                                                }
                                                Text {
                                                    Layout.fillWidth: true
                                                    text: root.spotify ? root.spotify.trackArtist : ""
                                                    color: root.muted
                                                    font.pixelSize: 12
                                                    elide: Text.ElideRight
                                                }
                                                Item { Layout.preferredHeight: 4 }
                                                RowLayout {
                                                    spacing: 6
                                                    IconButton {
                                                        theme: root
                                                        label: "|◀"
                                                        dim: !(root.spotify && root.spotify.canGoPrevious)
                                                        onClicked: if (root.spotify && root.spotify.canGoPrevious) root.spotify.previous()
                                                    }
                                                    IconButton {
                                                        theme: root
                                                        implicitWidth: 54
                                                        label: root.playing(root.spotify) ? "❚❚" : "▶"
                                                        dim: !(root.spotify && root.spotify.canTogglePlaying)
                                                        onClicked: if (root.spotify && root.spotify.canTogglePlaying) root.spotify.togglePlaying()
                                                    }
                                                    IconButton {
                                                        theme: root
                                                        label: "▶|"
                                                        dim: !(root.spotify && root.spotify.canGoNext)
                                                        onClicked: if (root.spotify && root.spotify.canGoNext) root.spotify.next()
                                                    }
                                                }
                                            }
                                        }

                                        ValueBar {
                                            visible: root.spotify !== null
                                            theme: root
                                            Layout.fillWidth: true
                                            value: root.spotify && root.spotify.length > 0 ? root.spotify.position / root.spotify.length : 0
                                            onMoved: v => {
                                                const p = root.spotify;
                                                if (p && p.canSeek && p.length > 0) p.position = v * p.length;
                                            }
                                        }
                                        RowLayout {
                                            visible: root.spotify !== null
                                            Layout.fillWidth: true
                                            Text { text: root.fmt(root.spotify ? root.spotify.position : 0); color: root.muted; font.pixelSize: 10 }
                                            Item { Layout.fillWidth: true }
                                            Text { text: root.fmt(root.spotify ? root.spotify.length : 0); color: root.muted; font.pixelSize: 10 }
                                        }

                                        // shuffle, repeat all, repeat one
                                        RowLayout {
                                            visible: root.spotify !== null
                                            Layout.fillWidth: true
                                            spacing: 8

                                            Repeater {
                                                model: [
                                                    {
                                                        icon: "\uf074", name: "Shuffle",
                                                        on: !!(root.spotify && root.spotify.shuffle),
                                                        ok: !!(root.spotify && root.spotify.shuffleSupported),
                                                        act: () => root.spotifyShuffle()
                                                    },
                                                    {
                                                        icon: "\uf01e", name: "Repeat all",
                                                        on: !!(root.spotify && root.spotify.loopState === MprisLoopState.Playlist),
                                                        ok: !!(root.spotify && root.spotify.loopSupported),
                                                        act: () => root.spotifyRepeat("playlist")
                                                    },
                                                    {
                                                        icon: "\uf01e", name: "Repeat one",
                                                        on: !!(root.spotify && root.spotify.loopState === MprisLoopState.Track),
                                                        ok: !!(root.spotify && root.spotify.loopSupported),
                                                        act: () => root.spotifyRepeat("track")
                                                    }
                                                ]
                                                delegate: Rectangle {
                                                    id: rpt
                                                    required property var modelData
                                                    Layout.fillWidth: true
                                                    Layout.preferredHeight: 34
                                                    radius: 12
                                                    opacity: rpt.modelData.ok ? 1 : 0.4
                                                    color: rpt.modelData.on ? root.accent : (rptMouse.containsMouse ? root.overlay : root.surface)
                                                    border.width: 1
                                                    border.color: root.glassEdge
                                                    scale: rptMouse.pressed ? 0.94 : 1
                                                    Behavior on color { ColorAnimation { duration: root.animMs } }
                                                    Behavior on scale { NumberAnimation { duration: root.animMs; easing.type: Easing.OutBack } }
                                                    Row {
                                                        anchors.centerIn: parent
                                                        spacing: 6
                                                        Text {
                                                            anchors.verticalCenter: parent.verticalCenter
                                                            text: rpt.modelData.icon
                                                            color: rpt.modelData.on ? root.bg : root.accent
                                                            font.family: root.iconFont
                                                            font.pixelSize: 11
                                                        }
                                                        Text {
                                                            anchors.verticalCenter: parent.verticalCenter
                                                            text: rpt.modelData.name
                                                            color: rpt.modelData.on ? root.bg : root.fg
                                                            font.pixelSize: 11
                                                            font.bold: rpt.modelData.on
                                                        }
                                                    }
                                                    // a little "1" on the repeat-one button
                                                    Rectangle {
                                                        visible: rpt.modelData.name === "Repeat one"
                                                        anchors.top: parent.top
                                                        anchors.right: parent.right
                                                        anchors.margins: 4
                                                        width: 12
                                                        height: 12
                                                        radius: 6
                                                        color: rpt.modelData.on ? root.bg : root.accent
                                                        Text {
                                                            anchors.centerIn: parent
                                                            text: "1"
                                                            color: rpt.modelData.on ? root.accent : root.bg
                                                            font.pixelSize: 8
                                                            font.bold: true
                                                        }
                                                    }
                                                    MouseArea {
                                                        id: rptMouse
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        cursorShape: rpt.modelData.ok ? Qt.PointingHandCursor : Qt.ArrowCursor
                                                        onClicked: if (rpt.modelData.ok) rpt.modelData.act()
                                                    }
                                                }
                                            }
                                        }

                                        // music volume: - slider +
                                        RowLayout {
                                            visible: root.spotify !== null
                                            Layout.fillWidth: true
                                            spacing: 8
                                            IconButton {
                                                theme: root
                                                implicitWidth: 34
                                                implicitHeight: 30
                                                label: "−"
                                                dim: root.spotifyVolume < 0
                                                onClicked: root.spotifyVolumeStep(-0.05)
                                            }
                                            ValueBar {
                                                theme: root
                                                Layout.fillWidth: true
                                                value: Math.max(0, root.spotifyVolume)
                                                onMoved: v => root.setSpotifyVolume(v)
                                            }
                                            IconButton {
                                                theme: root
                                                implicitWidth: 34
                                                implicitHeight: 30
                                                label: "+"
                                                dim: root.spotifyVolume < 0
                                                onClicked: root.spotifyVolumeStep(0.05)
                                            }
                                            Text {
                                                Layout.preferredWidth: 34
                                                horizontalAlignment: Text.AlignRight
                                                text: root.spotifyVolume >= 0 ? Math.round(root.spotifyVolume * 100) + "%" : "--"
                                                color: root.fg
                                                font.pixelSize: 11
                                            }
                                        }

                                        // not open
                                        RowLayout {
                                            visible: root.spotify === null
                                            Layout.fillWidth: true
                                            Text {
                                                Layout.fillWidth: true
                                                text: "Spotify isn't open"
                                                color: root.muted
                                                font.pixelSize: 12
                                            }
                                            BarButton {
                                                theme: root
                                                icon: ""
                                                label: "Open"
                                                onClicked: mouse => root.openSpotify()
                                            }
                                        }
                                    }
                                }

                                // ---- Vesktop (Discord) ----
                                HubCard {
                                    theme: root
                                    visible: root.sideView === "main"
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: dcCol.implicitHeight + 28

                                    ColumnLayout {
                                        id: dcCol
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.top: parent.top
                                        anchors.margins: 14
                                        spacing: 10

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 8
                                            IconImage {
                                                visible: root.vesktopIcon !== ""
                                                implicitSize: 18
                                                source: root.vesktopIcon
                                            }
                                            Text {
                                                visible: root.vesktopIcon === ""
                                                text: "\uf086"
                                                color: "#5865f2"
                                                font.family: root.iconFont
                                                font.pixelSize: 15
                                            }
                                            Text { Layout.fillWidth: true; text: "Vesktop"; color: root.fg; font.pixelSize: 14; font.bold: true }
                                            BarButton {
                                                theme: root
                                                icon: root.discordRunning ? "" : ""
                                                label: root.discordRunning ? "Show" : "Open"
                                                onClicked: mouse => root.openDiscord()
                                            }
                                        }

                                        // quick call controls (whole computer, works in any call)
                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 8

                                            Repeater {
                                                model: [
                                                    {
                                                        icon: root.source && root.source.audio && root.source.audio.muted ? "" : "",
                                                        name: root.source && root.source.audio && root.source.audio.muted ? "Mic muted" : "Mic on",
                                                        on: !!(root.source && root.source.audio && root.source.audio.muted),
                                                        act: () => { if (root.source && root.source.audio) root.source.audio.muted = !root.source.audio.muted; }
                                                    },
                                                    {
                                                        icon: root.sink && root.sink.audio && root.sink.audio.muted ? "" : "",
                                                        name: root.sink && root.sink.audio && root.sink.audio.muted ? "Deafened" : "Sound on",
                                                        on: !!(root.sink && root.sink.audio && root.sink.audio.muted),
                                                        act: () => { if (root.sink && root.sink.audio) root.sink.audio.muted = !root.sink.audio.muted; }
                                                    }
                                                ]
                                                delegate: Rectangle {
                                                    id: callBtn
                                                    required property var modelData
                                                    Layout.fillWidth: true
                                                    Layout.preferredHeight: 40
                                                    radius: 14
                                                    color: callBtn.modelData.on ? Qt.rgba(root.danger.r, root.danger.g, root.danger.b, 0.25)
                                                        : (callMouse.containsMouse ? root.overlay : root.surface)
                                                    border.width: 1
                                                    border.color: callBtn.modelData.on ? root.danger : root.glassEdge
                                                    scale: callMouse.pressed ? 0.95 : 1
                                                    Behavior on color { ColorAnimation { duration: root.animMs } }
                                                    Behavior on scale { NumberAnimation { duration: root.animMs; easing.type: Easing.OutBack } }
                                                    Row {
                                                        anchors.centerIn: parent
                                                        spacing: 8
                                                        Text {
                                                            anchors.verticalCenter: parent.verticalCenter
                                                            text: callBtn.modelData.icon
                                                            color: callBtn.modelData.on ? root.danger : root.accent
                                                            font.family: root.iconFont
                                                            font.pixelSize: 14
                                                        }
                                                        Text {
                                                            anchors.verticalCenter: parent.verticalCenter
                                                            text: callBtn.modelData.name
                                                            color: root.fg
                                                            font.pixelSize: 12
                                                        }
                                                    }
                                                    MouseArea {
                                                        id: callMouse
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: callBtn.modelData.act()
                                                    }
                                                }
                                            }
                                        }

                                        // latest Vesktop messages (from its notifications)
                                        Text {
                                            text: root.discordNotifs.length > 0 ? "New messages" : "No new messages"
                                            color: root.muted
                                            font.pixelSize: 11
                                        }

                                        Repeater {
                                            model: root.discordNotifs.slice(0, 3)
                                            delegate: Rectangle {
                                                id: dmsg
                                                required property var modelData
                                                Layout.fillWidth: true
                                                Layout.preferredHeight: dmsgCol.implicitHeight + 18
                                                radius: 14
                                                color: dmsgMouse.containsMouse ? root.overlay : root.surface
                                                border.width: 1
                                                border.color: root.glassEdge

                                                ColumnLayout {
                                                    id: dmsgCol
                                                    anchors.left: parent.left
                                                    anchors.right: parent.right
                                                    anchors.top: parent.top
                                                    anchors.margins: 9
                                                    anchors.rightMargin: 28
                                                    spacing: 1
                                                    Text {
                                                        Layout.fillWidth: true
                                                        text: dmsg.modelData.summary
                                                        color: root.fg
                                                        font.pixelSize: 12
                                                        font.bold: true
                                                        elide: Text.ElideRight
                                                    }
                                                    Text {
                                                        Layout.fillWidth: true
                                                        visible: text !== ""
                                                        text: dmsg.modelData.body
                                                        color: root.muted
                                                        font.pixelSize: 11
                                                        wrapMode: Text.Wrap
                                                        maximumLineCount: 2
                                                        elide: Text.ElideRight
                                                    }
                                                }

                                                // click opens Vesktop, × dismisses
                                                MouseArea {
                                                    id: dmsgMouse
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        dmsg.modelData.dismiss();
                                                        root.openDiscord();
                                                    }
                                                }
                                                Text {
                                                    anchors.top: parent.top
                                                    anchors.right: parent.right
                                                    anchors.margins: 9
                                                    text: ""
                                                    color: root.muted
                                                    font.family: root.iconFont
                                                    font.pixelSize: 11
                                                    MouseArea {
                                                        anchors.fill: parent
                                                        anchors.margins: -6
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: dmsg.modelData.dismiss()
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                // ---- Signal ----
                                HubCard {
                                    theme: root
                                    visible: root.sideView === "main"
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: sgCol.implicitHeight + 28

                                    ColumnLayout {
                                        id: sgCol
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.top: parent.top
                                        anchors.margins: 14
                                        spacing: 10

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 8
                                            IconImage {
                                                visible: root.signalIcon !== ""
                                                implicitSize: 18
                                                source: root.signalIcon
                                            }
                                            Text {
                                                visible: root.signalIcon === ""
                                                text: "\uf075"
                                                color: "#3a76f0"
                                                font.family: root.iconFont
                                                font.pixelSize: 15
                                            }
                                            Text { Layout.fillWidth: true; text: "Signal"; color: root.fg; font.pixelSize: 14; font.bold: true }
                                            BarButton {
                                                visible: root.sigAccount !== ""
                                                theme: root
                                                icon: "\uf086"
                                                label: root.sigUnreadTotal > 0 ? "Chats (" + root.sigUnreadTotal + ")" : "Chats"
                                                onClicked: mouse => { root.sideView = "signal"; }
                                            }
                                            BarButton {
                                                theme: root
                                                icon: root.signalRunning ? "" : ""
                                                label: root.signalRunning ? "Show" : "Open"
                                                onClicked: mouse => root.openSignal()
                                            }
                                        }

                                                // not set up for reading/replying here yet
                                        Text {
                                            visible: root.sigAccount === ""
                                            Layout.fillWidth: true
                                            wrapMode: Text.Wrap
                                            text: root.sigCliMissing
                                                ? "To read and reply right here, install signal-cli:\nparu -S signal-cli qrencode"
                                                : "To read and reply right here, run this once in a terminal:\n~/.config/quickshell/scripts/signal-setup.sh"
                                            color: root.muted
                                            font.pixelSize: 11
                                        }

                                        // latest Signal messages (from its notifications)
                                        Text {
                                            text: root.signalNotifs.length > 0 ? "New messages" : "No new messages"
                                            color: root.muted
                                            font.pixelSize: 11
                                        }

                                        Repeater {
                                            model: root.signalNotifs.slice(0, 3)
                                            delegate: Rectangle {
                                                id: smsg
                                                required property var modelData
                                                Layout.fillWidth: true
                                                Layout.preferredHeight: smsgCol.implicitHeight + 18
                                                radius: 14
                                                color: smsgMouse.containsMouse ? root.overlay : root.surface
                                                border.width: 1
                                                border.color: root.glassEdge

                                                ColumnLayout {
                                                    id: smsgCol
                                                    anchors.left: parent.left
                                                    anchors.right: parent.right
                                                    anchors.top: parent.top
                                                    anchors.margins: 9
                                                    anchors.rightMargin: 28
                                                    spacing: 1
                                                    Text {
                                                        Layout.fillWidth: true
                                                        text: smsg.modelData.summary
                                                        color: root.fg
                                                        font.pixelSize: 12
                                                        font.bold: true
                                                        elide: Text.ElideRight
                                                    }
                                                    Text {
                                                        Layout.fillWidth: true
                                                        visible: text !== ""
                                                        text: smsg.modelData.body
                                                        color: root.muted
                                                        font.pixelSize: 11
                                                        wrapMode: Text.Wrap
                                                        maximumLineCount: 2
                                                        elide: Text.ElideRight
                                                    }
                                                }

                                                // click opens Signal, × dismisses
                                                MouseArea {
                                                    id: smsgMouse
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        smsg.modelData.dismiss();
                                                        root.openSignal();
                                                    }
                                                }
                                                Text {
                                                    anchors.top: parent.top
                                                    anchors.right: parent.right
                                                    anchors.margins: 9
                                                    text: ""
                                                    color: root.muted
                                                    font.family: root.iconFont
                                                    font.pixelSize: 11
                                                    MouseArea {
                                                        anchors.fill: parent
                                                        anchors.margins: -6
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: smsg.modelData.dismiss()
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ---------- Wallpaper picker (scroll through, click or Enter to set) ----------
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: picker
            required property var modelData
            screen: modelData

            // stays up for a moment after closing so it can fade out
            property bool shown: false
            property real k: 0          // 0 = hidden, 1 = fully open
            visible: shown && (!Hyprland.focusedMonitor || Hyprland.focusedMonitor.name === modelData.name)

            Connections {
                target: root
                function onWallPickerOpenChanged() {
                    if (root.wallPickerOpen) {
                        picker.shown = true;
                        pickHide.stop();
                        pickShow.restart();
                    } else {
                        pickShow.stop();
                        pickHide.restart();
                    }
                }
            }
            NumberAnimation { id: pickShow; target: picker; property: "k"; to: 1; duration: 320; easing.type: Easing.OutCubic }
            NumberAnimation {
                id: pickHide
                target: picker
                property: "k"
                to: 0
                duration: 220
                easing.type: Easing.InCubic
                onFinished: picker.shown = false
            }

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell-wallpicker"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            exclusionMode: ExclusionMode.Ignore
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            color: Qt.rgba(0, 0, 0, 0.30 * picker.k)

            readonly property int thumbW: 360
            // which list the carousel shows: still pictures or live (video) wallpapers
            property string mode: "pictures"
            readonly property bool live: mode === "live"
            readonly property var src: live ? (root.liveThumbsReady ? liveVideos : emptyModel) : wallpapers
            ListModel { id: emptyModel }

            function setMode(m) {
                if (mode === m) return;
                mode = m;
                if (m === "live") root.refreshLiveThumbs();
                startFocus();
            }
            readonly property int thumbH: 210
            readonly property real slant: 0.24     // how far the cards lean
            property real wheelAcc: 0

            // Index of the wallpaper that's set right now (-1 if none)
            function currentWallIndex() {
                for (let i = 0; i < picker.src.count; i++)
                    if (picker.src.get(i, "fileUrl").toString() === (picker.live ? pins.adapter.liveWallpaper : pins.adapter.wallpaper)) return i;
                return -1;
            }

            // Jump straight to the wallpaper that's set right now. The picker opens before the
            // list has its size (and sometimes before the folder has loaded), so this runs a few
            // times over the first half second, unless you start moving through the list yourself.
            property bool jumping: false
            property int focusTries: 0
            function focusCurrent() {
                if (picker.src.count === 0) return;
                const i = currentWallIndex();
                jumping = true;
                strip.currentIndex = i >= 0 ? i : 0;
                strip.positionViewAtIndex(strip.currentIndex, ListView.Center);
            }
            function startFocus() {
                focusTries = 0;
                focusCurrent();
                focusTimer.restart();
            }
            function stopFocus() {
                focusTimer.stop();
                jumping = false;
            }
            Timer {
                id: focusTimer
                interval: 60
                repeat: true
                onTriggered: {
                    picker.focusCurrent();
                    if (++picker.focusTries >= 10) picker.stopFocus();
                }
            }
            Connections {
                target: picker.src
                ignoreUnknownSignals: true
                function onCountChanged() { if (focusTimer.running) picker.focusCurrent(); }
            }

            function step(n) {
                picker.stopFocus();
                if (picker.src.count === 0) return;
                strip.currentIndex = Math.max(0, Math.min(picker.src.count - 1, strip.currentIndex + n));
            }

            function applyCurrent() {
                if (strip.currentIndex < 0 || strip.currentIndex >= picker.src.count) return;
                const url = picker.src.get(strip.currentIndex, "fileUrl").toString();
                if (picker.live) root.setLiveWallpaper(url, picker.src.get(strip.currentIndex, "fileName"));
                else root.setWallpaper(url);
                root.wallPickerOpen = false;
            }

            onVisibleChanged: {
                if (visible) {
                    mode = pins.adapter.liveWallpaper !== "" ? "live" : "pictures";
                    if (live) root.refreshLiveThumbs();
                    startFocus();
                    keys.forceActiveFocus();
                }
            }

            // Click outside the card to close
            MouseArea {
                anchors.fill: parent
                onClicked: root.wallPickerOpen = false
            }

            Item {
                id: keys
                focus: true
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) root.wallPickerOpen = false;
                    else if (event.key === Qt.Key_Right || event.key === Qt.Key_Down || event.key === Qt.Key_Tab) picker.step(1);
                    else if (event.key === Qt.Key_Left || event.key === Qt.Key_Up || event.key === Qt.Key_Backtab) picker.step(-1);
                    else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) picker.applyCurrent();
                    else if (event.key === Qt.Key_R) {
                        if (picker.live) {
                            if (picker.src.count > 0) {
                                strip.currentIndex = Math.floor(Math.random() * picker.src.count);
                                picker.applyCurrent();
                            }
                        } else root.randomWallpaper();
                    }
                    else return;
                    event.accepted = true;
                }
            }

            Item {
                id: wcardPick
                opacity: picker.k
                scale: 0.96 + 0.04 * picker.k

                width: Math.min(picker.width - 40, 1700)
                height: 560
                anchors.centerIn: parent

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 14

                    // ---- Header: a glass pill above the cards ----
                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        implicitWidth: pickHead.implicitWidth + 28
                        implicitHeight: pickHead.implicitHeight + 16
                        radius: height / 2
                        color: root.popupBg
                        border.width: 1
                        border.color: root.glassEdge
                        GlassShine { radius: parent.radius; dark: root.dark; strength: 0.7 }
                        MouseArea { anchors.fill: parent }    // clicks here don't close the picker

                    RowLayout {
                        id: pickHead
                        anchors.centerIn: parent
                        spacing: 10

                        Text {
                            text: ""
                            color: root.accent
                            font.family: root.iconFont
                            font.pixelSize: 18
                        }
                        Text {
                            text: "Wallpapers"
                            color: root.fg
                            font.pixelSize: 17
                            font.bold: true
                        }
                        Buddy { theme: root; slot: 4; size: 30 }
                        Text {
                            visible: picker.src.count > 0
                            text: (strip.currentIndex + 1) + " / " + picker.src.count
                            color: root.muted
                            font.pixelSize: 13
                        }

                        Item { Layout.fillWidth: true }

                        // ---- Pictures | Live ----
                        Rectangle {
                            implicitWidth: modeRow.implicitWidth + 8
                            implicitHeight: 38
                            radius: 13
                            color: root.surface
                            border.width: 1
                            border.color: root.glassEdge

                            Row {
                                id: modeRow
                                anchors.centerIn: parent
                                spacing: 3
                                Repeater {
                                    model: [
                                        { key: "pictures", name: "Pictures", icon: "\uf03e" },
                                        { key: "live", name: "Live", icon: "\uf03d" }
                                    ]
                                    delegate: Rectangle {
                                        id: modeBtn
                                        required property var modelData
                                        readonly property bool on: picker.mode === modeBtn.modelData.key
                                        width: modeBtnRow.implicitWidth + 22
                                        height: 30
                                        radius: 10
                                        color: modeBtn.on ? root.accent : (modeMouse.containsMouse ? root.overlay : "transparent")
                                        Behavior on color { ColorAnimation { duration: root.animMs } }
                                        Row {
                                            id: modeBtnRow
                                            anchors.centerIn: parent
                                            spacing: 6
                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: modeBtn.modelData.icon
                                                color: modeBtn.on ? root.bg : root.accent
                                                font.family: root.iconFont
                                                font.pixelSize: 12
                                            }
                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: modeBtn.modelData.name
                                                color: modeBtn.on ? root.bg : root.fg
                                                font.pixelSize: 12
                                                font.bold: modeBtn.on
                                            }
                                        }
                                        MouseArea {
                                            id: modeMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: picker.setMode(modeBtn.modelData.key)
                                        }
                                    }
                                }
                            }
                        }

                        // pause / play the moving wallpaper
                        BarButton {
                            visible: picker.live && pins.adapter.liveWallpaper !== ""
                            theme: root
                            icon: root.livePaused ? "\uf04b" : "\uf04c"
                            label: root.livePaused ? "Play" : "Pause"
                            onClicked: mouse => { root.livePaused = !root.livePaused; }
                        }

                        BarButton {
                            theme: root
                            icon: "\uf074"
                            label: "Random"
                            onClicked: mouse => {
                                picker.stopFocus();
                                if (picker.live) {
                                    if (picker.src.count === 0) return;
                                    strip.currentIndex = Math.floor(Math.random() * picker.src.count);
                                    picker.applyCurrent();
                                    return;
                                }
                                root.randomWallpaper();
                                const i = picker.currentWallIndex();
                                if (i >= 0) strip.currentIndex = i;
                            }
                        }
                        BarButton {
                            theme: root
                            icon: ""
                            label: "Clear"
                            onClicked: mouse => root.setWallpaper("")
                        }
                    }
                    }

                    // ---- The carousel ----
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        ListView {
                            id: strip
                            anchors.fill: parent
                            orientation: ListView.Horizontal
                            model: picker.src
                            spacing: -64                        // side cards tuck behind the middle one
                            transform: Translate { x: (1 - picker.k) * 220 }   // cards slide in from the right
                            clip: false
                            interactive: true
                            boundsBehavior: Flickable.StopAtBounds
                            // keep the selected wallpaper in the middle
                            highlightRangeMode: ListView.StrictlyEnforceRange
                            preferredHighlightBegin: width / 2 - picker.thumbW / 2
                            preferredHighlightEnd: width / 2 + picker.thumbW / 2
                            highlightMoveDuration: picker.jumping ? 0 : root.animMs * 2
                            snapMode: ListView.SnapToItem
                            onWidthChanged: if (focusTimer.running) picker.focusCurrent()
                            onMovementStarted: picker.stopFocus()

                            delegate: Item {
                                id: wthumb
                                required property url fileUrl
                                required property string fileName
                                required property int index
                                readonly property bool centre: ListView.isCurrentItem
                                readonly property bool isSet: wthumb.fileUrl.toString() === (picker.live ? pins.adapter.liveWallpaper : pins.adapter.wallpaper)
                                width: picker.thumbW
                                height: strip.height
                                z: centre ? 2 : 1

                                Rectangle {
                                    id: frame
                                    anchors.centerIn: parent
                                    width: picker.thumbW
                                    height: picker.thumbH
                                    radius: 4
                                    color: root.overlay
                                    clip: true
                                    border.width: wthumb.isSet ? 3 : (wthumb.centre ? 2 : 1)
                                    border.color: wthumb.isSet ? root.accent : (wthumb.centre ? root.fg : root.glassEdge)
                                    scale: wthumb.centre ? (thumbMouse.containsMouse ? 1.40 : 1.36) : (thumbMouse.containsMouse ? 0.80 : 0.74)
                                    opacity: wthumb.centre ? 1 : 0.5
                                    Behavior on scale { NumberAnimation { duration: root.animMs * 2.4; easing.type: Easing.OutCubic } }
                                    Behavior on opacity { NumberAnimation { duration: root.animMs * 2.4 } }

                                    // lean the card (top pushed right), like a parallelogram
                                    transform: Matrix4x4 {
                                        matrix: Qt.matrix4x4(1, -picker.slant, 0, picker.slant * picker.thumbH / 2,
                                                             0, 1, 0, 0,
                                                             0, 0, 1, 0,
                                                             0, 0, 0, 1)
                                    }

                                    // the picture leans back the other way so it isn't stretched
                                    Image {
                                        width: parent.width + picker.slant * parent.height
                                        height: parent.height
                                        x: -picker.slant * parent.height / 2
                                        source: picker.live ? root.liveThumbFor(wthumb.fileName) : wthumb.fileUrl
                                        asynchronous: true
                                        fillMode: Image.PreserveAspectCrop
                                        sourceSize.width: 720
                                        transform: Matrix4x4 {
                                            matrix: Qt.matrix4x4(1, picker.slant, 0, -picker.slant * picker.thumbH / 2,
                                                                 0, 1, 0, 0,
                                                                 0, 0, 1, 0,
                                                                 0, 0, 0, 1)
                                        }
                                    }

                                    // soft shine along the top edge
                                    Rectangle {
                                        anchors.fill: parent
                                        gradient: Gradient {
                                            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.16) }
                                            GradientStop { position: 0.3; color: Qt.rgba(1, 1, 1, 0) }
                                        }
                                    }

                                    // the border drawn on top of the picture
                                    Rectangle {
                                        anchors.fill: parent
                                        color: "transparent"
                                        radius: parent.radius
                                        border.width: parent.border.width
                                        border.color: parent.border.color
                                    }

                                    // tick on the wallpaper that's set now
                                    Rectangle {
                                        visible: wthumb.isSet
                                        anchors.top: parent.top
                                        anchors.right: parent.right
                                        anchors.margins: 10
                                        width: 26
                                        height: 26
                                        radius: 13
                                        color: root.accent

                                        Text {
                                            anchors.centerIn: parent
                                            text: ""
                                            color: root.bg
                                            font.family: root.iconFont
                                            font.pixelSize: 12
                                        }
                                    }

                                    MouseArea {
                                        id: thumbMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            // first click brings it to the middle, clicking the middle one sets it
                                            picker.stopFocus();
                                            if (wthumb.centre) picker.applyCurrent();
                                            else strip.currentIndex = wthumb.index;
                                        }
                                    }
                                }
                            }
                        }

                        // Scroll wheel / touchpad moves one wallpaper per notch
                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.NoButton
                            onWheel: wheel => {
                                const d = wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : -wheel.angleDelta.x;
                                picker.wheelAcc += d;
                                while (picker.wheelAcc >= 120) { picker.step(-1); picker.wheelAcc -= 120; }
                                while (picker.wheelAcc <= -120) { picker.step(1); picker.wheelAcc += 120; }
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: picker.src.count === 0
                            horizontalAlignment: Text.AlignHCenter
                            text: picker.live
                                ? (!root.liveThumbsReady ? "Getting your live wallpapers ready…"
                                    : root.liveNoFfmpeg ? "Live wallpapers need ffmpeg:\nsudo pacman -S ffmpeg"
                                    : "No live wallpapers yet\nPut .mp4 / .webm / .mkv videos in ~/Videos/Wallpapers")
                                : "No wallpapers yet\nPut .jpg / .png / .webp files in ~/Pictures/Wallpapers"
                            color: root.muted
                            font.pixelSize: 14
                            lineHeight: 1.3
                        }
                    }

                    // ---- Name of the one in the middle ----
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.maximumWidth: wcardPick.width - 80
                        visible: picker.src.count > 0
                        elide: Text.ElideMiddle
                        text: strip.currentItem ? strip.currentItem.fileName : ""
                        color: root.fg
                        font.pixelSize: 14
                        font.bold: true
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: picker.live && root.liveUnavailable
                            ? "Live wallpapers need Qt's video support:  sudo pacman -S qt6-multimedia-ffmpeg   (then restart the bar)"
                            : "Scroll or ← →  browse      Click the middle one or Enter  set      R  random      Esc  close"
                        color: root.muted
                        font.pixelSize: 11
                        opacity: 0.8
                    }
                }
            }
        }
    }

    // ---------- Wallpaper (drawn on the background layer) ----------
    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.namespace: "quickshell-wallpaper"
            exclusionMode: ExclusionMode.Ignore
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            color: root.bg

            // Changing wallpaper: outlines of the new picture sketch themselves in, then it
            // spreads out like ink from the picture's subject (shaders/ink.frag).
            // Two images take turns being the one on screen, so nothing reloads or flickers.
            Item {
                id: wp
                anchors.fill: parent
                readonly property string target: pins.adapter.wallpaper
                property bool aFront: true
                property bool running: false
                property bool pending: false
                readonly property Image front: aFront ? imgA : imgB
                readonly property Image back: aFront ? imgB : imgA
                // where the ink starts: the busiest, most detailed part of the picture
                property point inkFrom: Qt.point(0.5, 0.45)
                property string focusSrc: ""

                onTargetChanged: {
                    if (running) {
                        inkAnim.stop();
                        finish();
                    }
                    if (target === "") {
                        imgA.source = "";
                        imgB.source = "";
                        pending = false;
                        return;
                    }
                    if (front.source == "") {
                        front.source = target;
                        return;
                    }
                    if (front.source == target) return;
                    pending = true;
                    focusWait.restart();
                    back.source = target;
                    tryBegin();
                }
                Component.onCompleted: if (target !== "") front.source = target

                function tryBegin() {
                    if (!pending || back.status !== Image.Ready) return;
                    if (focusSrc !== target && focusWait.running) return;   // give the focus finder a moment
                    pending = false;
                    if (root.animMs === 0) {
                        finish();
                        return;
                    }
                    ink.seed = Math.random() * 100;
                    ink.origin = focusSrc === target ? inkFrom : Qt.point(0.5, 0.45);
                    ink.progress = 0;
                    running = true;
                    inkAnim.restart();
                }

                function finish() {
                    running = false;
                    aFront = !aFront;
                    const old = back;
                    Qt.callLater(() => { if (!wp.running && !wp.pending) old.source = ""; });   // free the old picture
                }

                Timer {
                    id: focusWait
                    interval: 350
                    onTriggered: wp.tryBegin()
                }

                // Finds the most detailed area of a 48×48 copy of the picture (leaning toward
                // the middle), which is usually where the person or main thing is.
                function findFocus(px, w, h) {
                    const lum = new Array(w * h);
                    for (let i = 0; i < w * h; i++)
                        lum[i] = 0.299 * px[i * 4] + 0.587 * px[i * 4 + 1] + 0.114 * px[i * 4 + 2];
                    let sx = 0, sy = 0, sw = 0;
                    for (let y = 1; y < h - 1; y++)
                        for (let x = 1; x < w - 1; x++) {
                            const gx = lum[y * w + x + 1] - lum[y * w + x - 1];
                            const gy = lum[(y + 1) * w + x] - lum[(y - 1) * w + x];
                            const nx = x / w - 0.5, ny = y / h - 0.5;
                            const wgt = (gx * gx + gy * gy) * Math.max(0.15, 1 - 1.6 * Math.sqrt(nx * nx + ny * ny));
                            sx += wgt * x;
                            sy += wgt * y;
                            sw += wgt;
                        }
                    if (sw <= 0) return Qt.point(0.5, 0.45);
                    return Qt.point(Math.max(0.12, Math.min(0.88, sx / sw / w)), Math.max(0.12, Math.min(0.88, sy / sw / h)));
                }

                // Tiny hidden copy of the wallpaper used to pick the theme colors
                Canvas {
                    id: sampler
                    width: 48
                    height: 48
                    z: -1
                    renderTarget: Canvas.Image
                    readonly property string src: pins.adapter.wallpaper

                    onSrcChanged: {
                        if (src === "") {
                            root.seed = "#89b4fa";
                            root.wallIsLight = false;
                        } else {
                            loadImage(src);
                        }
                    }
                    Component.onCompleted: if (src !== "") loadImage(src)
                    onImageLoaded: requestPaint()
                    onPaint: {
                        if (src === "" || !isImageLoaded(src)) return;
                        const ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        ctx.drawImage(src, 0, 0, width, height);
                        const px = ctx.getImageData(0, 0, width, height).data;
                        root.applyPalette(px);
                        wp.inkFrom = wp.findFocus(px, width, height);
                        wp.focusSrc = src;
                        wp.tryBegin();
                    }
                }

                Image {
                    id: imgA
                    anchors.fill: parent
                    asynchronous: true
                    fillMode: Image.PreserveAspectCrop
                    visible: wp.aFront && !wp.running
                    onStatusChanged: if (status === Image.Ready && !wp.aFront) wp.tryBegin()
                }

                Image {
                    id: imgB
                    anchors.fill: parent
                    asynchronous: true
                    fillMode: Image.PreserveAspectCrop
                    visible: !wp.aFront && !wp.running
                    onStatusChanged: if (status === Image.Ready && wp.aFront) wp.tryBegin()
                }

                // The transition itself (only drawn while it plays)
                ShaderEffect {
                    id: ink
                    anchors.fill: parent
                    z: 1
                    visible: wp.running
                    property variant fromTex: ShaderEffectSource {
                        sourceItem: wp.front
                        live: wp.running
                    }
                    property variant toTex: ShaderEffectSource {
                        sourceItem: wp.back
                        live: wp.running
                        mipmap: true
                    }
                    property real progress: 0
                    property real aspect: width / Math.max(1, height)
                    property real seed: 0
                    property point origin: Qt.point(0.5, 0.45)
                    property size texel: Qt.size(1 / Math.max(1, width), 1 / Math.max(1, height))
                    fragmentShader: Qt.resolvedUrl("shaders/ink.frag.qsb")
                }

                NumberAnimation {
                    id: inkAnim
                    target: ink
                    property: "progress"
                    from: 0
                    to: 1
                    duration: 2400
                    onFinished: wp.finish()
                }

                // Live wallpaper (only loaded while one is chosen)
                Loader {
                    id: liveLoader
                    anchors.fill: parent
                    active: pins.adapter.liveWallpaper !== ""
                    source: Qt.resolvedUrl("LiveWallpaper.qml")
                    onLoaded: {
                        item.source = Qt.binding(() => pins.adapter.liveWallpaper);
                        item.paused = Qt.binding(() => root.livePaused || root.gameMode);
                    }
                    onStatusChanged: if (status === Loader.Error) root.liveUnavailable = true
                }

            }
        }
    }
}
