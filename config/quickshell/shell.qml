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
    // Top bar: what to show
    readonly property bool topShowApps: true
    readonly property bool topShowSystem: true
    readonly property bool topShowClock: true
    readonly property bool topShowMedia: true
    readonly property bool topShowVolume: true
    readonly property bool topShowPanel: true
    readonly property bool topShowWeather: true
    // Weather (from Open-Meteo, no account or key needed). Put your own coordinates here.
    readonly property string weatherName: "Windsor, ON"
    readonly property real weatherLat: 42.3149
    readonly property real weatherLon: -83.0364
    readonly property bool weatherMetric: true      // false = Fahrenheit and mph
    // Desktops (workspaces): every monitor gets its own set
    readonly property int defaultDesktops: 4       // how many each monitor starts with
    readonly property int maxDesktops: 9
    readonly property bool showDesktopOsd: true    // small pop-up when you switch desktops
    // Auto-hide: "off" = always visible
    //            "windows" = fade away while a window is open on the workspace, reveal on hover
    //            "always" = always hidden until you move the mouse to the screen edge
    readonly property string autoHide: pins.adapter.autoHide    // change it from the control center
    readonly property int hideDelayMs: 450        // wait before hiding after the mouse leaves
    readonly property int hotZoneSize: 4          // thickness of the invisible hover strip at the screen edge (px)

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
        }
    }

    // System (PipeWire) volume
    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }
    readonly property var sink: Pipewire.defaultAudioSink

    // Wallpapers: drop images into ~/Pictures/Wallpapers
    FolderListModel {
        id: wallpapers
        folder: "file://" + Quickshell.env("HOME") + "/Pictures/Wallpapers"
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.JPG", "*.JPEG", "*.PNG", "*.WEBP"]
        showDirs: false
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
        const order = ["windows", "always", "off"];
        pins.adapter.autoHide = order[(order.indexOf(pins.adapter.autoHide) + 1) % order.length];
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
        running: root.panelOpen && root.tab === 2
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
            implicitHeight: 44
            color: "transparent"
            WlrLayershell.namespace: "quickshell-bar"

            // ----- Auto-hide -----
            readonly property bool wantHide: root.autoHide === "always"
                || (root.autoHide === "windows" && root.workspaceHasWindows(screen))
            property bool hotHover: false
            readonly property bool popupOpen: ctxMenu.visible || mediaPopup.visible || wallPopup.visible
            readonly property bool keepOpen: !wantHide || hotHover || cursorInBar || popupOpen
            property bool barShown: true
            readonly property bool atBottom: true
            property bool cursorInBar: false

            // Ask Hyprland where the cursor is while the bar is showing, so it hides
            // again reliably when the pointer leaves
            Timer {
                interval: 120
                repeat: true
                running: panel.barShown && panel.wantHide
                onTriggered: if (!cursorProc.running) cursorProc.running = true
            }

            Process {
                id: cursorProc
                command: ["hyprctl", "cursorpos"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        const parts = text.trim().split(/[ ,]+/);
                        const cx = parseFloat(parts[0]);
                        const cy = parseFloat(parts[1]);
                        const s = panel.screen;
                        const band = panel.implicitHeight + 6;
                        const inside = cx >= s.x && cx < s.x + s.width && cy >= s.y && cy < s.y + s.height;
                        const inBand = panel.atBottom ? cy >= s.y + s.height - band : cy < s.y + band;
                        panel.cursorInBar = inside && inBand;
                    }
                }
            }

            // Bars overlay windows instead of pushing them when auto-hide is on
            exclusionMode: root.autoHide === "off" ? ExclusionMode.Auto : ExclusionMode.Ignore
            // While hidden, clicks pass straight through to the windows underneath
            mask: barShown ? null : hiddenMask
            Region { id: hiddenMask }

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

            // Invisible strip at the screen edge that brings the bar back
            PanelWindow {
                id: hotZone
                screen: panel.screen
                visible: root.autoHide !== "off" && panel.wantHide && !panel.barShown
                anchors {
                    bottom: true
                    left: true
                    right: true
                }
                implicitHeight: root.hotZoneSize
                exclusionMode: ExclusionMode.Ignore
                color: "transparent"
                WlrLayershell.namespace: "quickshell-hotzone"
                onVisibleChanged: if (!visible) panel.hotHover = false

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: panel.hotHover = true
                    onExited: panel.hotHover = false
                }
            }


            // Closes this bar's popups when asked (outside click, workspace change)
            Connections {
                target: root
                function onCloseAllRequested() {
                    ctxMenu.visible = false;
                    mediaPopup.visible = false;
                    wallPopup.visible = false;
                }
            }

            property double mediaClosedAt: 0
            property double wallClosedAt: 0

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

            // ===== Wallpaper popup =====
            PopupWindow {
                id: wallPopup
                anchor.window: panel
                anchor.edges: Edges.Top
                anchor.gravity: Edges.Top
                implicitWidth: 540
                implicitHeight: 380
                color: "transparent"
                visible: false

                Rectangle {
                    opacity: 0
                    scale: 0.96
                    NumberAnimation on opacity { running: wallPopup.visible; from: 0; to: 1; duration: root.animMs; easing.type: Easing.OutCubic }
                    NumberAnimation on scale { running: wallPopup.visible; from: 0.96; to: 1; duration: root.animMs; easing.type: Easing.OutCubic }
                    anchors.fill: parent
                    radius: 14
                    color: root.popupBg
                    border.color: root.overlay
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 10

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Text {
                                Layout.fillWidth: true
                                text: "Wallpapers"
                                color: root.fg
                                font.pixelSize: 14
                                font.bold: true
                            }
                            IconButton {
                                theme: root
                                implicitWidth: 80
                                implicitHeight: 28
                                label: "Random"
                                onClicked: root.randomWallpaper()
                            }
                            IconButton {
                                theme: root
                                implicitWidth: 80
                                implicitHeight: 28
                                label: "Clear"
                                onClicked: root.setWallpaper("")
                            }
                        }

                        Text {
                            visible: wallpapers.count === 0
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            text: "No images found. Put .jpg / .png / .webp files in ~/Pictures/Wallpapers"
                            color: root.muted
                            font.pixelSize: 12
                        }

                        GridView {
                            id: wallGrid
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            visible: wallpapers.count > 0
                            clip: true
                            cellWidth: 172
                            cellHeight: 102
                            model: wallpapers

                            delegate: Item {
                                id: thumb
                                required property url fileUrl
                                width: wallGrid.cellWidth
                                height: wallGrid.cellHeight

                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: 4
                                    radius: 8
                                    color: root.overlay
                                    scale: thumbMouse.containsMouse ? 1.05 : 1
                                    Behavior on scale { NumberAnimation { duration: root.animMs; easing.type: Easing.OutCubic } }
                                    border.width: thumb.fileUrl.toString() === pins.adapter.wallpaper ? 2 : 0
                                    border.color: root.accent

                                    Image {
                                        anchors.fill: parent
                                        anchors.margins: 3
                                        source: thumb.fileUrl
                                        asynchronous: true
                                        fillMode: Image.PreserveAspectCrop
                                        sourceSize.width: 320
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        id: thumbMouse
                                        hoverEnabled: true
                                        onClicked: root.setWallpaper(thumb.fileUrl.toString())
                                    }
                                }
                            }
                        }
                    }
                }
            }

            HyprlandFocusGrab {
                windows: [wallPopup]
                active: wallPopup.visible
                onCleared: {
                    root.closeAll();
                    wallPopup.visible = false;
                    panel.wallClosedAt = Date.now();
                }
            }

            // ===== The bar itself =====
            RowLayout {
                id: barContent
                opacity: panel.barShown ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: root.animMs * 2; easing.type: Easing.OutCubic } }
                transform: Translate {
                    y: panel.barShown ? 0 : 16
                    Behavior on y { NumberAnimation { duration: root.animMs * 2; easing.type: Easing.OutCubic } }
                }
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 12
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
                Rectangle {
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: 22
                    Layout.alignment: Qt.AlignVCenter
                    color: root.overlay
                }

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
                            width: visible ? 38 : 0
                            height: 34

                            function focusNext() {
                                let next = 0;
                                for (let i = 0; i < wins.length; i++) {
                                    if (wins[i].activated) { next = (i + 1) % wins.length; break; }
                                }
                                wins[next].activate();
                            }

                            function menuEntries() {
                                const out = [];
                                out.push({ text: "Open new window", action: () => pin.entry.execute() });

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
                                radius: 8
                                color: pinMouse.containsMouse ? root.overlay
                                     : (pin.isActive ? root.surface : "transparent")
                                     Behavior on color { ColorAnimation { duration: root.animMs } }
                            }

                            IconImage {
                                anchors.centerIn: parent
                                implicitSize: 22
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
                                anchors.bottomMargin: 1
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
                                        pin.entry.execute();
                                    } else if (pin.running) {
                                        pin.focusNext();
                                    } else {
                                        pin.entry.execute();
                                    }
                                }
                            }
                        }
                    }
                }

                // ---- Other open windows (not pinned) ----
                Row {
                    spacing: 4
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    clip: true

                    Repeater {
                        model: ToplevelManager.toplevels

                        delegate: Rectangle {
                            id: win
                            required property var modelData
                            visible: root.bottomShowWindowList && !root.isPinned(modelData.appId)
                            width: visible ? 150 : 0
                            height: 32
                            radius: 8
                            color: modelData.activated ? root.overlay : root.surface
                            Behavior on color { ColorAnimation { duration: root.animMs } }
                            border.width: 1
                            border.color: root.glassEdge

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 6

                                IconImage {
                                    anchors.verticalCenter: parent.verticalCenter
                                    implicitSize: 18
                                    source: Quickshell.iconPath(win.modelData.appId, "application-x-executable")
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - 24
                                    text: win.modelData.title
                                    color: root.fg
                                    font.pixelSize: 12
                                    elide: Text.ElideRight
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
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
                    implicitWidth: 34
                    implicitHeight: 30
                    radius: 8
                    color: (wallPopup.visible || wallMouse.containsMouse) ? root.overlay : root.surface
                    Behavior on color { ColorAnimation { duration: root.animMs } }
                    border.width: 1
                    border.color: root.glassEdge

                    Text {
                        anchors.centerIn: parent
                        text: "▣"
                        color: root.fg
                        font.pixelSize: 15
                    }

                    MouseArea {
                        id: wallMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                        onClicked: mouse => {
                            if (mouse.button === Qt.MiddleButton) {
                                root.randomWallpaper();
                                return;
                            }
                            if (Date.now() - panel.wallClosedAt < 250) return;
                            if (wallPopup.visible) {
                                wallPopup.visible = false;
                                return;
                            }
                            const p = wallBtn.mapToItem(null, 0, 0);
                            wallPopup.anchor.rect = Qt.rect(p.x, p.y, wallBtn.width, wallBtn.height);
                            wallPopup.visible = true;
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

    // ---------- Top bar ----------
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
            implicitHeight: 44
            color: "transparent"
            WlrLayershell.namespace: "quickshell-topbar"

            // ----- Auto-hide -----
            readonly property bool wantHide: root.autoHide === "always"
                || (root.autoHide === "windows" && root.workspaceHasWindows(screen))
            property bool hotHover: false
            readonly property bool popupOpen: mediaPopup.visible || volPopup.visible || sysPopup.visible
            readonly property bool keepOpen: !wantHide || hotHover || cursorInBar || popupOpen
            property bool barShown: true
            readonly property bool atBottom: false
            property bool cursorInBar: false

            // Ask Hyprland where the cursor is while the bar is showing, so it hides
            // again reliably when the pointer leaves
            Timer {
                interval: 120
                repeat: true
                running: panel.barShown && panel.wantHide
                onTriggered: if (!cursorProc.running) cursorProc.running = true
            }

            Process {
                id: cursorProc
                command: ["hyprctl", "cursorpos"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        const parts = text.trim().split(/[ ,]+/);
                        const cx = parseFloat(parts[0]);
                        const cy = parseFloat(parts[1]);
                        const s = panel.screen;
                        const band = panel.implicitHeight + 6;
                        const inside = cx >= s.x && cx < s.x + s.width && cy >= s.y && cy < s.y + s.height;
                        const inBand = panel.atBottom ? cy >= s.y + s.height - band : cy < s.y + band;
                        panel.cursorInBar = inside && inBand;
                    }
                }
            }

            // Bars overlay windows instead of pushing them when auto-hide is on
            exclusionMode: root.autoHide === "off" ? ExclusionMode.Auto : ExclusionMode.Ignore
            // While hidden, clicks pass straight through to the windows underneath
            mask: barShown ? null : hiddenMask
            Region { id: hiddenMask }

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

            // Invisible strip at the screen edge that brings the bar back
            PanelWindow {
                id: hotZone
                screen: panel.screen
                visible: root.autoHide !== "off" && panel.wantHide && !panel.barShown
                anchors {
                    top: true
                    left: true
                    right: true
                }
                implicitHeight: root.hotZoneSize
                exclusionMode: ExclusionMode.Ignore
                color: "transparent"
                WlrLayershell.namespace: "quickshell-hotzone"
                onVisibleChanged: if (!visible) panel.hotHover = false

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: panel.hotHover = true
                    onExited: panel.hotHover = false
                }
            }


            // Closes this bar's popups when asked (outside click, workspace change)
            Connections {
                target: root
                function onCloseAllRequested() {
                    mediaPopup.visible = false;
                    volPopup.visible = false;
                    sysPopup.visible = false;
                }
            }

            property double mediaClosedAt: 0
            property double volClosedAt: 0
            property double sysClosedAt: 0

            // ===== Media popup =====
            PopupWindow {
                id: mediaPopup
                readonly property var p: root.player
                anchor.window: panel
                anchor.edges: Edges.Bottom
                anchor.gravity: Edges.Bottom
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

            // ===== Volume popup =====
            PopupWindow {
                id: volPopup
                readonly property var audio: root.sink ? root.sink.audio : null
                anchor.window: panel
                anchor.edges: Edges.Bottom
                anchor.gravity: Edges.Bottom
                implicitWidth: 280
                implicitHeight: volCol.implicitHeight + 24
                color: "transparent"
                visible: false

                Rectangle {
                    opacity: 0
                    scale: 0.96
                    NumberAnimation on opacity { running: volPopup.visible; from: 0; to: 1; duration: root.animMs; easing.type: Easing.OutCubic }
                    NumberAnimation on scale { running: volPopup.visible; from: 0.96; to: 1; duration: root.animMs; easing.type: Easing.OutCubic }
                    anchors.fill: parent
                    radius: 14
                    color: root.popupBg
                    border.color: root.overlay
                    border.width: 1

                    ColumnLayout {
                        id: volCol
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 10

                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                Layout.fillWidth: true
                                text: "Volume"
                                color: root.fg
                                font.pixelSize: 14
                                font.bold: true
                            }
                            Text {
                                text: volPopup.audio ? Math.round(volPopup.audio.volume * 100) + "%" : "--"
                                color: root.muted
                                font.pixelSize: 13
                            }
                        }

                        ValueBar {
                            theme: root
                            Layout.fillWidth: true
                            value: volPopup.audio ? volPopup.audio.volume : 0
                            onMoved: v => {
                                if (volPopup.audio) volPopup.audio.volume = v;
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: root.sink ? (root.sink.description || root.sink.name) : "No output device"
                            color: root.muted
                            font.pixelSize: 11
                            elide: Text.ElideRight
                        }

                        IconButton {
                            theme: root
                            Layout.fillWidth: true
                            label: volPopup.audio && volPopup.audio.muted ? "Unmute" : "Mute"
                            onClicked: {
                                if (volPopup.audio) volPopup.audio.muted = !volPopup.audio.muted;
                            }
                        }
                    }
                }
            }

            HyprlandFocusGrab {
                windows: [volPopup]
                active: volPopup.visible
                onCleared: {
                    root.closeAll();
                    volPopup.visible = false;
                    panel.volClosedAt = Date.now();
                }
            }

            // ===== System popup =====
            PopupWindow {
                id: sysPopup
                anchor.window: panel
                anchor.edges: Edges.Bottom
                anchor.gravity: Edges.Bottom
                implicitWidth: 340
                implicitHeight: sysCol.implicitHeight + 24
                color: "transparent"
                visible: false

                Rectangle {
                    opacity: 0
                    scale: 0.96
                    NumberAnimation on opacity { running: sysPopup.visible; from: 0; to: 1; duration: root.animMs; easing.type: Easing.OutCubic }
                    NumberAnimation on scale { running: sysPopup.visible; from: 0.96; to: 1; duration: root.animMs; easing.type: Easing.OutCubic }
                    anchors.fill: parent
                    radius: 14
                    color: root.popupBg
                    border.color: root.overlay
                    border.width: 1

                    ColumnLayout {
                        id: sysCol
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 10

                        Text {
                            text: "System"
                            color: root.fg
                            font.pixelSize: 14
                            font.bold: true
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            IconButton {
                                theme: root
                                Layout.fillWidth: true
                                label: "Reload Hyprland"
                                onClicked: {
                                    sysPopup.visible = false;
                                    Quickshell.execDetached(["hyprctl", "reload"]);
                                }
                            }
                            IconButton {
                                theme: root
                                Layout.fillWidth: true
                                label: "Restart bar"
                                onClicked: {
                                    sysPopup.visible = false;
                                    Quickshell.reload(true);
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            IconButton {
                                theme: root
                                Layout.fillWidth: true
                                label: "Lock"
                                onClicked: {
                                    sysPopup.visible = false;
                                    Quickshell.execDetached(["sh", "-c", "hyprlock || loginctl lock-session"]);
                                }
                            }
                            IconButton {
                                theme: root
                                Layout.fillWidth: true
                                label: "Sleep"
                                onClicked: {
                                    sysPopup.visible = false;
                                    Quickshell.execDetached(["systemctl", "suspend"]);
                                }
                            }
                            IconButton {
                                theme: root
                                Layout.fillWidth: true
                                label: "Config folder"
                                onClicked: {
                                    sysPopup.visible = false;
                                    Quickshell.execDetached(["xdg-open", Quickshell.env("HOME") + "/.config"]);
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            color: root.overlay
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            ConfirmButton {
                                theme: root
                                Layout.fillWidth: true
                                label: "Log out"
                                onConfirmed: {
                                    sysPopup.visible = false;
                                    Quickshell.execDetached(["hyprctl", "dispatch", "exit"]);
                                }
                            }
                            ConfirmButton {
                                theme: root
                                Layout.fillWidth: true
                                label: "Reboot"
                                onConfirmed: {
                                    sysPopup.visible = false;
                                    Quickshell.execDetached(["systemctl", "reboot"]);
                                }
                            }
                            ConfirmButton {
                                theme: root
                                Layout.fillWidth: true
                                label: "Shut down"
                                onConfirmed: {
                                    sysPopup.visible = false;
                                    Quickshell.execDetached(["systemctl", "poweroff"]);
                                }
                            }
                        }
                    }
                }
            }

            HyprlandFocusGrab {
                windows: [sysPopup]
                active: sysPopup.visible
                onCleared: {
                    root.closeAll();
                    sysPopup.visible = false;
                    panel.sysClosedAt = Date.now();
                }
            }

            // ===== Top bar contents =====
            Item {
                id: barContent
                opacity: panel.barShown ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: root.animMs * 2; easing.type: Easing.OutCubic } }
                transform: Translate {
                    y: panel.barShown ? 0 : -16
                    Behavior on y { NumberAnimation { duration: root.animMs * 2; easing.type: Easing.OutCubic } }
                }
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 12

                // ---- Left: system tab ----
                RowLayout {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Rectangle {
                        id: panelBtn
                        visible: root.topShowPanel
                        Layout.alignment: Qt.AlignVCenter
                        implicitWidth: panelLabel.implicitWidth + 24
                        implicitHeight: 30
                        radius: 8
                        color: (root.panelOpen || panelMouse.containsMouse) ? root.overlay : root.surface
                        Behavior on color { ColorAnimation { duration: root.animMs } }
                        border.width: 1
                        border.color: root.glassEdge

                        Text {
                            id: panelLabel
                            anchors.centerIn: parent
                            text: notifServer.trackedNotifications.values.length > 0
                                ? "Panel (" + notifServer.trackedNotifications.values.length + ")" : "Panel"
                            color: root.fg
                            font.pixelSize: 12
                        }

                        MouseArea {
                            id: panelMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                if (Date.now() - root.panelClosedAt < 250) return;
                                root.panelOpen = !root.panelOpen;
                            }
                        }
                    }


                    Rectangle {
                        id: appsBtn
                        visible: root.topShowApps
                        Layout.alignment: Qt.AlignVCenter
                        implicitWidth: appsLabel.implicitWidth + 24
                        implicitHeight: 30
                        radius: 8
                        color: (root.launcherOpen || appsMouse.containsMouse) ? root.overlay : root.surface
                        Behavior on color { ColorAnimation { duration: root.animMs } }
                        border.width: 1
                        border.color: root.glassEdge

                        Text {
                            id: appsLabel
                            anchors.centerIn: parent
                            text: "Apps"
                            color: root.fg
                            font.pixelSize: 12
                        }

                        MouseArea {
                            id: appsMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.launcherOpen = !root.launcherOpen
                        }
                    }

                    Rectangle {
                        id: sysBtn
                        visible: root.topShowSystem
                        Layout.alignment: Qt.AlignVCenter
                        implicitWidth: sysLabel.implicitWidth + 24
                        implicitHeight: 30
                        radius: 8
                        color: (sysPopup.visible || sysMouse.containsMouse) ? root.overlay : root.surface
                        Behavior on color { ColorAnimation { duration: root.animMs } }
                        border.width: 1
                        border.color: root.glassEdge

                        Text {
                            id: sysLabel
                            anchors.centerIn: parent
                            text: "System"
                            color: root.fg
                            font.pixelSize: 12
                        }

                        MouseArea {
                            id: sysMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                if (Date.now() - panel.sysClosedAt < 250) return;
                                if (sysPopup.visible) {
                                    sysPopup.visible = false;
                                    return;
                                }
                                const p = sysBtn.mapToItem(null, 0, 0);
                                sysPopup.anchor.rect = Qt.rect(p.x, p.y, sysBtn.width, sysBtn.height);
                                sysPopup.visible = true;
                            }
                        }
                    }
                }

                // ---- Center: date and time ----
                Rectangle {
                    anchors.centerIn: parent
                    visible: root.topShowClock
                    implicitWidth: topClock.implicitWidth + 28
                    implicitHeight: 30
                    radius: 8
                    color: root.surface
                    border.width: 1
                    border.color: root.glassEdge

                    Text {
                        id: topClock
                        anchors.centerIn: parent
                        text: Qt.formatDateTime(clock.date, "dddd, MMM d    " + root.timePattern)
                        color: root.fg
                        font.pixelSize: 13
                    }
                }

                // ---- Right: media + volume ----
                RowLayout {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                // ---- Media button (only shows when something is playing/paused) ----
                Rectangle {
                    id: mediaBtn
                    visible: root.topShowMedia && root.player !== null
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

                    // ---- Volume (scroll to change, middle click to mute) ----
                    Rectangle {
                        id: weatherBtn
                        visible: root.topShowWeather
                        Layout.alignment: Qt.AlignVCenter
                        implicitWidth: weatherLabel.implicitWidth + 24
                        implicitHeight: 30
                        radius: 8
                        color: (root.weatherOpen || weatherMouse.containsMouse) ? root.overlay : root.surface
                        Behavior on color { ColorAnimation { duration: root.animMs } }
                        border.width: 1
                        border.color: root.glassEdge

                        Text {
                            id: weatherLabel
                            anchors.centerIn: parent
                            text: root.wxNow ? root.wxNow.icon + "  " + root.wxNow.temp + "°" : "Weather"
                            color: root.fg
                            font.pixelSize: 12
                        }

                        MouseArea {
                            id: weatherMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                if (Date.now() - root.weatherClosedAt < 250) return;
                                root.weatherOpen = !root.weatherOpen;
                            }
                        }
                    }


                    Rectangle {
                        id: volBtn
                        visible: root.topShowVolume
                        Layout.alignment: Qt.AlignVCenter
                        implicitWidth: volLabel.implicitWidth + 24
                        implicitHeight: 30
                        radius: 8
                        color: (volPopup.visible || volMouse.containsMouse) ? root.overlay : root.surface
                        Behavior on color { ColorAnimation { duration: root.animMs } }
                        border.width: 1
                        border.color: root.glassEdge

                        Text {
                            id: volLabel
                            anchors.centerIn: parent
                            color: root.fg
                            font.pixelSize: 12
                            text: !volPopup.audio ? "Vol --"
                                : (volPopup.audio.muted ? "Vol muted"
                                : "Vol " + Math.round(volPopup.audio.volume * 100) + "%")
                        }

                        MouseArea {
                            id: volMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                            onClicked: mouse => {
                                if (mouse.button === Qt.MiddleButton) {
                                    if (volPopup.audio) volPopup.audio.muted = !volPopup.audio.muted;
                                    return;
                                }
                                if (Date.now() - panel.volClosedAt < 250) return;
                                if (volPopup.visible) {
                                    volPopup.visible = false;
                                    return;
                                }
                                const p = volBtn.mapToItem(null, 0, 0);
                                volPopup.anchor.rect = Qt.rect(p.x, p.y, volBtn.width, volBtn.height);
                                volPopup.visible = true;
                            }
                            onWheel: wheel => {
                                const a = volPopup.audio;
                                if (!a) return;
                                const step = wheel.angleDelta.y > 0 ? root.volumeStep : -root.volumeStep;
                                a.volume = Math.max(0, Math.min(1, a.volume + step));
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
            color: "#66000000"

            onVisibleChanged: {
                if (visible) {
                    searchInput.text = "";
                    appList.currentIndex = 0;
                    searchInput.forceActiveFocus();
                }
            }

            // Click outside the card to close
            MouseArea {
                anchors.fill: parent
                onClicked: root.launcherOpen = false
            }

            Rectangle {
                id: card
                opacity: 0
                scale: 0.96
                NumberAnimation on opacity { running: launcher.visible; from: 0; to: 1; duration: root.animMs; easing.type: Easing.OutCubic }
                NumberAnimation on scale { running: launcher.visible; from: 0.96; to: 1; duration: root.animMs; easing.type: Easing.OutCubic }
                property var results: root.searchApps(searchInput.text)

                width: 560
                height: 440
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -60
                radius: 16
                color: root.popupBg
                border.color: root.overlay
                border.width: 1

                function launchCurrent() {
                    if (appList.currentIndex < 0 || appList.currentIndex >= results.length) return;
                    const e = results[appList.currentIndex];
                    root.launcherOpen = false;
                    e.execute();
                }

                // Swallow clicks inside the card
                MouseArea { anchors.fill: parent }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 12

                    // Search box
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 44
                        radius: 10
                        color: root.surface
                        border.color: root.accent
                        border.width: 1

                        TextInput {
                            id: searchInput
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            verticalAlignment: TextInput.AlignVCenter
                            color: root.fg
                            font.pixelSize: 16
                            clip: true
                            selectByMouse: true

                            onTextChanged: appList.currentIndex = 0

                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_Escape) {
                                    root.launcherOpen = false;
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab) {
                                    appList.currentIndex = Math.min(card.results.length - 1, appList.currentIndex + 1);
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab) {
                                    appList.currentIndex = Math.max(0, appList.currentIndex - 1);
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    card.launchCurrent();
                                    event.accepted = true;
                                }
                            }

                            Text {
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                visible: searchInput.text === ""
                                text: "Search apps..."
                                color: root.muted
                                font.pixelSize: 16
                            }
                        }
                    }

                    // Results
                    ListView {
                        id: appList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 2
                        model: card.results
                        currentIndex: 0
                        highlightMoveDuration: 0
                        keyNavigationEnabled: false

                        delegate: Rectangle {
                            id: row
                            required property var modelData
                            required property int index
                            width: appList.width
                            height: 48
                            radius: 10
                            color: row.ListView.isCurrentItem ? root.overlay
                                 : (rowMouse.containsMouse ? root.surface : "transparent")

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 12

                                IconImage {
                                    implicitSize: 30
                                    source: Quickshell.iconPath(row.modelData.icon, "application-x-executable")
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0

                                    Text {
                                        Layout.fillWidth: true
                                        text: row.modelData.name
                                        color: root.fg
                                        font.pixelSize: 14
                                        font.bold: true
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        visible: text !== ""
                                        text: row.modelData.comment || row.modelData.genericName || ""
                                        color: root.muted
                                        font.pixelSize: 11
                                        elide: Text.ElideRight
                                    }
                                }
                            }

                            MouseArea {
                                id: rowMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    root.launcherOpen = false;
                                    row.modelData.execute();
                                }
                            }
                        }
                    }

                    Text {
                        visible: card.results.length === 0
                        Layout.alignment: Qt.AlignHCenter
                        text: "No matching apps"
                        color: root.muted
                        font.pixelSize: 13
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
                top: 54
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
                        sub: root.autoHide === "windows" ? "When windows open"
                            : (root.autoHide === "always" ? "Always" : "Off"),
                        active: root.autoHide !== "off",
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

                                    Text {
                                        anchors.centerIn: parent
                                        text: tabBtn.modelData
                                        color: root.tab === tabBtn.index ? root.bg : root.fg
                                        font.pixelSize: 13
                                        font.bold: root.tab === tabBtn.index
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
            top: 54
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
                top: 54
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
