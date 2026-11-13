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
import Qt.labs.folderlistmodel

ShellRoot {
    id: root

    // ---------- Theme (colors are generated from the current wallpaper) ----------
    // 'seed' is the dominant vivid color found in the wallpaper.
    property color seed: "#89b4fa"
    property bool wallIsLight: false
    // "auto" = light theme on bright wallpapers, dark on dark ones. Change it from the control center.
    readonly property string themeMode: pins.adapter.themeMode
    readonly property bool dark: themeMode === "dark" || (themeMode !== "light" && !wallIsLight)

    readonly property real hue: seed.hslHue < 0 ? 0.6 : seed.hslHue
    readonly property real sat: Math.max(0.35, Math.min(0.85, seed.hslSaturation))

    property color bg: dark ? Qt.hsla(hue, sat * 0.35, 0.10, 1) : Qt.hsla(hue, sat * 0.30, 0.96, 1)
    property color surface: dark ? Qt.hsla(hue, sat * 0.30, 0.16, 0.55) : Qt.hsla(hue, sat * 0.25, 0.97, 0.60)
    property color overlay: dark ? Qt.hsla(hue, sat * 0.30, 0.30, 0.75) : Qt.hsla(hue, sat * 0.35, 0.82, 0.85)
    property color popupBg: dark ? Qt.hsla(hue, sat * 0.30, 0.12, 0.86) : Qt.hsla(hue, sat * 0.25, 0.96, 0.90)
    property color fg: dark ? Qt.hsla(hue, sat * 0.30, 0.93, 1) : Qt.hsla(hue, sat * 0.40, 0.14, 1)
    property color muted: dark ? Qt.hsla(hue, sat * 0.20, 0.72, 1) : Qt.hsla(hue, sat * 0.25, 0.38, 1)
    property color accent: dark ? Qt.hsla(hue, sat, 0.72, 1) : Qt.hsla(hue, sat, 0.38, 1)
    property color danger: dark ? "#f38ba8" : "#c0264a"
    property color glassEdge: dark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.10)

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
    readonly property int animMs: 150               // animation speed in ms (0 = no animations)
    readonly property bool hoverZoom: true          // pinned icons grow when hovered
    readonly property string iconFont: "JetBrainsMono Nerd Font"   // font the bar icons come from
    // Clock
    readonly property bool use24h: true
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
            property string themeMode: "auto"
            property string autoHide: "windows"
            property string desktopsJson: ""
            property string historyJson: ""     // which apps were opened, how often and when (launcher tabs)
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
        pins.adapter.wallpaper = url;
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
        wallIsLight = count > 0 && (lum / count) > 0.6;
        if (best >= 0 && bestW > 6) {
            seed = Qt.rgba(sr[best] / weight[best], sg[best] / weight[best], sb[best] / weight[best], 1);
        } else if (count > 0) {
            seed = Qt.rgba(ar / count, ag / count, ab / count, 1);    // greyscale wallpaper
        }
    }

    function cycleTheme() {
        const order = ["auto", "dark", "light"];
        pins.adapter.themeMode = order[(order.indexOf(pins.adapter.themeMode) + 1) % order.length];
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
                summary: n.summary,
                body: n.body,
                appName: n.appName,
                critical: n.urgency === NotificationUrgency.Critical
            });
            while (toastModel.count > 4) toastModel.remove(0);
        }
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
    // Every monitor gets its own list of desktops (Hyprland workspaces). The lists are saved,
    // so an empty desktop stays in the bar until you delete it.
    readonly property var deskMap: {
        try {
            return JSON.parse(pins.adapter.desktopsJson || "{}");
        } catch (e) {
            return {};
        }
    }

    // Runs each Lua dispatcher through hyprctl, one after the other
    function hyprList(exprs) {
        const parts = [];
        for (let i = 0; i < exprs.length; i++)
            parts.push("hyprctl dispatch '" + exprs[i] + "'");
        Quickshell.execDetached(["sh", "-c", parts.join("; ")]);
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
        if (fresh.length > 0) saveDesk(map);
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

    function gotoDesktop(monitorName, id) {
        hyprList([
            'hl.dsp.focus({ monitor = "' + monitorName + '" })',
            'hl.dsp.focus({ workspace = ' + id + ', on_current_monitor = true })'
        ]);
    }

    function addDesktop(monitorName) {
        const map = copyMap();
        const ids = map[monitorName] || [];
        if (ids.length >= maxDesktops) return;
        const id = freeId(map);
        ids.push(id);
        map[monitorName] = ids;
        saveDesk(map);
        gotoDesktop(monitorName, id);
    }

    // Deleting a desktop moves its windows to the neighbouring one, nothing gets closed
    function removeDesktop(monitorName, id) {
        const map = copyMap();
        const ids = map[monitorName] || [];
        const at = ids.indexOf(id);
        if (ids.length <= 1 || at < 0) return;
        const target = ids[at > 0 ? at - 1 : 1];
        const cmds = [];
        const ws = workspaceById(id);
        if (ws) {
            const tops = ws.toplevels.values;
            for (let i = 0; i < tops.length; i++) {
                let a = String(tops[i].address);
                if (a.indexOf("0x") !== 0) a = "0x" + a;
                cmds.push('hl.dsp.window.move({ workspace = ' + target + ', follow = false, window = "address:' + a + '" })');
            }
        }
        if (activeWsId(monitorName) === id) {
            cmds.push('hl.dsp.focus({ monitor = "' + monitorName + '" })');
            cmds.push('hl.dsp.focus({ workspace = ' + target + ', on_current_monitor = true })');
        }
        ids.splice(at, 1);
        map[monitorName] = ids;
        saveDesk(map);
        if (cmds.length > 0) hyprList(cmds);
    }

    function focusedMonitorName() {
        return Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "";
    }

    function switchToNth(n) {
        const name = focusedMonitorName();
        const ids = deskMap[name] || [];
        if (n >= 1 && n <= ids.length) gotoDesktop(name, ids[n - 1]);
    }

    function cycleDesktop(delta) {
        const name = focusedMonitorName();
        const ids = deskMap[name] || [];
        if (ids.length === 0) return;
        const at = ids.indexOf(activeWsId(name));
        const next = ids[(Math.max(at, 0) + delta + ids.length) % ids.length];
        gotoDesktop(name, next);
    }

    // From a terminal:  quickshell ipc call desktops switchTo 2   (also next, prev, add, remove, reset)
    IpcHandler {
        target: "desktops"
        function switchTo(n: int): void { root.switchToNth(n); }
        function next(): void { root.cycleDesktop(1); }
        function prev(): void { root.cycleDesktop(-1); }
        function add(): void {
            const name = root.focusedMonitorName();
            if (name !== "") root.addDesktop(name);
        }
        function remove(): void {
            const name = root.focusedMonitorName();
            if (name !== "") root.removeDesktop(name, root.activeWsId(name));
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
        const accentHex = col(h, s, d ? 0.72 : 0.38);
        const bgc = d ? col(h, s * 0.35, 0.09) : col(h, s * 0.30, 0.97);
        const fgc = d ? col(h, s * 0.25, 0.90) : col(h, s * 0.40, 0.15);
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
            "color7 " + col(h, s * 0.15, d ? 0.80 : 0.30),
            "color8 " + col(h, s * 0.25, d ? 0.28 : 0.70),
            "color15 " + col(h, s * 0.12, d ? 0.95 : 0.15)
        ];
        // Every colour leans 20% of the way toward the wallpaper's hue, so red stays reddish,
        // green stays greenish, but they all look like they belong to the wallpaper.
        // Blue (color4) is the wallpaper accent itself; fastfetch uses it for its labels.
        const lean = 0.2;
        const tint = base => base + ((((h - base) % 1) + 1.5) % 1 - 0.5) * lean;
        const sLo = Math.max(0.35, Math.min(0.75, s * 0.9));
        const sHi = Math.max(0.45, Math.min(0.85, s));
        for (let i = 0; i < 6; i++) {
            const hh = i === 3 ? h : tint(hues[i]);
            lines.push("color" + (i + 1) + " " + col(hh, sLo, lo));
            lines.push("color" + (i + 9) + " " + col(hh, sHi, hi));
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
    onDarkChanged: kittyTimer.restart()

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
            implicitHeight: root.dockIconSize + 34
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
            exclusionMode: ExclusionMode.Normal
            exclusiveZone: barShown ? implicitHeight : 0

            // While hidden, only a thin strip at the screen edge listens for the mouse;
            // everything else passes straight through to the windows underneath
            mask: barShown ? null : edgeMask
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
                implicitWidth: 340
                implicitHeight: content.implicitHeight + 24
                color: "transparent"
                visible: false

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
                    opacity: 0
                    scale: 0.96
                    NumberAnimation on opacity { running: mediaPopup.visible; from: 0; to: 1; duration: root.animMs; easing.type: Easing.OutCubic }
                    NumberAnimation on scale { running: mediaPopup.visible; from: 0.96; to: 1; duration: root.animMs; easing.type: Easing.OutCubic }
                    anchors.fill: parent
                    radius: 14
                    color: root.popupBg
                    border.color: root.overlay
                    border.width: 1

                    ColumnLayout {
                        id: content
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 10

                        // Cover art + title
                        RowLayout {
                            spacing: 12

                            Rectangle {
                                Layout.preferredWidth: 60
                                Layout.preferredHeight: 60
                                radius: 8
                                color: root.overlay
                                clip: true

                                Image {
                                    anchors.fill: parent
                                    source: mediaPopup.p ? mediaPopup.p.trackArtUrl : ""
                                    fillMode: Image.PreserveAspectCrop
                                    visible: status === Image.Ready
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: "♪"
                                    color: root.muted
                                    font.pixelSize: 24
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    Layout.fillWidth: true
                                    text: mediaPopup.p ? (mediaPopup.p.trackTitle || "Unknown title") : ""
                                    color: root.fg
                                    font.pixelSize: 14
                                    font.bold: true
                                    elide: Text.ElideRight
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: mediaPopup.p ? mediaPopup.p.trackArtist : ""
                                    color: root.muted
                                    font.pixelSize: 12
                                    elide: Text.ElideRight
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: mediaPopup.p ? mediaPopup.p.identity : ""
                                    color: root.muted
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        // Seek bar
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            ValueBar {
                                theme: root
                                Layout.fillWidth: true
                                value: mediaPopup.p && mediaPopup.p.length > 0
                                    ? mediaPopup.p.position / mediaPopup.p.length : 0
                                onMoved: v => {
                                    const p = mediaPopup.p;
                                    if (p && p.canSeek && p.length > 0) p.position = v * p.length;
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: root.fmt(mediaPopup.p ? mediaPopup.p.position : 0)
                                    color: root.muted
                                    font.pixelSize: 11
                                }
                                Item { Layout.fillWidth: true }
                                Text {
                                    text: root.fmt(mediaPopup.p ? mediaPopup.p.length : 0)
                                    color: root.muted
                                    font.pixelSize: 11
                                }
                            }
                        }

                        // Transport controls
                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 8

                            IconButton {
                                theme: root
                                label: "|◀"
                                dim: !(mediaPopup.p && mediaPopup.p.canGoPrevious)
                                onClicked: if (mediaPopup.p && mediaPopup.p.canGoPrevious) mediaPopup.p.previous()
                            }
                            IconButton {
                                theme: root
                                implicitWidth: 56
                                label: root.playing(mediaPopup.p) ? "❚❚" : "▶"
                                dim: !(mediaPopup.p && mediaPopup.p.canTogglePlaying)
                                onClicked: if (mediaPopup.p && mediaPopup.p.canTogglePlaying) mediaPopup.p.togglePlaying()
                            }
                            IconButton {
                                theme: root
                                label: "▶|"
                                dim: !(mediaPopup.p && mediaPopup.p.canGoNext)
                                onClicked: if (mediaPopup.p && mediaPopup.p.canGoNext) mediaPopup.p.next()
                            }
                        }

                        // Player's own volume (not every player supports this)
                        RowLayout {
                            Layout.fillWidth: true
                            visible: mediaPopup.p && mediaPopup.p.volumeSupported
                            spacing: 8

                            Text {
                                Layout.preferredWidth: 52
                                text: "Player"
                                color: root.muted
                                font.pixelSize: 12
                            }
                            ValueBar {
                                theme: root
                                Layout.fillWidth: true
                                value: mediaPopup.p ? mediaPopup.p.volume : 0
                                onMoved: v => {
                                    if (mediaPopup.p && mediaPopup.p.volumeSupported) mediaPopup.p.volume = v;
                                }
                            }
                            Item { Layout.preferredWidth: 60 }
                        }

                        // System volume (works for any app, including browser video)
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Text {
                                Layout.preferredWidth: 52
                                text: "System"
                                color: root.muted
                                font.pixelSize: 12
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
                                implicitWidth: 60
                                implicitHeight: 28
                                label: root.sink && root.sink.audio && root.sink.audio.muted ? "Unmute" : "Mute"
                                onClicked: {
                                    if (root.sink && root.sink.audio) root.sink.audio.muted = !root.sink.audio.muted;
                                }
                            }
                        }
                    }
                }
            }

            HyprlandFocusGrab {
                windows: [mediaPopup]
                active: mediaPopup.visible
                onCleared: {
                    root.closeAll();
                    mediaPopup.visible = false;
                    panel.mediaClosedAt = Date.now();
                }
            }

            // ===== The bar itself =====
            Item {
                id: barContent
                opacity: panel.barShown ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: root.animMs * 2; easing.type: Easing.OutCubic } }
                transform: Translate {
                    y: panel.barShown ? 0 : panel.implicitHeight
                    Behavior on y { NumberAnimation { duration: root.animMs * 2; easing.type: Easing.OutCubic } }
                }
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 12

                // ---- Left: search bar (opens the app launcher) ----
                Rectangle {
                    id: searchBar
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: 260
                    height: 44
                    radius: 22
                    color: searchMouse.containsMouse ? root.overlay : root.surface
                    border.width: 1
                    border.color: root.glassEdge
                    Behavior on color { ColorAnimation { duration: root.animMs } }

                    // little magnifying glass drawn from two shapes
                    Item {
                        anchors.left: parent.left
                        anchors.leftMargin: 17
                        anchors.verticalCenter: parent.verticalCenter
                        width: 16
                        height: 16

                        Rectangle {
                            width: 11
                            height: 11
                            radius: 5.5
                            color: "transparent"
                            border.width: 2
                            border.color: root.muted
                        }
                        Rectangle {
                            x: 9
                            y: 10
                            width: 7
                            height: 2
                            radius: 1
                            color: root.muted
                            rotation: 45
                            transformOrigin: Item.Left
                        }
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 44
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Search apps..."
                        color: root.muted
                        font.pixelSize: 14
                    }

                    MouseArea {
                        id: searchMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.launcherOpen = !root.launcherOpen
                    }
                }
                // ---- Center: the dock, big app icons ----
                Rectangle {
                    id: dock
                    anchors.centerIn: parent
                    implicitWidth: dockRow.implicitWidth + 20
                    implicitHeight: root.dockIconSize + 26
                    radius: 24
                    color: root.surface
                    border.width: 1
                    border.color: root.glassEdge
                    visible: dockRow.implicitWidth > 0

                    RowLayout {
                        id: dockRow
                        anchors.centerIn: parent
                        spacing: 6

                        // ---- Pinned apps ----
                        Row {
                            spacing: 4
                            Layout.alignment: Qt.AlignVCenter

                            Repeater {
                                model: pins.adapter.pinned

                                delegate: Item {
                                    id: pin
                                    required property string modelData

                                    // Reading .values makes this re-run once apps finish loading
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
                                    width: visible ? root.dockIconSize + 14 : 0
                                    height: root.dockIconSize + 14

                                    function focusNext() {
                                        let next = 0;
                                        for (let i = 0; i < wins.length; i++) {
                                            if (wins[i].activated) { next = (i + 1) % wins.length; break; }
                                        }
                                        wins[next].activate();
                                    }

                                    function menuEntries() {
                                        const out = [];
                                        out.push({ text: "Open new window", action: () => root.launchApp(pin.entry) });

                                        const acts = pin.entry.actions;
                                        for (let i = 0; i < acts.length && i < 4; i++) {
                                            const a = acts[i];
                                            out.push({ text: a.name, action: () => a.execute() });
                                        }

                                        if (pin.running) {
                                            out.push({
                                                text: pin.wins.length > 1 ? "Close all windows" : "Close window",
                                                danger: true,
                                                action: () => { for (const w of pin.wins) w.close(); }
                                            });
                                        }
                                        out.push({ text: "Unpin", action: () => root.unpin(pin.modelData) });
                                        return out;
                                    }

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 14
                                        color: pinMouse.containsMouse ? root.overlay
                                             : (pin.isActive ? root.surface : "transparent")
                                             Behavior on color { ColorAnimation { duration: root.animMs } }
                                    }

                                    IconImage {
                                        anchors.centerIn: parent
                                        implicitSize: root.dockIconSize
                                        scale: (root.hoverZoom && pinMouse.containsMouse) ? 1.18 : 1
                                        Behavior on scale { NumberAnimation { duration: root.animMs; easing.type: Easing.OutBack } }
                                        source: pin.entry
                                            ? Quickshell.iconPath(pin.entry.icon, "application-x-executable") : ""
                                    }

                                    // Dot under running apps (longer for the focused one)
                                    Rectangle {
                                        visible: pin.running
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        anchors.bottom: parent.bottom
                                        anchors.bottomMargin: 3
                                        width: pin.isActive ? 14 : 5
                                        height: 3
                                        radius: 2
                                        color: root.accent
                                    }

                                    MouseArea {
                                        id: pinMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                                        onClicked: mouse => {
                                            if (mouse.button === Qt.RightButton) {
                                                panel.openMenu(pin, pin.menuEntries());
                                            } else if (mouse.button === Qt.MiddleButton) {
                                                root.launchApp(pin.entry);
                                            } else if (pin.running) {
                                                pin.focusNext();
                                            } else {
                                                root.launchApp(pin.entry);
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // ---- Other open windows (not pinned), shown as icons ----
                        Row {
                            spacing: 4
                            Layout.alignment: Qt.AlignVCenter

                            Repeater {
                                model: ToplevelManager.toplevels

                                delegate: Item {
                                    id: win
                                    required property var modelData
                                    visible: root.bottomShowWindowList && !root.isPinned(modelData.appId)
                                    width: visible ? root.dockIconSize + 14 : 0
                                    height: root.dockIconSize + 14

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 14
                                        color: winMouse.containsMouse ? root.overlay
                                             : (win.modelData.activated ? root.surface : "transparent")
                                        Behavior on color { ColorAnimation { duration: root.animMs } }
                                    }

                                    IconImage {
                                        anchors.centerIn: parent
                                        implicitSize: root.dockIconSize
                                        scale: (root.hoverZoom && winMouse.containsMouse) ? 1.18 : 1
                                        Behavior on scale { NumberAnimation { duration: root.animMs; easing.type: Easing.OutBack } }
                                        source: Quickshell.iconPath(win.modelData.appId, "application-x-executable")
                                    }

                                    // Dot under the window (longer when it's the focused one)
                                    Rectangle {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        anchors.bottom: parent.bottom
                                        anchors.bottomMargin: 3
                                        width: win.modelData.activated ? 14 : 5
                                        height: 3
                                        radius: 2
                                        color: root.accent
                                    }

                                    MouseArea {
                                        id: winMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                                        onClicked: mouse => {
                                            if (mouse.button === Qt.RightButton) {
                                                const out = [];
                                                out.push({ text: "Close window", danger: true, action: () => win.modelData.close() });
                                                if (win.modelData.appId)
                                                    out.push({ text: "Pin to taskbar", action: () => root.pin(win.modelData.appId) });
                                                panel.openMenu(win, out);
                                            } else if (mouse.button === Qt.MiddleButton) {
                                                win.modelData.close();
                                            } else {
                                                win.modelData.activate();
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // ---- Right: desktops, tray, media, wallpaper, clock ----
                RowLayout {
                    id: rightGroup
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10

                    // ---- Desktops (this monitor's own set: click to switch, + to add, right-click to delete) ----
                    Row {
                        id: strip
                        readonly property string monitorName: panel.screen.name
                        spacing: 6
                        Layout.alignment: Qt.AlignVCenter

                        ListModel { id: deskModel }

                        // Keeps the animated list in step with the saved desktops
                        function sync() {
                            const want = root.deskMap[monitorName] || [];
                            for (let i = deskModel.count - 1; i >= 0; i--)
                                if (want.indexOf(deskModel.get(i).wid) < 0) deskModel.remove(i);
                            for (let i = 0; i < want.length; i++) {
                                if (i < deskModel.count && deskModel.get(i).wid === want[i]) continue;
                                let found = -1;
                                for (let j = i + 1; j < deskModel.count; j++)
                                    if (deskModel.get(j).wid === want[i]) found = j;
                                if (found >= 0) deskModel.move(found, i, 1);
                                else deskModel.insert(i, { wid: want[i] });
                            }
                        }

                        Connections {
                            target: root
                            function onDeskMapChanged() { strip.sync(); }
                        }
                        Component.onCompleted: sync()

                        ListView {
                            id: deskView
                            orientation: ListView.Horizontal
                            interactive: false
                            spacing: 6
                            width: contentWidth
                            height: 28
                            model: deskModel

                            // New desktops pop in, deleted ones shrink away, the rest slide over
                            add: Transition {
                                ParallelAnimation {
                                    NumberAnimation { property: "scale"; from: 0; to: 1; duration: root.animMs * 3; easing.type: Easing.OutBack }
                                    NumberAnimation { property: "opacity"; from: 0; to: 1; duration: root.animMs * 2 }
                                }
                            }
                            remove: Transition {
                                ParallelAnimation {
                                    NumberAnimation { property: "scale"; to: 0; duration: root.animMs * 2; easing.type: Easing.InBack }
                                    NumberAnimation { property: "opacity"; to: 0; duration: root.animMs * 2 }
                                }
                            }
                            displaced: Transition {
                                NumberAnimation { properties: "x"; duration: root.animMs * 2; easing.type: Easing.OutCubic }
                            }

                            delegate: Item {
                                id: dk
                                required property int wid
                                required property int index
                                readonly property bool isActive: root.activeWsId(strip.monitorName) === dk.wid
                                readonly property int windows: root.wsWindowCount(dk.wid)
                                width: pill.width
                                height: 28

                                Rectangle {
                                    id: pill
                                    width: dk.isActive ? 52 : 28
                                    height: 28
                                    radius: 14
                                    color: dk.isActive ? root.accent : (dkMouse.containsMouse ? root.overlay : root.surface)
                                    border.width: 1
                                    border.color: root.glassEdge
                                    Behavior on width { NumberAnimation { duration: root.animMs * 2; easing.type: Easing.OutBack } }
                                    Behavior on color { ColorAnimation { duration: root.animMs } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: dk.index + 1
                                        color: dk.isActive ? root.bg : root.fg
                                        font.pixelSize: 13
                                        font.bold: dk.isActive
                                    }

                                    // Small dot when a desktop has windows on it
                                    Rectangle {
                                        visible: dk.windows > 0 && !dk.isActive
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        anchors.bottom: parent.bottom
                                        anchors.bottomMargin: 3
                                        width: 4
                                        height: 4
                                        radius: 2
                                        color: root.accent
                                    }
                                }

                                MouseArea {
                                    id: dkMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    onClicked: mouse => {
                                        if (mouse.button === Qt.RightButton) {
                                            const out = [];
                                            out.push({ text: "Go to desktop " + (dk.index + 1), action: () => root.gotoDesktop(strip.monitorName, dk.wid) });
                                            if (deskModel.count > 1)
                                                out.push({ text: "Delete this desktop", danger: true, action: () => root.removeDesktop(strip.monitorName, dk.wid) });
                                            panel.openMenu(dk, out);
                                        } else {
                                            root.gotoDesktop(strip.monitorName, dk.wid);
                                        }
                                    }
                                }
                            }
                        }

                        // Add button: the plus spins when you hover it
                        Rectangle {
                            id: addBtn
                            visible: deskModel.count < root.maxDesktops
                            width: 28
                            height: 28
                            radius: 14
                            color: addMouse.containsMouse ? root.overlay : root.surface
                            border.width: 1
                            border.color: root.glassEdge
                            rotation: addMouse.containsMouse ? 90 : 0
                            scale: addMouse.pressed ? 0.85 : 1
                            Behavior on color { ColorAnimation { duration: root.animMs } }
                            Behavior on rotation { NumberAnimation { duration: root.animMs * 2; easing.type: Easing.OutBack } }
                            Behavior on scale { NumberAnimation { duration: root.animMs; easing.type: Easing.OutCubic } }

                            Text {
                                anchors.centerIn: parent
                                text: "+"
                                color: root.fg
                                font.pixelSize: 17
                            }

                            MouseArea {
                                id: addMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: root.addDesktop(strip.monitorName)
                            }
                        }
                    }
                    // ---- System tray ----
                    Row {
                        visible: root.bottomShowTray
                        spacing: 8
                        Layout.alignment: Qt.AlignVCenter

                        Repeater {
                            model: SystemTray.items

                            delegate: Item {
                                id: trayItem
                                required property var modelData
                                width: 22
                                height: 22

                                IconImage {
                                    anchors.fill: parent
                                    source: trayItem.modelData.icon
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                                    onClicked: mouse => {
                                        const p = trayItem.mapToItem(null, 0, 0);
                                        if (mouse.button === Qt.LeftButton && !trayItem.modelData.onlyMenu) {
                                            trayItem.modelData.activate();
                                        } else if (mouse.button === Qt.MiddleButton) {
                                            trayItem.modelData.secondaryActivate();
                                        } else if (trayItem.modelData.hasMenu) {
                                            trayItem.modelData.display(panel, p.x, p.y);
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ---- Media button (only shows when something is playing/paused) ----
                    Rectangle {
                        id: mediaBtn
                        visible: root.bottomShowMedia && root.player !== null
                        Layout.alignment: Qt.AlignVCenter
                        implicitWidth: Math.min(260, mediaLabel.implicitWidth + 24)
                        implicitHeight: 30
                        radius: 8
                        color: mediaPopup.visible ? root.overlay : root.surface
                        Behavior on color { ColorAnimation { duration: root.animMs } }
                        border.width: 1
                        border.color: root.glassEdge

                        Text {
                            id: mediaLabel
                            anchors.centerIn: parent
                            width: Math.min(implicitWidth, 236)
                            elide: Text.ElideRight
                            color: root.fg
                            font.pixelSize: 12
                            text: root.player
                                ? (root.playing(root.player) ? "▶  " : "❚❚  ")
                                  + (root.player.trackTitle || root.player.identity)
                                  + (root.player.trackArtist ? " – " + root.player.trackArtist : "")
                                : ""
                        }

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                            onClicked: mouse => {
                                if (mouse.button === Qt.MiddleButton) {
                                    if (root.player && root.player.canTogglePlaying) root.player.togglePlaying();
                                    return;
                                }
                                // Clicking the button also dismisses the popup; don't instantly reopen it
                                if (Date.now() - panel.mediaClosedAt < 250) return;
                                if (mediaPopup.visible) {
                                    mediaPopup.visible = false;
                                    return;
                                }
                                const p = mediaBtn.mapToItem(null, 0, 0);
                                mediaPopup.anchor.rect = Qt.rect(p.x, p.y, mediaBtn.width, mediaBtn.height);
                                mediaPopup.visible = true;
                            }
                        }
                    }

                    // ---- Wallpaper button (middle click = random) ----
                    Rectangle {
                        id: wallBtn
                        visible: root.bottomShowWallpaperButton
                        Layout.alignment: Qt.AlignVCenter
                        implicitWidth: 36
                        implicitHeight: 32
                        radius: 10
                        color: (root.wallPickerOpen || wallMouse.containsMouse) ? root.overlay : root.surface
                        scale: wallMouse.pressed ? 0.92 : (wallMouse.containsMouse ? 1.08 : 1)
                        Behavior on color { ColorAnimation { duration: root.animMs } }
                        Behavior on scale { NumberAnimation { duration: root.animMs; easing.type: Easing.OutBack } }
                        border.width: 1
                        border.color: root.glassEdge

                        Text {
                            anchors.centerIn: parent
                            text: "\uf03e"
                            color: root.accent
                            font.family: root.iconFont
                            font.pixelSize: 15
                        }

                        MouseArea {
                            id: wallMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                            onClicked: mouse => {
                                if (mouse.button === Qt.MiddleButton) {
                                    root.randomWallpaper();
                                    return;
                                }
                                root.wallPickerOpen = !root.wallPickerOpen;
                            }
                        }
                    }

                    // ---- Clock ----
                    Text {
                        Layout.alignment: Qt.AlignVCenter
                        visible: root.bottomShowClock
                        text: Qt.formatDateTime(clock.date, "ddd MMM d  " + root.timePattern)
                        color: root.fg
                        font.pixelSize: 13
                    }
                }
            }
        }
    }

    // ---------- Top bar: the island ----------
    // A compact pill at the top centre. Click it and it grows into the hub:
    // Home, Media, Apps, Calendar, Alerts and System.
    property bool hubOpen: false
    property int hubTab: 0           // 0 home, 1 media, 2 apps, 3 calendar, 4 alerts, 5 system, 6 capture
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

    // Small glossy card used all over the hub
    component HubCard: Rectangle {
        id: hc
        property var theme: null
        radius: 20
        color: hc.theme ? hc.theme.surface : "#313244"
        border.width: 1
        border.color: hc.theme ? hc.theme.glassEdge : "transparent"

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, hc.theme && hc.theme.dark ? 0.06 : 0.25) }
                GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0) }
            }
        }
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
            implicitHeight: 52
            color: "transparent"
            WlrLayershell.namespace: "quickshell-topbar"

            readonly property bool focusedHere: !Hyprland.focusedMonitor || Hyprland.focusedMonitor.name === modelData.name
            readonly property bool hubHere: root.hubOpen && focusedHere
            onHubHereChanged: if (hubHere) hubKeys.forceActiveFocus()

            // ----- Auto-hide -----
            // Touch the top edge and the pill slides down; windows shrink to make room.
            // Move away and it slides back up; windows stretch back to full size.
            readonly property bool wantHide: root.autoHideOn
            readonly property bool popupOpen: hubHere
            readonly property bool keepOpen: !wantHide || barHover.hovered || popupOpen
                || root.topBarOpen     // Super+T (if bound) pins it open
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

            // Windows only make room while the pill is out
            exclusionMode: ExclusionMode.Normal
            exclusiveZone: barShown ? implicitHeight : 0

            // While hidden, only a thin strip at the top edge listens for the mouse
            mask: barShown ? null : edgeMask
            Region { id: edgeMask; item: hotStrip }

            Item {
                id: hotStrip
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: root.hotZoneSize
            }

            Item {
                anchors.fill: parent
                z: 1000
                HoverHandler { id: barHover }
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
                width: pillRow.implicitWidth + 36
                height: 42
                radius: 21
                color: root.bg
                border.width: 1
                border.color: root.glassEdge
                opacity: panel.hubHere ? 0 : 1
                scale: pillMouse.pressed ? 0.97 : (pillHover.hovered ? 1.03 : 1)
                Behavior on y { NumberAnimation { duration: root.animMs * 2; easing.type: Easing.OutCubic } }
                Behavior on width { NumberAnimation { duration: root.animMs * 2; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: root.animMs } }
                Behavior on scale { NumberAnimation { duration: root.animMs; easing.type: Easing.OutBack } }

                HoverHandler { id: pillHover }

                // gloss
                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, root.dark ? 0.10 : 0.35) }
                        GradientStop { position: 0.55; color: Qt.rgba(1, 1, 1, 0) }
                    }
                }

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
                    spacing: 16

                    // ---- Desktop dots ----
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 5

                        Repeater {
                            model: panel.desks

                            delegate: Item {
                                id: dDot
                                required property var modelData
                                readonly property bool isActive: root.activeWsId(panel.modelData.name) === dDot.modelData
                                width: dot.width
                                height: 14

                                Rectangle {
                                    id: dot
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: dDot.isActive ? 20 : 8
                                    height: 8
                                    radius: 4
                                    color: dDot.isActive ? root.accent
                                        : (root.wsWindowCount(dDot.modelData) > 0 ? root.muted : root.overlay)
                                    Behavior on width { NumberAnimation { duration: root.animMs * 2; easing.type: Easing.OutBack } }
                                    Behavior on color { ColorAnimation { duration: root.animMs } }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -4
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.gotoDesktop(panel.modelData.name, dDot.modelData)
                                }
                            }
                        }
                    }

                    // ---- Focused app ----
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 7

                        IconImage {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: !!panel.activeWin
                            implicitSize: 18
                            source: panel.activeWin ? Quickshell.iconPath(panel.activeWin.appId, "application-x-executable") : ""
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.min(implicitWidth, 220)
                            elide: Text.ElideRight
                            text: panel.activeWin ? (panel.activeWin.title || panel.activeWin.appId) : "Desktop"
                            color: root.fg
                            font.pixelSize: 13
                        }
                    }

                    Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 4; height: 4; radius: 2; color: root.muted }

                    // ---- Clock (opens the calendar) ----
                    Item {
                        anchors.verticalCenter: parent.verticalCenter
                        width: clockRow.implicitWidth
                        height: 30

                        Row {
                            id: clockRow
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 7

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: Qt.formatDateTime(clock.date, root.timePattern)
                                color: root.fg
                                font.pixelSize: 15
                                font.bold: true
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: Qt.formatDateTime(clock.date, "ddd d")
                                color: root.muted
                                font.pixelSize: 13
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.openHub(3)
                        }
                    }

                    Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 4; height: 4; radius: 2; color: root.muted }

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
                                    font.pixelSize: 12
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: Math.round(chip.modelData.value * 100) + "%"
                                    color: root.fg
                                    font.pixelSize: 12
                                }
                            }
                        }
                    }

                    // ---- Status icons ----
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 12

                        // recording: red dot + time, click to stop
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

                        // music note while something plays (opens Media)
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: root.playing(root.player)
                            text: ""
                            color: root.accent
                            font.family: root.iconFont
                            font.pixelSize: 13
                            SequentialAnimation on opacity {
                                running: root.playing(root.player)
                                loops: Animation.Infinite
                                NumberAnimation { to: 0.45; duration: 700; easing.type: Easing.InOutSine }
                                NumberAnimation { to: 1; duration: 700; easing.type: Easing.InOutSine }
                            }
                            MouseArea { anchors.fill: parent; anchors.margins: -5; cursorShape: Qt.PointingHandCursor; onClicked: root.openHub(1) }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.netIcon()
                            color: root.netKind === "" ? root.muted : root.fg
                            font.family: root.iconFont
                            font.pixelSize: 13
                        }

                        // volume: scroll to change, click to mute
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.volIcon(root.sink ? root.sink.audio : null)
                            color: root.fg
                            font.family: root.iconFont
                            font.pixelSize: 14
                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -5
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (root.sink && root.sink.audio) root.sink.audio.muted = !root.sink.audio.muted
                                onWheel: wheel => {
                                    const a = root.sink ? root.sink.audio : null;
                                    if (!a) return;
                                    const step = wheel.angleDelta.y > 0 ? root.volumeStep : -root.volumeStep;
                                    a.volume = Math.max(0, Math.min(1, a.volume + step));
                                }
                            }
                        }

                        // microphone: click to mute, scroll to change
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: !!root.source
                            text: root.source && root.source.audio && !root.source.audio.muted ? "\uf130" : "\uf131"
                            color: root.source && root.source.audio && root.source.audio.muted ? root.danger : root.fg
                            font.family: root.iconFont
                            font.pixelSize: 14
                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -5
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (root.source && root.source.audio) root.source.audio.muted = !root.source.audio.muted
                                onWheel: wheel => {
                                    const a = root.source ? root.source.audio : null;
                                    if (!a) return;
                                    const step = wheel.angleDelta.y > 0 ? root.volumeStep : -root.volumeStep;
                                    a.volume = Math.max(0, Math.min(1, a.volume + step));
                                }
                            }
                        }

                        // bell with a count (opens Alerts)
                        Item {
                            anchors.verticalCenter: parent.verticalCenter
                            width: bell.implicitWidth + (badge.visible ? 8 : 0)
                            height: 18

                            Text {
                                id: bell
                                anchors.verticalCenter: parent.verticalCenter
                                text: ""
                                color: root.dnd ? root.muted : root.fg
                                font.family: root.iconFont
                                font.pixelSize: 13
                            }
                            Rectangle {
                                id: badge
                                visible: notifServer.trackedNotifications.values.length > 0
                                anchors.left: bell.right
                                anchors.leftMargin: -4
                                anchors.top: parent.top
                                anchors.topMargin: -3
                                width: Math.max(14, badgeText.implicitWidth + 6)
                                height: 14
                                radius: 7
                                color: root.accent

                                Text {
                                    id: badgeText
                                    anchors.centerIn: parent
                                    text: notifServer.trackedNotifications.values.length
                                    color: root.bg
                                    font.pixelSize: 9
                                    font.bold: true
                                }
                            }
                            MouseArea { anchors.fill: parent; anchors.margins: -5; cursorShape: Qt.PointingHandCursor; onClicked: root.openHub(4) }
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
                        else if (event.key === Qt.Key_Tab) root.hubTab = (root.hubTab + 1) % 7;
                        else if (event.key === Qt.Key_Backtab) root.hubTab = (root.hubTab + 6) % 7;
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

                    // gloss, accent glow and a bright top edge
                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, root.dark ? 0.10 : 0.40) }
                            GradientStop { position: 0.25; color: Qt.rgba(1, 1, 1, root.dark ? 0.03 : 0.10) }
                            GradientStop { position: 0.55; color: Qt.rgba(1, 1, 1, 0) }
                        }
                    }
                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        gradient: Gradient {
                            GradientStop { position: 0.6; color: "transparent" }
                            GradientStop { position: 1.0; color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, root.dark ? 0.12 : 0.08) }
                        }
                    }
                    Rectangle {
                        anchors.top: parent.top
                        anchors.topMargin: 1
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: parent.width - 60
                        height: 1
                        color: Qt.rgba(1, 1, 1, root.dark ? 0.22 : 0.7)
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
                            Rectangle { anchors.fill: parent; radius: 30; color: "#55000000" }
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
                                                { name: "Capture", icon: "" }
                                            ]

                                            delegate: Rectangle {
                                                id: htab
                                                required property var modelData
                                                required property int index
                                                readonly property bool current: root.hubTab === htab.index
                                                width: htabRow.implicitWidth + 20
                                                height: 34
                                                radius: 11
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
                                                    Text {
                                                        anchors.verticalCenter: parent.verticalCenter
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
                                    spacing: 12

                                    // Quick toggles
                                    GridLayout {
                                        Layout.fillWidth: true
                                        columns: 4
                                        rowSpacing: 10
                                        columnSpacing: 10

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
                                                    icon: "", title: "Theme",
                                                    sub: root.themeMode === "auto" ? "Auto" : (root.themeMode === "dark" ? "Dark" : "Light"),
                                                    active: false, ok: true,
                                                    run: () => root.cycleTheme()
                                                },
                                                {
                                                    icon: "", title: "Auto-hide bars",
                                                    sub: root.autoHideOn ? "On" : "Off",
                                                    active: root.autoHideOn, ok: true,
                                                    run: () => root.cycleAutoHide()
                                                },
                                                {
                                                    icon: "", title: "Wallpaper", sub: "Choose one",
                                                    active: false, ok: true,
                                                    run: () => { root.hubOpen = false; root.wallPickerOpen = true; }
                                                }
                                            ]

                                            delegate: Rectangle {
                                                id: tgl
                                                required property var modelData
                                                Layout.fillWidth: true
                                                Layout.preferredHeight: 70
                                                radius: 20
                                                color: tgl.modelData.active ? root.accent : (tglMouse.containsMouse ? root.overlay : root.surface)
                                                border.width: 1
                                                border.color: root.glassEdge
                                                opacity: tgl.modelData.ok ? 1 : 0.45
                                                scale: tglMouse.pressed ? 0.95 : (tglMouse.containsMouse && tgl.modelData.ok ? 1.03 : 1)
                                                Behavior on color { ColorAnimation { duration: root.animMs } }
                                                Behavior on scale { NumberAnimation { duration: root.animMs; easing.type: Easing.OutBack } }

                                                RowLayout {
                                                    anchors.fill: parent
                                                    anchors.margins: 12
                                                    spacing: 10

                                                    Rectangle {
                                                        Layout.preferredWidth: 38
                                                        Layout.preferredHeight: 38
                                                        radius: 19
                                                        color: tgl.modelData.active ? Qt.rgba(1, 1, 1, 0.25) : root.overlay

                                                        Text {
                                                            anchors.centerIn: parent
                                                            text: tgl.modelData.icon
                                                            color: tgl.modelData.active ? root.bg : root.accent
                                                            font.family: root.iconFont
                                                            font.pixelSize: 15
                                                        }
                                                    }

                                                    ColumnLayout {
                                                        Layout.fillWidth: true
                                                        spacing: 1
                                                        Text {
                                                            Layout.fillWidth: true
                                                            text: tgl.modelData.title
                                                            color: tgl.modelData.active ? root.bg : root.fg
                                                            font.pixelSize: 13
                                                            font.bold: true
                                                            elide: Text.ElideRight
                                                        }
                                                        Text {
                                                            Layout.fillWidth: true
                                                            text: tgl.modelData.sub
                                                            color: tgl.modelData.active ? root.bg : root.muted
                                                            font.pixelSize: 11
                                                            elide: Text.ElideRight
                                                        }
                                                    }
                                                }

                                                MouseArea {
                                                    id: tglMouse
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: tgl.modelData.ok ? Qt.PointingHandCursor : Qt.ArrowCursor
                                                    onClicked: if (tgl.modelData.ok) tgl.modelData.run()
                                                }
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

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 24
                                        spacing: 26
                                        visible: root.player !== null

                                        Rectangle {
                                            Layout.preferredWidth: 260
                                            Layout.preferredHeight: 260
                                            radius: 24
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
                                                font.pixelSize: 60
                                            }
                                            Rectangle {
                                                anchors.fill: parent
                                                radius: parent.radius
                                                gradient: Gradient {
                                                    GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.18) }
                                                    GradientStop { position: 0.4; color: Qt.rgba(1, 1, 1, 0) }
                                                }
                                            }
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 6

                                            Text {
                                                Layout.fillWidth: true
                                                text: root.player ? (root.player.trackTitle || "Unknown title") : ""
                                                color: root.fg
                                                font.pixelSize: 22
                                                font.bold: true
                                                wrapMode: Text.Wrap
                                                maximumLineCount: 2
                                                elide: Text.ElideRight
                                            }
                                            Text {
                                                Layout.fillWidth: true
                                                text: root.player ? root.player.trackArtist : ""
                                                color: root.muted
                                                font.pixelSize: 15
                                                elide: Text.ElideRight
                                            }
                                            Text {
                                                Layout.fillWidth: true
                                                text: root.player ? root.player.identity : ""
                                                color: root.accent
                                                font.pixelSize: 12
                                            }

                                            Item { Layout.preferredHeight: 18 }

                                            // seek bar (position only updates when asked, so poll while visible)
                                            Timer {
                                                interval: 1000
                                                repeat: true
                                                running: panel.hubHere && root.hubTab === 1 && root.playing(root.player)
                                                onTriggered: root.player.positionChanged()
                                            }
                                            ValueBar {
                                                theme: root
                                                Layout.fillWidth: true
                                                value: root.player && root.player.length > 0 ? root.player.position / root.player.length : 0
                                                onMoved: v => {
                                                    const p = root.player;
                                                    if (p && p.canSeek && p.length > 0) p.position = v * p.length;
                                                }
                                            }
                                            RowLayout {
                                                Layout.fillWidth: true
                                                Text {
                                                    text: root.fmt(root.player ? root.player.position : 0)
                                                    color: root.muted
                                                    font.pixelSize: 11
                                                }
                                                Item { Layout.fillWidth: true }
                                                Text {
                                                    text: root.fmt(root.player ? root.player.length : 0)
                                                    color: root.muted
                                                    font.pixelSize: 11
                                                }
                                            }

                                            RowLayout {
                                                Layout.alignment: Qt.AlignHCenter
                                                spacing: 12
                                                IconButton {
                                                    theme: root
                                                    implicitWidth: 60
                                                    implicitHeight: 46
                                                    label: "|◀"
                                                    dim: !(root.player && root.player.canGoPrevious)
                                                    onClicked: if (root.player && root.player.canGoPrevious) root.player.previous()
                                                }
                                                IconButton {
                                                    theme: root
                                                    implicitWidth: 76
                                                    implicitHeight: 46
                                                    label: root.playing(root.player) ? "❚❚" : "▶"
                                                    dim: !(root.player && root.player.canTogglePlaying)
                                                    onClicked: if (root.player && root.player.canTogglePlaying) root.player.togglePlaying()
                                                }
                                                IconButton {
                                                    theme: root
                                                    implicitWidth: 60
                                                    implicitHeight: 46
                                                    label: "▶|"
                                                    dim: !(root.player && root.player.canGoNext)
                                                    onClicked: if (root.player && root.player.canGoNext) root.player.next()
                                                }
                                            }

                                            RowLayout {
                                                Layout.fillWidth: true
                                                visible: root.player && root.player.volumeSupported
                                                spacing: 10
                                                Text {
                                                    text: "Player"
                                                    color: root.muted
                                                    font.pixelSize: 12
                                                }
                                                ValueBar {
                                                    theme: root
                                                    Layout.fillWidth: true
                                                    value: root.player ? root.player.volume : 0
                                                    onMoved: v => {
                                                        if (root.player && root.player.volumeSupported) root.player.volume = v;
                                                    }
                                                }
                                            }
                                            Item { Layout.fillHeight: true }
                                        }
                                    }

                                    Column {
                                        anchors.centerIn: parent
                                        visible: root.player === null
                                        spacing: 8
                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: ""
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
                                            onConfirmed: Quickshell.execDetached(["hyprctl", "dispatch", "exit"])
                                        }
                                        ConfirmButton {
                                            theme: root
                                            Layout.fillWidth: true
                                            label: "Reboot"
                                            onConfirmed: Quickshell.execDetached(["systemctl", "reboot"])
                                        }
                                        ConfirmButton {
                                            theme: root
                                            Layout.fillWidth: true
                                            label: "Shut down"
                                            onConfirmed: Quickshell.execDetached(["systemctl", "poweroff"])
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

            // Only show on the monitor that has focus
            visible: root.launcherOpen
                && (!Hyprland.focusedMonitor || Hyprland.focusedMonitor.name === modelData.name)

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell-launcher"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            exclusionMode: ExclusionMode.Ignore
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            color: "#55000000"

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

            Rectangle {
                id: card
                opacity: 0
                scale: 0.94
                NumberAnimation on opacity { running: launcher.visible; from: 0; to: 1; duration: root.animMs * 1.5; easing.type: Easing.OutCubic }
                NumberAnimation on scale { running: launcher.visible; from: 0.94; to: 1; duration: root.animMs * 2; easing.type: Easing.OutBack }

                width: 760
                height: 560
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -30
                radius: 26
                color: root.popupBg
                border.color: root.glassEdge
                border.width: 1
                clip: true

                // Glossy sheen: light catching the top of the glass
                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, root.dark ? 0.10 : 0.40) }
                        GradientStop { position: 0.28; color: Qt.rgba(1, 1, 1, root.dark ? 0.03 : 0.10) }
                        GradientStop { position: 0.6; color: Qt.rgba(1, 1, 1, 0) }
                    }
                }
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
                Rectangle {
                    anchors.top: parent.top
                    anchors.topMargin: 1
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - 60
                    height: 1
                    color: Qt.rgba(1, 1, 1, root.dark ? 0.22 : 0.7)
                }

                // Swallow clicks inside the card
                MouseArea { anchors.fill: parent }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 14

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

                        TextInput {
                            id: searchInput
                            anchors.left: searchIcon.right
                            anchors.leftMargin: 14
                            anchors.right: parent.right
                            anchors.rightMargin: 18
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

                    // ---- Hints ----
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Enter  open      ↑ ↓ Tab  move      Right-click  pin / unpin      Ctrl+Tab  switch tab      Esc  close"
                        color: root.muted
                        font.pixelSize: 11
                        opacity: 0.8
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

                Behavior on x { NumberAnimation { duration: root.animMs * 2; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: root.animMs * 2; easing.type: Easing.OutCubic } }

                readonly property var tiles: [
                    {
                        title: "Theme",
                        sub: root.themeMode === "auto" ? "Auto (" + (root.dark ? "dark" : "light") + ")"
                            : (root.themeMode === "dark" ? "Dark" : "Light"),
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
                                color: root.surface
                                border.width: nCard.modelData.urgency === NotificationUrgency.Critical ? 1 : 0
                                border.color: root.danger

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

                delegate: Rectangle {
                    id: toast
                    required property int tid
                    required property string summary
                    required property string body
                    required property string appName
                    required property bool critical
                    width: toastCol.width
                    height: toastText.implicitHeight + 24
                    radius: 14
                    color: root.popupBg
                    border.width: 1
                    border.color: toast.critical ? root.danger : root.glassEdge
                    opacity: 0

                    NumberAnimation on opacity { running: true; from: 0; to: 1; duration: root.animMs * 2 }
                    Timer {
                        interval: 6000
                        running: true
                        onTriggered: root.removeToast(toast.tid)
                    }

                    ColumnLayout {
                        id: toastText
                        anchors.fill: parent
                        anchors.margins: 12
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
                            font.pixelSize: 13
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

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.removeToast(toast.tid)
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
    // ---------- Wallpaper picker (scroll through, click or Enter to set) ----------
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: picker
            required property var modelData
            screen: modelData

            visible: root.wallPickerOpen
                && (!Hyprland.focusedMonitor || Hyprland.focusedMonitor.name === modelData.name)

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
            color: "#66000000"

            readonly property int thumbW: 340
            readonly property int thumbH: 200
            property real wheelAcc: 0

            // Index of the wallpaper that's set right now (-1 if none)
            function currentWallIndex() {
                for (let i = 0; i < wallpapers.count; i++)
                    if (wallpapers.get(i, "fileUrl").toString() === pins.adapter.wallpaper) return i;
                return -1;
            }

            function step(n) {
                if (wallpapers.count === 0) return;
                strip.currentIndex = Math.max(0, Math.min(wallpapers.count - 1, strip.currentIndex + n));
            }

            function applyCurrent() {
                if (strip.currentIndex < 0 || strip.currentIndex >= wallpapers.count) return;
                root.setWallpaper(wallpapers.get(strip.currentIndex, "fileUrl").toString());
            }

            onVisibleChanged: {
                if (visible) {
                    const i = currentWallIndex();
                    strip.currentIndex = i >= 0 ? i : 0;
                    strip.positionViewAtIndex(strip.currentIndex, ListView.Center);
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
                    else if (event.key === Qt.Key_R) root.randomWallpaper();
                    else return;
                    event.accepted = true;
                }
            }

            Rectangle {
                id: wcardPick
                opacity: 0
                scale: 0.94
                NumberAnimation on opacity { running: picker.visible; from: 0; to: 1; duration: root.animMs * 1.5; easing.type: Easing.OutCubic }
                NumberAnimation on scale { running: picker.visible; from: 0.94; to: 1; duration: root.animMs * 2; easing.type: Easing.OutBack }

                width: Math.min(picker.width - 80, 1240)
                height: 470
                anchors.centerIn: parent
                radius: 28
                color: root.popupBg
                border.color: root.glassEdge
                border.width: 1
                clip: true

                // Glossy sheen, same as the launcher
                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, root.dark ? 0.10 : 0.40) }
                        GradientStop { position: 0.28; color: Qt.rgba(1, 1, 1, root.dark ? 0.03 : 0.10) }
                        GradientStop { position: 0.6; color: Qt.rgba(1, 1, 1, 0) }
                    }
                }
                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    gradient: Gradient {
                        GradientStop { position: 0.55; color: "transparent" }
                        GradientStop { position: 1.0; color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, root.dark ? 0.12 : 0.08) }
                    }
                }
                Rectangle {
                    anchors.top: parent.top
                    anchors.topMargin: 1
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - 60
                    height: 1
                    color: Qt.rgba(1, 1, 1, root.dark ? 0.22 : 0.7)
                }

                // Swallow clicks inside the card
                MouseArea { anchors.fill: parent }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 22
                    spacing: 10

                    // ---- Header ----
                    RowLayout {
                        Layout.fillWidth: true
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
                        Text {
                            visible: wallpapers.count > 0
                            text: (strip.currentIndex + 1) + " / " + wallpapers.count
                            color: root.muted
                            font.pixelSize: 13
                        }
                        Item { Layout.fillWidth: true }
                        BarButton {
                            theme: root
                            icon: ""
                            label: "Random"
                            onClicked: mouse => {
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

                    // ---- The carousel ----
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        ListView {
                            id: strip
                            anchors.fill: parent
                            orientation: ListView.Horizontal
                            model: wallpapers
                            spacing: 18
                            clip: false
                            interactive: true
                            boundsBehavior: Flickable.StopAtBounds
                            // keep the selected wallpaper in the middle
                            highlightRangeMode: ListView.StrictlyEnforceRange
                            preferredHighlightBegin: width / 2 - picker.thumbW / 2
                            preferredHighlightEnd: width / 2 + picker.thumbW / 2
                            highlightMoveDuration: root.animMs * 2
                            snapMode: ListView.SnapToItem

                            delegate: Item {
                                id: wthumb
                                required property url fileUrl
                                required property string fileName
                                required property int index
                                readonly property bool centre: ListView.isCurrentItem
                                readonly property bool isSet: wthumb.fileUrl.toString() === pins.adapter.wallpaper
                                width: picker.thumbW
                                height: strip.height
                                z: centre ? 2 : 1

                                Rectangle {
                                    id: frame
                                    anchors.centerIn: parent
                                    width: picker.thumbW
                                    height: picker.thumbH
                                    radius: 20
                                    color: root.overlay
                                    border.width: wthumb.isSet ? 3 : (wthumb.centre ? 2 : 1)
                                    border.color: wthumb.isSet ? root.accent : (wthumb.centre ? root.fg : root.glassEdge)
                                    scale: wthumb.centre ? (thumbMouse.containsMouse ? 1.32 : 1.28) : (thumbMouse.containsMouse ? 0.9 : 0.84)
                                    opacity: wthumb.centre ? 1 : 0.55
                                    Behavior on scale { NumberAnimation { duration: root.animMs * 2; easing.type: Easing.OutBack } }
                                    Behavior on opacity { NumberAnimation { duration: root.animMs * 2 } }

                                    Image {
                                        anchors.fill: parent
                                        anchors.margins: 4
                                        source: wthumb.fileUrl
                                        asynchronous: true
                                        fillMode: Image.PreserveAspectCrop
                                        sourceSize.width: 640
                                    }

                                    // glossy highlight across the top of each picture
                                    Rectangle {
                                        anchors.fill: parent
                                        anchors.margins: 4
                                        radius: 16
                                        gradient: Gradient {
                                            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.22) }
                                            GradientStop { position: 0.35; color: Qt.rgba(1, 1, 1, 0) }
                                        }
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
                            visible: wallpapers.count === 0
                            horizontalAlignment: Text.AlignHCenter
                            text: "No wallpapers yet\nPut .jpg / .png / .webp files in ~/Pictures/Wallpapers"
                            color: root.muted
                            font.pixelSize: 14
                            lineHeight: 1.3
                        }
                    }

                    // ---- Name of the one in the middle ----
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.maximumWidth: wcardPick.width - 80
                        visible: wallpapers.count > 0
                        elide: Text.ElideMiddle
                        text: strip.currentItem ? strip.currentItem.fileName : ""
                        color: root.fg
                        font.pixelSize: 14
                        font.bold: true
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Scroll or ← →  browse      Click the middle one or Enter  set      R  random      Esc  close"
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

            // Crossfades to the new wallpaper instead of snapping
            Item {
                id: wp
                anchors.fill: parent
                readonly property string target: pins.adapter.wallpaper

                onTargetChanged: {
                    if (target === "") {
                        baseImg.source = "";
                        topImg.source = "";
                        topImg.opacity = 0;
                    } else if (baseImg.source == "") {
                        baseImg.source = target;
                    } else {
                        topImg.source = target;
                    }
                }
                Component.onCompleted: if (target !== "") baseImg.source = target

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
                        root.applyPalette(ctx.getImageData(0, 0, width, height).data);
                    }
                }

                Image {
                    id: baseImg
                    anchors.fill: parent
                    asynchronous: true
                    fillMode: Image.PreserveAspectCrop
                }

                Image {
                    id: topImg
                    anchors.fill: parent
                    asynchronous: true
                    fillMode: Image.PreserveAspectCrop
                    opacity: 0
                    onStatusChanged: if (status === Image.Ready) fade.restart()
                }

                NumberAnimation {
                    id: fade
                    target: topImg
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: root.animMs * 3
                    easing.type: Easing.InOutQuad
                    onFinished: {
                        baseImg.source = topImg.source;
                        topImg.opacity = 0;
                    }
                }
            }
        }
    }
}
