// JoeOS online wallpapers: browse, download and set wallpapers from the web, inside the
// wallpaper picker (the "Online" button). Shown by shell.qml.
//   Wallhaven  pictures          no key needed
//   Pexels     pictures + live   key (Pexels paused new keys in 2026; old keys still work)
//   Pixabay    live              free key
// Click or Enter opens a big preview first; Set downloads and applies it.
// Keys (forwarded by shell.qml): arrows browse, Enter preview / set, D download, / search, Esc back.
// Each source remembers its search and scroll position.
// Downloads go to ~/Pictures/Wallpapers and ~/Videos/Wallpapers, so they also show up in
// the normal carousel. Keys and options live in ~/.config/joeos/online-wallpapers.json.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: ow

    property var theme                   // shell.qml's root (colours, fonts, animMs)
    property string kind: "photo"        // photo | video
    property string currentUrl: ""       // the wallpaper that's set now (file://...)
    signal use(string url, string fileName)

    readonly property string home: Quickshell.env("HOME")
    readonly property string photoDir: home + "/Pictures/Wallpapers"
    readonly property string videoDir: home + "/Videos/Wallpapers"
    readonly property string cfgDir: home + "/.config/joeos"

    // which inner panel is showing: browse | options | help
    property string panel: "browse"

    // ================= saved options =================
    property bool cfgReady: false
    Process {
        running: true
        command: ["sh", "-c", "mkdir -p \"$1\" && { [ -s \"$1/online-wallpapers.json\" ] || echo '{}' > \"$1/online-wallpapers.json\"; }", "sh", ow.cfgDir]
        onExited: ow.cfgReady = true
    }
    FileView {
        id: cfgFile
        path: ow.cfgReady ? ow.cfgDir + "/online-wallpapers.json" : ""
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        JsonAdapter {
            id: cfg
            property string photoSource: "wallhaven"
            property string videoSource: "pixabay"
            property string pexelsKey: ""
            property string pixabayKey: ""
            property int photoSize: 1080        // smallest picture to show: 1080 | 1440 | 2160
            property int videoSize: 1080        // biggest video to download
            property bool anime: true           // Wallhaven anime
            property bool preview: true         // play live wallpapers on hover
            property var last: ({})             // "source:kind" → { q, sort }: last search, kept across restarts
        }
    }

    // ================= sources =================
    readonly property var sources: ({
        wallhaven: { id: "wallhaven", name: "Wallhaven", kinds: ["photo"], key: "", signup: "https://wallhaven.cc",
                     sorts: [{ v: "toplist", l: "Top" }, { v: "date_added", l: "New" }, { v: "random", l: "Random" }] },
        pexels:    { id: "pexels", name: "Pexels", kinds: ["photo", "video"], key: "pexelsKey", signup: "https://www.pexels.com/api/new/", sorts: [],
                     paused: "Pexels has paused new API keys for now. If you already have one it still works; otherwise use Pixabay for live wallpapers." },
        pixabay:   { id: "pixabay", name: "Pixabay", kinds: ["video"], key: "pixabayKey", signup: "https://pixabay.com/api/docs/",
                     sorts: [{ v: "popular", l: "Top" }, { v: "latest", l: "New" }] }
    })
    readonly property var srcList: (kind === "video" ? ["pixabay", "pexels"] : ["wallhaven", "pexels"]).map(id => sources[id])
    readonly property string srcId: {
        const want = kind === "video" ? cfg.videoSource : cfg.photoSource;
        const ok = s => !s.key || keyOf(s) !== "";
        const pick = srcList.find(s => s.id === want) ?? srcList[0];
        // the chosen one has no key but another one works: use that instead
        if (pick && !ok(pick)) { const other = srcList.find(ok); if (other) return other.id; }
        return pick?.id ?? "";
    }
    readonly property var src: sources[srcId]
    function keyOf(s) { return s && s.key ? String(cfg[s.key] ?? "").trim() : ""; }
    readonly property bool needKey: !!src && src.key !== "" && keyOf(src) === ""

    readonly property var widths: ({ 1080: 1920, 1440: 2560, 2160: 3840 })
    readonly property int minPhotoW: widths[cfg.photoSize] ?? 1920
    readonly property int maxVideoW: widths[cfg.videoSize] ?? 1920

    function setSource(id) { if (kind === "video") cfg.videoSource = id; else cfg.photoSource = id; }

    // ================= searching =================
    property string sort: src?.sorts[0]?.v ?? ""
    property int page: 1
    property string seed: ""
    property bool more: false
    property bool loading: false
    property string error: ""
    property int token: 0
    property var cache: ({})

    ListModel { id: results }

    function reload() {
        token++;
        closePreview();
        if (curKey !== "") {
            const l = Object.assign({}, cfg.last);
            l[curKey] = { q: searchBox.text.trim(), sort: sort };
            if (JSON.stringify(l[curKey]) !== JSON.stringify(cfg.last[curKey] ?? null)) cfg.last = l;
        }
        results.clear();
        page = 1; seed = ""; more = false; error = "";
        grid.contentY = grid.originY;
        if (!src || needKey) { loading = false; return; }
        fetchPage();
    }
    function loadMore() {
        if (loading || !more || error !== "") return;
        page++;
        fetchPage();
    }
    function fetchPage() {
        const t = token;
        loading = true;
        search(srcId, kind, searchBox.text, sort, page, seed, r => {
            if (t !== ow.token) return;        // an older search came back late
            ow.loading = false;
            ow.error = r.error ?? "";
            r.items.forEach(i => results.append(i));
            ow.more = r.more;
            ow.seed = r.seed || ow.seed;
            if (r.more && r.items.length === 0 && !r.error) { ow.page++; ow.fetchPage(); }   // all filtered out: keep going
        });
    }

    onKindChanged: Qt.callLater(switchTo)
    onSrcIdChanged: Qt.callLater(switchTo)
    onNeedKeyChanged: Qt.callLater(reload)
    onMinPhotoWChanged: Qt.callLater(refreshAll)
    onMaxVideoWChanged: Qt.callLater(refreshAll)
    Connections { target: cfg; function onAnimeChanged() { Qt.callLater(ow.refreshAll); } }
    onVisibleChanged: if (visible) { rescan(); if (results.count === 0 && !loading) Qt.callLater(reload); }
    Component.onCompleted: { rescan(); Qt.callLater(switchTo); }

    // ---- each source + kind keeps its own search, results and scroll ----
    property string curKey: ""
    property var savedPages: ({})
    readonly property var fields: ["kind", "file", "url", "thumb", "big", "preview", "w", "h", "secs", "by", "page"]
    function stateKey() { return srcId + ":" + kind; }
    function plain(i) {
        if (i < 0 || i >= results.count) return null;
        const r = results.get(i), o = {};
        fields.forEach(f => o[f] = r[f]);
        return o;
    }
    function saveState() {
        if (curKey === "") return;
        const items = [];
        for (let i = 0; i < results.count; i++) items.push(plain(i));
        const st = Object.assign({}, savedPages);
        st[curKey] = { q: searchBox.text, sort: sort, page: page, seed: seed, more: more, error: error,
                       items: items, y: grid.contentY, cur: grid.currentIndex };
        savedPages = st;
    }
    function switchTo() {
        const k = stateKey();
        if (k === curKey || srcId === "") return;
        saveState();
        curKey = k;
        closePreview();
        const st = savedPages[k];
        if (st && st.items.length > 0) {
            token++;
            loading = false;
            results.clear();
            st.items.forEach(i => results.append(i));
            searchBox.text = st.q; sort = st.sort; page = st.page; seed = st.seed; more = st.more; error = st.error;
            Qt.callLater(() => { grid.currentIndex = st.cur; grid.contentY = st.y; });
            return;
        }
        const last = cfg.last[k] ?? {};
        searchBox.text = last.q ?? "";
        sort = (src?.sorts ?? []).some(o => o.v === last.sort) ? last.sort : (src?.sorts[0]?.v ?? "");
        reload();
    }
    // a setting changed what searches return: forget the saved pages
    function refreshAll() { savedPages = ({}); reload(); }

    // ---- topic chips under the search box ----
    readonly property var topics: kind === "video"
        ? ["Space", "Nature", "Ocean", "Rain", "City", "Neon", "Abstract", "Fire", "Clouds"]
        : srcId === "wallhaven"
            ? ["Space", "Nature", "Anime", "City", "Minimal", "Abstract", "Cars", "Gaming", "Cyberpunk"]
            : ["Space", "Nature", "Mountains", "City", "Minimal", "Abstract", "Ocean", "Night", "Forest"]

    // ---- preview + keyboard ----
    property bool previewOpen: false
    property int previewIndex: -1
    readonly property var pv: previewIndex >= 0 && previewIndex < results.count ? results.get(previewIndex) : null

    function openPreview(i) {
        if (i < 0 || i >= results.count) return;
        previewIndex = i;
        grid.currentIndex = i;
        previewOpen = true;
        navKeys.forceActiveFocus();
    }
    function closePreview() { previewOpen = false; }
    // Esc: close the preview / inner panel. false = nothing left to close
    function back() {
        if (previewOpen) { closePreview(); return true; }
        if (panel === "help") { panel = needKey ? "browse" : "options"; return true; }
        if (panel !== "browse") { panel = "browse"; return true; }
        return false;
    }
    function move(n) {
        if (results.count === 0) return;
        const i = Math.max(0, Math.min(results.count - 1, grid.currentIndex < 0 ? 0 : grid.currentIndex + n));
        grid.currentIndex = i;
        grid.positionViewAtIndex(i, GridView.Contain);
        if (previewOpen) previewIndex = i;
    }
    function focusSearch() { searchBox.input.forceActiveFocus(); searchBox.input.selectAll(); }
    // true = handled
    function handleKey(e) {
        const k = e.key;
        if (k === Qt.Key_Escape) { if (!back() && theme) theme.wallPickerOpen = false; return true; }
        if (panel !== "browse") return false;
        if (k === Qt.Key_Slash || (k === Qt.Key_F && (e.modifiers & Qt.ControlModifier))) { closePreview(); focusSearch(); return true; }
        if (needKey) return false;
        if (k === Qt.Key_Right || k === Qt.Key_Tab) { move(1); return true; }
        if (k === Qt.Key_Left || k === Qt.Key_Backtab) { move(-1); return true; }
        if (k === Qt.Key_Down) { move(previewOpen ? 1 : grid.cols); return true; }
        if (k === Qt.Key_Up) {
            if (!previewOpen && grid.currentIndex < grid.cols) { focusSearch(); return true; }
            move(previewOpen ? -1 : -grid.cols);
            return true;
        }
        const it = plain(Math.max(0, grid.currentIndex));
        if (k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_Space) {
            if (!it) return true;
            if (previewOpen) useItem(it); else openPreview(Math.max(0, grid.currentIndex));
            return true;
        }
        if (k === Qt.Key_D) { if (it && jobs[it.file]?.state !== "get") get(it, null); return true; }
        return false;
    }
    Item {
        id: navKeys
        Keys.onPressed: e => { if (ow.handleKey(e)) e.accepted = true; }
    }
    Keys.onPressed: e => { if (ow.handleKey(e)) e.accepted = true; }     // keys the search box passes up

    function search(id, kind, query, sort, page, seed, cb) {
        const s = sources[id];
        const q = encodeURIComponent((query ?? "").trim());
        let url = "", headers = [];
        if (id === "wallhaven") {
            const srt = sort || "toplist";
            url = "https://wallhaven.cc/api/v1/search?q=" + q + "&categories=" + (cfg.anime ? "110" : "100") +
                  "&purity=100&sorting=" + srt + "&order=desc&atleast=" + minPhotoW + "x" + Math.round(minPhotoW * 9 / 16) +
                  (srt === "toplist" ? "&topRange=1M" : "") + (seed ? "&seed=" + seed : "") + "&page=" + page;
        } else if (id === "pexels") {
            headers = ["Authorization: " + keyOf(s)];
            if (kind === "photo")
                url = q ? "https://api.pexels.com/v1/search?query=" + q + "&orientation=landscape&size=" + (minPhotoW >= 3840 ? "large" : "medium") + "&per_page=24&page=" + page
                        : "https://api.pexels.com/v1/curated?per_page=24&page=" + page;
            else
                url = q ? "https://api.pexels.com/videos/search?query=" + q + "&orientation=landscape&size=medium&per_page=24&page=" + page
                        : "https://api.pexels.com/videos/popular?min_width=1920&per_page=24&page=" + page;
        } else if (id === "pixabay") {
            url = "https://pixabay.com/api/videos/?key=" + encodeURIComponent(keyOf(s)) + "&q=" + q +
                  "&order=" + (sort || "popular") + "&safesearch=true&min_width=1920&per_page=24&page=" + page;
        }
        const done = body => {
            try { cb(parse(id, kind, JSON.parse(body), page)); }
            catch (e) { cb({ items: [], more: false, error: "Got an odd reply from " + s.name + "." }); }
        };
        if (cache[url]) { done(cache[url]); return; }
        fetch(url, headers, (body, status, code) => {
            if (code !== 0) return cb({ items: [], more: false, error: "Couldn't reach " + s.name + ". Check your internet." });
            if (status === 401 || status === 403) return cb({ items: [], more: false, error: s.name + " didn't accept the key. Check it in Options." });
            if (status === 429) return cb({ items: [], more: false, error: s.name + " says slow down. Try again in a minute." });
            if (status === 400 && page > 1) return cb({ items: [], more: false });
            if (status < 200 || status >= 300) return cb({ items: [], more: false, error: s.name + " answered " + status + ". Try again later." });
            const c = Object.assign({}, cache); c[url] = body; cache = c;      // Pixabay asks for caching
            done(body);
        });
    }

    function ext(u, fallback) {
        const m = String(u).split("?")[0].match(/\.([a-zA-Z0-9]{2,4})$/);
        return m ? m[1].toLowerCase().replace("jpeg", "jpg") : fallback;
    }
    function pickFile(files, maxW) {       // biggest that fits, else the smallest
        const ok = files.filter(f => f.url && f.w > 0 && f.w >= f.h).sort((a, b) => a.w - b.w);
        if (ok.length === 0) return null;
        const under = ok.filter(f => f.w <= maxW);
        return under.length ? under[under.length - 1] : ok[0];
    }
    function bigFile(files) {             // sharp enough for the big preview
        const ok = files.filter(f => f.url && f.w > 0).sort((a, b) => a.w - b.w);
        return ok.find(f => f.w >= 1280) ?? ok[ok.length - 1] ?? null;
    }
    function previewFile(files) {
        const ok = files.filter(f => f.url && f.w > 0).sort((a, b) => a.w - b.w);
        return ok.find(f => f.w >= 480) ?? ok[ok.length - 1] ?? null;
    }
    function compact(n) { return n >= 1000 ? (n / 1000).toFixed(n >= 10000 ? 0 : 1) + "k" : String(n); }

    function parse(id, kind, j, page) {
        const items = [];
        let more = false, seed = "";
        if (id === "wallhaven") {
            (j.data ?? []).forEach(d => items.push({
                kind: "photo", file: "wallhaven-" + d.id + "." + ext(d.path, "jpg"), url: d.path,
                thumb: d.thumbs?.large ?? d.thumbs?.small ?? "", big: d.path, preview: "", w: d.dimension_x, h: d.dimension_y,
                secs: 0, by: "♥ " + compact(d.favorites ?? 0), page: d.url ?? ""
            }));
            more = (j.meta?.current_page ?? 1) < (j.meta?.last_page ?? 1);
            seed = j.meta?.seed ?? "";
        } else if (id === "pexels" && kind === "photo") {
            (j.photos ?? []).forEach(p => {
                if (p.width < minPhotoW || p.height > p.width) return;
                items.push({
                    kind: "photo", file: "pexels-" + p.id + "." + ext(p.src?.original, "jpg"), url: p.src?.original ?? "",
                    thumb: p.src?.medium ?? "", big: p.src?.large2x ?? p.src?.large ?? "", preview: "", w: p.width, h: p.height, secs: 0, by: p.photographer ?? "", page: p.url ?? ""
                });
            });
            more = !!j.next_page;
        } else if (id === "pexels") {
            (j.videos ?? []).forEach(v => {
                const files = (v.video_files ?? []).filter(f => f.file_type === "video/mp4").map(f => ({ url: f.link, w: f.width ?? 0, h: f.height ?? 0 }));
                const best = pickFile(files, maxVideoW);
                if (!best || best.w < 1280) return;
                const prev = previewFile(files);
                items.push({
                    kind: "video", file: "pexels-" + v.id + ".mp4", url: best.url, thumb: v.image ?? "", big: bigFile(files)?.url ?? "",
                    preview: prev ? prev.url : "", w: best.w, h: best.h, secs: v.duration ?? 0, by: v.user?.name ?? "", page: v.url ?? ""
                });
            });
            more = !!j.next_page;
        } else if (id === "pixabay") {
            (j.hits ?? []).forEach(h => {
                const r = h.videos ?? {};
                const files = ["large", "medium", "small", "tiny"].map(k => r[k]).filter(f => f && f.url).map(f => ({ url: f.url, w: f.width ?? 0, h: f.height ?? 0 }));
                const best = pickFile(files, maxVideoW);
                if (!best) return;
                const prev = previewFile(files);
                items.push({
                    kind: "video", file: "pixabay-" + h.id + ".mp4", url: best.url,
                    thumb: r.medium?.thumbnail || r.small?.thumbnail || r.large?.thumbnail || "",
                    big: bigFile(files)?.url ?? "",
                    preview: prev ? prev.url : "", w: best.w, h: best.h, secs: h.duration ?? 0, by: h.user ?? "", page: h.pageURL ?? ""
                });
            });
            more = page * 24 < Math.min(500, j.totalHits ?? 0);
        }
        return { items: items, more: more, seed: seed, error: "" };
    }

    // curl: body, HTTP status, curl exit code
    function fetch(url, headers, cb) {
        const args = ["curl", "-sSL", "-m", "20", "-A", "joeos-wallpapers", "-w", "\n%{http_code}"];
        headers.forEach(h => args.push("-H", h));
        args.push(url);
        const p = fetchC.createObject(ow, { command: args, cb: cb });
        p.running = true;
    }
    Component {
        id: fetchC
        Process {
            id: fp
            property var cb: null
            property bool gotText: false
            property int code: -1
            property string body: ""
            function finish() {
                if (!gotText || code < 0 || !cb) return;
                const nl = body.lastIndexOf("\n");
                const c = cb; cb = null;
                c(nl >= 0 ? body.slice(0, nl) : body, parseInt(body.slice(nl + 1)) || 0, code);
                fp.destroy();
            }
            stdout: StdioCollector { onStreamFinished: { fp.body = text; fp.gotText = true; fp.finish(); } }
            onExited: (exitCode, exitStatus) => { fp.code = exitCode; fp.finish(); }
        }
    }

    // ================= downloading =================
    property var jobs: ({})        // file → { pct, state: "get" | "fail" }
    property var have: ({})        // files already in the wallpaper folders
    property var waiting: ({})     // file → callbacks to run when it's done

    function dirFor(k) { return k === "video" ? videoDir : photoDir; }
    function pathFor(it) { return dirFor(it.kind) + "/" + it.file; }
    function setJob(file, j) {
        const n = Object.assign({}, jobs);
        if (j) n[file] = j; else delete n[file];
        jobs = n;
    }
    // download if needed, then cb(path)
    function get(it, cb) {
        if (have[it.file]) { if (cb) cb(pathFor(it)); return; }
        const w = Object.assign({}, waiting);
        w[it.file] = (w[it.file] ?? []).concat(cb ? [cb] : []);
        waiting = w;
        if (jobs[it.file]?.state === "get") return;
        setJob(it.file, { pct: 0, state: "get" });
        const dest = pathFor(it);
        const p = dlC.createObject(ow, { file: it.file, dest: dest, command: ["sh", "-c",
            "mkdir -p \"$(dirname \"$2\")\" && curl -fL --retry 2 -m 900 --progress-bar -A joeos-wallpapers -o \"$2.part\" \"$1\" " +
            "&& mv -f \"$2.part\" \"$2\" || { rm -f \"$2.part\"; exit 1; }", "sh", it.url, dest] });
        p.running = true;
    }
    function useItem(it) {
        const f = it.file;
        get(it, path => ow.use("file://" + path, f));
    }
    Component {
        id: dlC
        Process {
            id: dp
            property string file: ""
            property string dest: ""
            property int last: -1
            stderr: SplitParser {
                splitMarker: "\r"
                onRead: data => {
                    const m = data.match(/(\d+(?:\.\d+)?)%/);
                    if (!m) return;
                    const pct = Math.floor(parseFloat(m[1]));
                    if (pct !== dp.last) { dp.last = pct; ow.setJob(dp.file, { pct: pct, state: "get" }); }
                }
            }
            onExited: (exitCode, exitStatus) => {
                const cbs = ow.waiting[dp.file] ?? [];
                const w = Object.assign({}, ow.waiting); delete w[dp.file]; ow.waiting = w;
                if (exitCode === 0) {
                    const h = Object.assign({}, ow.have); h[dp.file] = true; ow.have = h;
                    ow.setJob(dp.file, null);
                    cbs.forEach(c => c(dp.dest));
                } else ow.setJob(dp.file, { pct: 0, state: "fail" });
                dp.destroy();
            }
        }
    }
    function rescan() {
        scan.running = false;
        scan.command = ["sh", "-c", "find \"$1\" \"$2\" -maxdepth 1 -type f -printf '%f\\n' 2>/dev/null; true", "sh", photoDir, videoDir];
        scan.running = true;
    }
    Process {
        id: scan
        stdout: StdioCollector {
            onStreamFinished: {
                const h = {};
                text.split("\n").forEach(n => { if (n) h[n] = true; });
                ow.have = h;
            }
        }
    }

    // ================= look =================
    readonly property color fg: theme ? theme.fg : "white"
    readonly property color muted: theme ? theme.muted : "#aaa"
    readonly property color accent: theme ? theme.accent : "#89b4fa"
    readonly property color bgc: theme ? theme.bg : "#111"
    readonly property color surface: theme ? theme.surface : "#222"
    readonly property color overlay: theme ? theme.overlay : "#333"
    readonly property color edge: theme ? theme.glassEdge : "#444"
    readonly property color danger: theme ? theme.danger : "#f38ba8"
    readonly property string icons: theme ? theme.iconFont : ""
    readonly property int ms: theme ? theme.animMs : 120

    MouseArea { anchors.fill: parent }     // clicks in here don't close the picker

    // a rounded glass button: icon and/or label, "on" fills it with the accent
    component Btn: Rectangle {
        id: b
        property string icon: ""
        property string label: ""
        property bool on: false
        property bool small: false
        signal clicked()
        implicitWidth: bRow.implicitWidth + (small ? 16 : 22)
        implicitHeight: small ? 30 : 36
        radius: small ? 10 : 12
        color: on ? ow.accent : (bMouse.containsMouse ? ow.overlay : ow.surface)
        border.width: 1
        border.color: ow.edge
        scale: bMouse.pressed ? 0.94 : 1
        Behavior on color { ColorAnimation { duration: ow.ms } }
        Behavior on scale { NumberAnimation { duration: ow.ms; easing.type: Easing.OutBack } }
        Row {
            id: bRow
            anchors.centerIn: parent
            spacing: 6
            Text {
                visible: b.icon !== ""
                anchors.verticalCenter: parent.verticalCenter
                text: b.icon
                font.family: ow.icons
                font.pixelSize: b.small ? 11 : 12
                color: b.on ? ow.bgc : ow.accent
            }
            Text {
                visible: b.label !== ""
                anchors.verticalCenter: parent.verticalCenter
                text: b.label
                font.pixelSize: b.small ? 11 : 12
                font.bold: b.on
                color: b.on ? ow.bgc : ow.fg
            }
        }
        MouseArea {
            id: bMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: b.clicked()
        }
    }

    // a text box
    component Field: Rectangle {
        id: fl
        property alias text: fIn.text
        property alias input: fIn
        property string placeholder: ""
        property string icon: ""
        property bool secret: false
        property bool toGrid: false         // Down moves to the results
        signal accepted()
        signal edited()
        implicitHeight: 38
        radius: 13
        color: ow.surface
        border.width: 1
        border.color: fIn.activeFocus ? ow.accent : ow.edge
        Text {
            id: fIcon
            visible: fl.icon !== ""
            anchors.left: parent.left
            anchors.leftMargin: 13
            anchors.verticalCenter: parent.verticalCenter
            text: fl.icon
            font.family: ow.icons
            font.pixelSize: 12
            color: ow.muted
        }
        TextInput {
            id: fIn
            anchors.left: fIcon.visible ? fIcon.right : parent.left
            anchors.leftMargin: fIcon.visible ? 10 : 14
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            color: ow.fg
            font.pixelSize: 13
            clip: true
            selectByMouse: true
            echoMode: fl.secret ? TextInput.Password : TextInput.Normal
            onAccepted: fl.accepted()
            onEditingFinished: fl.edited()
            Keys.onEscapePressed: navKeys.forceActiveFocus()
            Keys.onDownPressed: e => { if (fl.toGrid) { navKeys.forceActiveFocus(); if (grid.currentIndex < 0) grid.currentIndex = 0; } else e.accepted = false; }
            Text {
                anchors.fill: parent
                verticalAlignment: Text.AlignVCenter
                visible: fIn.text === "" && !fIn.preeditText
                text: fl.placeholder
                color: ow.muted
                font.pixelSize: 13
            }
        }
    }

    component Spinner: Text {
        text: ""
        font.family: ow.icons
        font.pixelSize: 26
        color: ow.muted
        RotationAnimation on rotation { running: visible; loops: Animation.Infinite; from: 0; to: 360; duration: 1200 }
    }

    // a glass card like the rest of JoeOS
    component Glass: Rectangle {
        radius: 22
        color: ow.theme ? ow.theme.popupBg : "#cc111111"
        border.width: 1
        border.color: ow.edge
    }

    // one row on the Options page: title + hint on the left, controls on the right
    component OptRow: Rectangle {
        id: orow
        property string title: ""
        property string hint: ""
        default property alias trailing: orTrail.data
        Layout.fillWidth: true
        implicitHeight: hint !== "" ? 62 : 52
        radius: 16
        color: ow.surface
        border.width: 1
        border.color: ow.edge
        ColumnLayout {
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.right: orTrail.left
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            Text { Layout.fillWidth: true; text: orow.title; color: ow.fg; font.pixelSize: 13; font.bold: true; elide: Text.ElideRight }
            Text { Layout.fillWidth: true; visible: orow.hint !== ""; text: orow.hint; color: ow.muted; font.pixelSize: 11; elide: Text.ElideRight }
        }
        Row {
            id: orTrail
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6
        }
    }

    // ================= browse panel =================
    Glass {
        anchors.fill: parent
        visible: ow.panel === "browse"

        // toolbar: sources · search · sort · options
        RowLayout {
            id: bar
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 14
            spacing: 8

            Repeater {
                model: ow.srcList
                delegate: Btn {
                    required property var modelData
                    label: modelData.name
                    on: ow.srcId === modelData.id
                    onClicked: ow.setSource(modelData.id)
                }
            }
            Field {
                id: searchBox
                Layout.fillWidth: true
                toGrid: true
                icon: ""
                placeholder: ow.kind === "video" ? "Search live wallpapers" : "Search wallpapers"
                onAccepted: { typing.stop(); ow.reload(); }
                Connections { target: searchBox.input; function onTextEdited() { typing.restart(); } }
                Timer { id: typing; interval: 650; onTriggered: ow.reload() }
            }
            Repeater {
                model: ow.src?.sorts ?? []
                delegate: Btn {
                    required property var modelData
                    label: modelData.l
                    on: ow.sort === modelData.v
                    onClicked: { ow.sort = modelData.v; ow.reload(); }
                }
            }
            Btn { icon: ""; label: "Options"; onClicked: ow.panel = "options" }
        }

        Row {
            id: chips
            anchors.top: bar.bottom
            anchors.topMargin: 10
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            spacing: 6
            clip: true
            visible: !ow.needKey
            height: visible ? 30 : 0
            Repeater {
                model: ow.topics
                delegate: Btn {
                    required property string modelData
                    small: true
                    label: modelData
                    on: searchBox.text.trim().toLowerCase() === modelData.toLowerCase()
                    onClicked: { typing.stop(); searchBox.text = on ? "" : modelData; ow.reload(); }
                }
            }
        }

        GridView {
            id: grid
            anchors.top: chips.bottom
            anchors.topMargin: 12
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: 14
            anchors.rightMargin: 6
            anchors.bottomMargin: 10
            visible: !ow.needKey
            clip: true
            model: results
            boundsBehavior: Flickable.StopAtBounds
            cacheBuffer: 400
            readonly property int cols: Math.max(1, Math.floor(width / 300))
            cellWidth: Math.floor(width / cols)
            cellHeight: Math.round((cellWidth - 12) * 9 / 16) + 44
            onContentYChanged: if (contentY + height > contentHeight - cellHeight * 1.5) ow.loadMore()
            onCountChanged: if (count > 0 && contentHeight < height + cellHeight) Qt.callLater(ow.loadMore)

            delegate: Item {
                id: tile
                required property var model
                required property int index
                readonly property var it: model
                readonly property bool isVideo: it.kind === "video"
                readonly property bool got: !!ow.have[it.file]
                readonly property var job: ow.jobs[it.file] ?? null
                readonly property bool getting: job?.state === "get"
                readonly property bool failed: job?.state === "fail"
                readonly property bool isSet: got && ow.currentUrl === "file://" + ow.pathFor(it)
                readonly property bool hot: GridView.isCurrentItem
                width: grid.cellWidth
                height: grid.cellHeight

                function sizeLabel() {
                    const w = it.w, h = it.h;
                    const r = h >= 2160 || w >= 3840 ? "4K" : h >= 1440 || w >= 2560 ? "1440p" : h >= 1080 || w >= 1920 ? "1080p" : h + "p";
                    if (!isVideo) return r;
                    const s = Math.round(it.secs);
                    return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0") + " · " + r;
                }

                Rectangle {
                    id: frame
                    x: 0; y: 0
                    width: parent.width - 12
                    height: parent.height - 44
                    radius: 14
                    color: ow.overlay
                    clip: true
                    border.width: tile.isSet ? 3 : 1
                    border.color: tile.isSet ? ow.accent : (tile.hot ? ow.fg : ow.edge)
                    scale: tile.hot ? 1.03 : 1
                    Behavior on scale { NumberAnimation { duration: ow.ms * 2; easing.type: Easing.OutCubic } }

                    Image {
                        id: img
                        anchors.fill: parent
                        anchors.margins: 1
                        source: tile.it.thumb
                        asynchronous: true
                        fillMode: Image.PreserveAspectCrop
                        sourceSize.width: 560
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: img.status !== Image.Ready
                        text: img.status === Image.Error ? "" : (tile.isVideo ? "" : "")
                        font.family: ow.icons
                        font.pixelSize: 26
                        color: ow.muted
                    }

                    // live wallpapers play when you hover them
                    Loader {
                        id: prev
                        anchors.fill: parent
                        anchors.margins: 1
                        active: tile.isVideo && cfg.preview && tile.it.preview !== "" && hoverWait.ready
                        source: Qt.resolvedUrl("LiveWallpaper.qml")
                        onLoaded: item.source = tile.it.preview
                    }
                    Timer {
                        id: hoverWait
                        property bool ready: false
                        interval: 450
                        running: tMouse.containsMouse && tile.isVideo
                        onTriggered: ready = true
                    }
                    Connections {
                        target: tMouse
                        function onContainsMouseChanged() {
                            if (tMouse.containsMouse) grid.currentIndex = tile.index;
                            else hoverWait.ready = false;
                        }
                    }

                    // soft shine along the top, like the carousel cards
                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.14) }
                            GradientStop { position: 0.3; color: Qt.rgba(1, 1, 1, 0) }
                        }
                    }

                    // download progress along the bottom
                    Rectangle {
                        visible: tile.getting
                        anchors.left: parent.left
                        anchors.bottom: parent.bottom
                        height: 4
                        width: parent.width * (tile.job?.pct ?? 0) / 100
                        color: ow.accent
                        Behavior on width { NumberAnimation { duration: 200 } }
                    }

                    // size / length
                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.margins: 8
                        implicitWidth: sizeTxt.implicitWidth + 14
                        implicitHeight: 22
                        radius: 11
                        color: Qt.rgba(0, 0, 0, 0.55)
                        Text { id: sizeTxt; anchors.centerIn: parent; text: tile.sizeLabel(); color: "white"; font.pixelSize: 10; font.bold: true }
                    }
                    // downloaded / % / failed
                    Rectangle {
                        visible: tile.got || tile.getting || tile.failed
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 8
                        implicitWidth: Math.max(22, stTxt.implicitWidth + 14)
                        implicitHeight: 22
                        radius: 11
                        color: tile.failed ? ow.danger : tile.getting ? Qt.rgba(0, 0, 0, 0.55) : ow.accent
                        Text {
                            id: stTxt
                            anchors.centerIn: parent
                            text: tile.getting ? tile.job.pct + "%" : tile.failed ? "Failed" : ""
                            font.family: tile.getting || tile.failed ? "" : ow.icons
                            color: tile.getting ? "white" : ow.bgc
                            font.pixelSize: 10
                            font.bold: true
                        }
                    }

                    MouseArea {
                        id: tMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: m => {
                            if (m.button === Qt.RightButton) { if (tile.it.page) Qt.openUrlExternally(tile.it.page); }
                            else ow.openPreview(tile.index);
                        }
                    }
                }

                // under the picture: who made it · download · set
                RowLayout {
                    anchors.top: frame.bottom
                    anchors.topMargin: 6
                    anchors.left: frame.left
                    anchors.right: frame.right
                    spacing: 6
                    Text {
                        Layout.fillWidth: true
                        text: tile.it.by
                        color: ow.muted
                        font.pixelSize: 11
                        elide: Text.ElideRight
                    }
                    Btn {
                        visible: !tile.got
                        small: true
                        icon: tile.failed ? "" : ""
                        onClicked: if (!tile.getting) ow.get(ow.plain(tile.index), null)
                    }
                    Btn {
                        small: true
                        icon: tile.isSet ? "" : ""
                        label: tile.isSet ? "Set" : "Use"
                        on: !tile.isSet
                        onClicked: if (!tile.getting) ow.useItem(ow.plain(tile.index))
                    }
                }
            }

            footer: Item {
                width: grid.width
                height: ow.loading && grid.count > 0 ? 50 : 0
                Spinner { anchors.centerIn: parent; visible: parent.height > 0 }
            }
        }

        // empty / loading / error
        Column {
            anchors.centerIn: grid
            visible: !ow.needKey && grid.count === 0
            spacing: 12
            Spinner { anchors.horizontalCenter: parent.horizontalCenter; visible: ow.loading }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                horizontalAlignment: Text.AlignHCenter
                visible: !ow.loading
                text: ow.error !== "" ? ow.error
                    : "Nothing found" + (searchBox.text.trim() ? " for \"" + searchBox.text.trim() + "\"" : "") + " on " + (ow.src?.name ?? "")
                color: ow.muted
                font.pixelSize: 13
            }
            Btn {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: !ow.loading && ow.error !== ""
                icon: ""
                label: "Try again"
                onClicked: ow.reload()
            }
        }
        Rectangle {
            anchors.bottom: grid.bottom
            anchors.horizontalCenter: grid.horizontalCenter
            visible: ow.error !== "" && grid.count > 0
            implicitWidth: errTxt.implicitWidth + 24
            implicitHeight: 28
            radius: 14
            color: ow.danger
            Text { id: errTxt; anchors.centerIn: parent; text: ow.error; color: ow.bgc; font.pixelSize: 11; font.bold: true }
        }

        // a key is needed for this source
        Rectangle {
            anchors.centerIn: grid
            visible: ow.needKey
            width: Math.min(480, grid.width - 40)
            height: keyCol.implicitHeight + 36
            radius: 18
            color: ow.surface
            border.width: 1
            border.color: ow.edge
            ColumnLayout {
                id: keyCol
                x: 18; y: 18
                width: parent.width - 36
                spacing: 12
                Text { Layout.fillWidth: true; text: (ow.src?.name ?? "") + " needs a free key"; color: ow.fg; font.pixelSize: 15; font.bold: true }
                Text {
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    text: ow.src?.paused ? ow.src.paused
                        : "Paste it once and it's saved." + (ow.kind === "photo" ? " Wallhaven works without one." : "")
                    color: ow.muted
                    font.pixelSize: 12
                }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Field {
                        id: keyBox
                        Layout.fillWidth: true
                        icon: ""
                        secret: true
                        placeholder: "API key"
                        onAccepted: saveKey.clicked()
                    }
                    Btn {
                        id: saveKey
                        label: "Save"
                        on: keyBox.text.trim() !== ""
                        onClicked: if (keyBox.text.trim() && ow.src?.key) { cfg[ow.src.key] = keyBox.text.trim(); keyBox.text = ""; }
                    }
                }
                RowLayout {
                    spacing: 8
                    Btn { icon: ""; label: "How to get one"; onClicked: ow.panel = "help" }
                    Btn {
                        visible: !!ow.src?.paused
                        label: ow.kind === "video" ? "Use Pixabay" : "Use Wallhaven"
                        on: true
                        onClicked: ow.setSource(ow.kind === "video" ? "pixabay" : "wallhaven")
                    }
                    Btn { visible: !ow.src?.paused; icon: ""; label: "Open " + (ow.src?.name ?? ""); onClicked: Qt.openUrlExternally(ow.src.signup) }
                }
            }
        }

        // ---- big preview: a leaning card like the carousel, before anything downloads ----
        Item {
            id: preview
            anchors.fill: parent
            z: 20
            visible: opacity > 0.01
            opacity: ow.previewOpen && ow.pv ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: ow.ms * 2; easing.type: Easing.OutCubic } }

            readonly property var it: ow.pv
            readonly property bool isVideo: !!it && it.kind === "video"
            readonly property bool got: !!it && !!ow.have[it.file]
            readonly property var job: it ? (ow.jobs[it.file] ?? null) : null
            readonly property bool getting: job?.state === "get"
            readonly property bool failed: job?.state === "fail"
            readonly property bool isSet: got && ow.currentUrl === "file://" + ow.pathFor(it)
            readonly property real slant: 0.16

            // dim the grid; click it to go back
            Rectangle { anchors.fill: parent; radius: 22; color: Qt.rgba(0, 0, 0, 0.5) }
            MouseArea { anchors.fill: parent; onClicked: ow.closePreview() }

            Rectangle {
                id: pcard
                anchors.horizontalCenter: parent.horizontalCenter
                y: 18
                height: parent.height - 96
                width: Math.min(parent.width - 150 - preview.slant * height, height * 16 / 9)
                radius: 4
                color: ow.overlay
                clip: true
                border.width: 2
                border.color: preview.isSet ? ow.accent : ow.fg
                scale: ow.previewOpen ? 1 : 0.9
                Behavior on scale { NumberAnimation { duration: ow.ms * 2.6; easing.type: Easing.OutBack; easing.overshoot: 0.8 } }

                // lean the card (top pushed right)
                transform: Matrix4x4 {
                    matrix: Qt.matrix4x4(1, -preview.slant, 0, preview.slant * pcard.height / 2,
                                         0, 1, 0, 0,
                                         0, 0, 1, 0,
                                         0, 0, 0, 1)
                }

                MouseArea { anchors.fill: parent }      // clicks on the card don't close it

                // the picture leans back the other way so it isn't stretched
                Item {
                    width: parent.width + preview.slant * parent.height
                    height: parent.height
                    x: -preview.slant * parent.height / 2
                    transform: Matrix4x4 {
                        matrix: Qt.matrix4x4(1, preview.slant, 0, -preview.slant * pcard.height / 2,
                                             0, 1, 0, 0,
                                             0, 0, 1, 0,
                                             0, 0, 0, 1)
                    }
                    Image {
                        anchors.fill: parent
                        source: preview.it ? preview.it.thumb : ""
                        asynchronous: true
                        fillMode: Image.PreserveAspectCrop
                    }
                    Image {
                        id: bigImg
                        anchors.fill: parent
                        visible: !preview.isVideo
                        source: preview.visible && preview.it && !preview.isVideo ? preview.it.big : ""
                        asynchronous: true
                        fillMode: Image.PreserveAspectCrop
                        sourceSize.width: 1920
                        opacity: status === Image.Ready ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: ow.ms * 3 } }
                    }
                    Loader {
                        id: bigVid
                        anchors.fill: parent
                        active: preview.visible && preview.isVideo && preview.it.big !== ""
                        source: Qt.resolvedUrl("LiveWallpaper.qml")
                        onLoaded: item.source = Qt.binding(() => preview.it ? preview.it.big : "")
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
                Spinner {
                    anchors.centerIn: parent
                    visible: !preview.isVideo && bigImg.status === Image.Loading
                }
                // download progress along the bottom
                Rectangle {
                    visible: preview.getting
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
                    height: 5
                    width: parent.width * (preview.job?.pct ?? 0) / 100
                    color: ow.accent
                    Behavior on width { NumberAnimation { duration: 200 } }
                }
            }

            // previous / next
            Btn {
                anchors.verticalCenter: pcard.verticalCenter
                anchors.right: pcard.left
                anchors.rightMargin: 24 + preview.slant * pcard.height / 2
                icon: ""
                visible: ow.previewIndex > 0
                onClicked: ow.move(-1)
            }
            Btn {
                anchors.verticalCenter: pcard.verticalCenter
                anchors.left: pcard.right
                anchors.leftMargin: 24 + preview.slant * pcard.height / 2
                icon: ""
                visible: ow.previewIndex < results.count - 1
                onClicked: { ow.move(1); if (ow.previewIndex >= results.count - 3) ow.loadMore(); }
            }

            // what it is + what to do with it
            MouseArea { anchors.fill: infoRow }         // clicks here don't close the preview
            RowLayout {
                id: infoRow
                anchors.top: pcard.bottom
                anchors.topMargin: 16
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.min(parent.width - 40, Math.max(pcard.width, 620))
                spacing: 8

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1
                    Text {
                        Layout.fillWidth: true
                        text: preview.it ? (preview.it.by || ow.src?.name || "") : ""
                        color: ow.fg
                        font.pixelSize: 14
                        font.bold: true
                        elide: Text.ElideRight
                    }
                    Text {
                        Layout.fillWidth: true
                        text: preview.it ? preview.it.w + " × " + preview.it.h + "  ·  " + (ow.src?.name ?? "")
                              + (preview.isVideo ? "  ·  " + Math.round(preview.it.secs) + "s" : "") : ""
                        color: ow.muted
                        font.pixelSize: 11
                        elide: Text.ElideRight
                    }
                }
                Btn { icon: ""; label: "Page"; onClicked: if (preview.it?.page) Qt.openUrlExternally(preview.it.page) }
                Btn {
                    icon: preview.got ? "" : preview.failed ? "" : ""
                    label: preview.got ? "Saved" : preview.getting ? preview.job.pct + "%" : preview.failed ? "Retry" : "Download"
                    onClicked: if (!preview.got && !preview.getting) ow.get(ow.plain(ow.previewIndex), null)
                }
                Btn {
                    icon: preview.isSet ? "" : ""
                    label: preview.isSet ? "Set" : preview.getting ? "Downloading…" : "Set as wallpaper"
                    on: !preview.isSet
                    onClicked: if (!preview.getting && !preview.isSet) ow.useItem(ow.plain(ow.previewIndex))
                }
                Btn { icon: ""; label: "Close"; onClicked: ow.closePreview() }
            }
        }
    }

    // ================= options panel =================
    Glass {
        anchors.fill: parent
        visible: ow.panel === "options"

        RowLayout {
            id: optHead
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.margins: 14
            spacing: 10
            Btn { icon: ""; label: "Back"; onClicked: ow.panel = "browse" }
            Text { text: "Online options"; color: ow.fg; font.pixelSize: 16; font.bold: true }
        }

        Flickable {
            anchors.top: optHead.bottom
            anchors.topMargin: 14
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 14
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(640, parent.width - 28)
            contentHeight: opts.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: opts
                width: parent.width
                spacing: 10

                OptRow {
                    title: "Pexels key"
                    hint: "New keys are paused by Pexels; old ones work"
                    Field { width: 260; secret: true; placeholder: "Free key"; text: cfg.pexelsKey; onEdited: cfg.pexelsKey = text.trim() }
                }
                OptRow {
                    title: "Pixabay key"
                    hint: "Live wallpapers"
                    Field { width: 260; secret: true; placeholder: "Free key"; text: cfg.pixabayKey; onEdited: cfg.pixabayKey = text.trim() }
                }
                OptRow {
                    title: "Getting a key"
                    hint: "Takes about a minute, both are free"
                    Btn { small: true; icon: ""; label: "How"; onClicked: ow.panel = "help" }
                }
                OptRow {
                    title: "Picture size"
                    hint: "Smallest picture to show"
                    Repeater {
                        model: [{ v: 1080, l: "1080p" }, { v: 1440, l: "1440p" }, { v: 2160, l: "4K" }]
                        delegate: Btn { required property var modelData; small: true; label: modelData.l; on: cfg.photoSize === modelData.v; onClicked: cfg.photoSize = modelData.v }
                    }
                }
                OptRow {
                    title: "Live wallpaper size"
                    hint: "Biggest video to download (smaller is lighter to play)"
                    Repeater {
                        model: [{ v: 1080, l: "1080p" }, { v: 1440, l: "1440p" }, { v: 2160, l: "4K" }]
                        delegate: Btn { required property var modelData; small: true; label: modelData.l; on: cfg.videoSize === modelData.v; onClicked: cfg.videoSize = modelData.v }
                    }
                }
                OptRow {
                    title: "Anime"
                    hint: "Include anime wallpapers from Wallhaven"
                    Btn { small: true; label: cfg.anime ? "On" : "Off"; on: cfg.anime; onClicked: cfg.anime = !cfg.anime }
                }
                OptRow {
                    title: "Hover preview"
                    hint: "Play live wallpapers when you hover them"
                    Btn { small: true; label: cfg.preview ? "On" : "Off"; on: cfg.preview; onClicked: cfg.preview = !cfg.preview }
                }
                OptRow {
                    title: "Saved to"
                    hint: "~/Pictures/Wallpapers and ~/Videos/Wallpapers"
                }
            }
        }
    }

    // ================= how to get a key =================
    Glass {
        anchors.fill: parent
        visible: ow.panel === "help"

        RowLayout {
            id: helpHead
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.margins: 14
            spacing: 10
            Btn { icon: ""; label: "Back"; onClicked: ow.panel = ow.needKey ? "browse" : "options" }
            Text { text: "Getting a key"; color: ow.fg; font.pixelSize: 16; font.bold: true }
        }
        Flickable {
            anchors.top: helpHead.bottom
            anchors.topMargin: 14
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 14
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(640, parent.width - 28)
            contentHeight: helpCol.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            ColumnLayout {
                id: helpCol
                width: parent.width
                spacing: 12
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: helpTxt.implicitHeight + 32
                    radius: 16
                    color: ow.surface
                    border.width: 1
                    border.color: ow.edge
                    Text {
                        id: helpTxt
                        x: 16; y: 16
                        width: parent.width - 32
                        wrapMode: Text.Wrap
                        color: ow.fg
                        font.pixelSize: 12
                        lineHeight: 1.25
                        text: "Wallhaven (pictures) works without a key. Live wallpapers come from Pixabay, which needs a free key:\n\n" +
                              "1. Open the Pixabay page below and sign up or log in.\n" +
                              "2. Scroll to \"Search Images\" → Parameters. Your key is shown next to \"key\".\n" +
                              "3. Copy it and paste it into Options → Pixabay key.\n\n" +
                              "Pexels has paused new API keys for now. If you already have one, paste it into Options → Pexels key and it still works.\n\n" +
                              "Keys are saved in ~/.config/joeos/online-wallpapers.json."
                    }
                }
                RowLayout {
                    spacing: 8
                    Btn { icon: ""; label: "Open Pixabay"; on: true; onClicked: Qt.openUrlExternally(ow.sources.pixabay.signup) }
                }
            }
        }
    }
}
