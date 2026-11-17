#!/usr/bin/env python3
"""JoeOS sound helper (hub: Choose sound output).

  audio.py outputs          every output you can pick, one per line:  id<TAB>name<TAB>active(1/0)
  audio.py pick ID          switch to it: sets the graphics card / headset mode, makes it the
                            default, and moves everything that's playing over (like pavucontrol)
  audio.py fix              put the known-good settings back (the bar runs this at login and
                            whenever the sound system restarts)
  audio.py fix headset      only fix a USB headset that fell into output-only or the AC3 buzz mode
"""
import json, os, subprocess, sys, time

STATE = os.path.expanduser("~/.local/state/joeos-audio-out")
BAD = ("ac3", "dts", "surround", "a52")          # modes that buzz / don't work on headsets


def pactl(*args):
    try:
        return subprocess.run(["pactl", *args], capture_output=True, text=True, timeout=5).stdout
    except Exception:
        return ""


def pj(*args):
    try:
        return json.loads(pactl("-f", "json", *args) or "[]")
    except Exception:
        return []


def props(o):
    return o.get("properties") or {}


def is_hdmi(name):
    n = name.lower()
    return "hdmi" in n or "displayport" in n


def hdmi_profiles(card):
    """Plugged-in monitor speaker modes on a graphics card: [(profile, label, active)]"""
    out = []
    ports = card.get("ports") or {}
    for prof, info in (card.get("profiles") or {}).items():
        if not prof.startswith("output:hdmi-stereo") or "+input" in prof:
            continue
        if info.get("available") is False or info.get("available") == "no":
            continue
        label = None
        for pname, port in ports.items():
            if prof in (port.get("profiles") or []):
                if port.get("availability") == "not available":
                    label = False
                    break
                mon = props(port).get("device.product.name", "").strip()
                label = mon or None
        if label is False:
            continue                                   # nothing plugged in there
        n = prof.split("extra")[-1] if "extra" in prof else "0"
        port_no = int(n) + 1 if n.isdigit() else 1
        name = f"Monitor speakers · {label}" if label else f"Monitor speakers · HDMI {port_no}"
        out.append((prof, name, prof == card.get("active_profile")))
    return out


def card_label(card):
    p = props(card)
    return p.get("device.product.name") or p.get("device.description") or card.get("name", "")


def outputs():
    cards = {c["name"]: c for c in pj("list", "cards")}
    default = pactl("get-default-sink").strip()
    rows, done_cards = [], set()
    # graphics cards: one row per plugged-in monitor, whichever one is switched on right now
    for c in cards.values():
        if not any(is_hdmi(k) for k in (c.get("profiles") or {})):
            continue
        profs = hdmi_profiles(c)
        if not profs:
            continue
        done_cards.add(c["name"])
        for prof, name, active in profs:
            rows.append((f"card:{c['name']}|{prof}", name, active and sink_of(c["name"]) == default))
    # everything else that already is an output (headsets, speakers, bluetooth)
    for s in pj("list", "sinks"):
        sp = props(s)
        card = sp.get("device.name", "")
        if card in done_cards:
            continue
        if not card and (s["name"].startswith("joeos") or "null" in s["name"]):
            continue                                   # the bar's own recording / filter helpers
        name = s.get("description") or s["name"]
        if card in cards:
            base = card_label(cards[card])
            kind = "Headphones" if sp.get("device.bus") == "usb" or "usb" in s["name"] else ""
            if card.startswith("bluez"):
                kind = "Bluetooth"
            name = f"{kind} · {base}" if kind and base else (base or name)
        rows.append((f"sink:{s['name']}", name, s["name"] == default))
    return rows


def sink_of(card, tries=1):
    for i in range(tries):
        for s in pj("list", "sinks"):
            if props(s).get("device.name") == card:
                return s["name"]
        if i < tries - 1:
            time.sleep(0.1)
    return ""


def move_all(sink):
    """What pavucontrol does: make it the default AND move every playing app onto it."""
    pactl("set-default-sink", sink)
    pactl("set-sink-mute", sink, "0")
    for line in pactl("list", "short", "sink-inputs").splitlines():
        i = line.split("\t")[0]
        if i:
            pactl("move-sink-input", i, sink)
    vol = pactl("get-sink-volume", sink)
    try:
        pct = int(vol.split("%")[0].split()[-1])
        if pct < 5:
            pactl("set-sink-volume", sink, "60%")
    except Exception:
        pass


def save(key):
    os.makedirs(os.path.dirname(STATE), exist_ok=True)
    with open(STATE, "w") as f:
        f.write(key + "\n")


def pick(key, remember=True):
    if key.startswith("card:"):
        card, _, prof = key[5:].partition("|")
        cur = next((c for c in pj("list", "cards") if c["name"] == card), None)
        if not cur:
            return False
        if cur.get("active_profile") != prof:
            pactl("set-card-profile", card, prof)
            time.sleep(0.3)
        s = sink_of(card, tries=30)
        if not s:
            return False
        move_all(s)
    elif key.startswith("sink:"):
        s = key[5:]
        if s not in [x["name"] for x in pj("list", "sinks")]:
            return False
        move_all(s)
    else:
        return False
    if remember:
        save(key)
    return True


def fix_headsets(cards):
    """USB headsets (the K66): never AC3/surround, never output-only - keep the mic switched on."""
    changed = False
    for c in cards:
        if props(c).get("device.bus") != "usb":
            continue
        profs = c.get("profiles") or {}
        act = c.get("active_profile") or ""
        if act == "off" or not act:
            continue
        good = [k for k, v in profs.items()
                if "output:" in k and "input:" in k and not any(b in k for b in BAD)
                and v.get("available") is not False and v.get("available") != "no"]
        if not good:
            continue                                   # no output+mic mode (e.g. a webcam)
        bad = any(b in act for b in BAD) or ("input:" not in act)
        if not bad:
            continue
        out_part = act.split("+")[0]
        same = [k for k in good if k.split("+")[0] == out_part and not any(b in out_part for b in BAD)]
        stereo = [k for k in good if "iec958-stereo" in k] + [k for k in good if "analog-stereo+" in k]
        choice = (same or stereo or sorted(good, key=lambda k: -(profs[k].get("priority") or 0)))[0]
        pactl("set-card-profile", c["name"], choice)
        changed = True
    return changed


def fix_mic(cards):
    """If the default mic is gone (or is a 'monitor' of speakers), use the headset's mic."""
    cur = pactl("get-default-source").strip()
    srcs = [s for s in pj("list", "sources") if not s["name"].endswith(".monitor")]
    names = [s["name"] for s in srcs]
    if cur in names:
        return
    sinks_cards = {props(s).get("device.name") for s in pj("list", "sinks")}
    head = [s for s in srcs if props(s).get("device.bus") == "usb" and props(s).get("device.name") in sinks_cards]
    choice = (head or [s for s in srcs if props(s).get("device.bus") == "usb"] or srcs or [None])[0]
    if choice:
        pactl("set-default-source", choice["name"])


def fix(only_headset=False):
    cards = pj("list", "cards")
    if fix_headsets(cards):
        time.sleep(0.5)
    if only_headset:
        fix_mic(cards)
        return
    # put the output you last picked in the bar back (this is what keeps the monitor from
    # flipping back to the wrong HDMI port after a restart)
    try:
        key = open(STATE).read().strip()
    except Exception:
        key = ""
    if key:
        pick(key, remember=False)
    fix_mic(pj("list", "cards"))


def main():
    a = sys.argv[1:]
    cmd = a[0] if a else ""
    if cmd == "outputs":
        for key, name, active in outputs():
            print(f"{key}\t{name}\t{1 if active else 0}")
    elif cmd == "pick" and len(a) > 1:
        print("ok" if pick(a[1]) else "fail")
    elif cmd == "fix":
        fix(only_headset=len(a) > 1 and a[1] == "headset")
    else:
        print(__doc__.strip())
        sys.exit(1)


if __name__ == "__main__":
    main()
