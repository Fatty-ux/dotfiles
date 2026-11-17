local mainMod = "SUPER"
local launchPrefix = "uwsm app -- " -- if you are not using UWSM, make this empty (e.g. "")

-- JoeOS: everything that used to go to Noctalia now goes to Quickshell
local qs = "qs ipc call "
local capture = "bash $HOME/.config/quickshell/scripts/capture.sh "   -- $HOME is filled in by the shell

-- AZERTY fix: the number-row keys emit symbols (& é " ' ...) without Shift, so
-- binding to the digit characters fails. Bind by physical keycode instead.
-- Digit d -> evdev keycode: 1..9 => 10..18, 0 => 19
local function digitCode(d)
    return "code:" .. (d == 0 and 19 or (9 + d))
end

---------------------------
---- WINDOW MANAGEMENT ----
---------------------------

-- Window manipulation
hl.bind(mainMod .. " + Escape",      hl.dsp.exec_cmd("hyprctl kill"))
hl.bind(mainMod .. " + Q",           hl.dsp.window.close())
hl.bind(mainMod .. " + ALT + Space", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + D",           hl.dsp.window.fullscreen({ mode = 1 }))
hl.bind(mainMod .. " + F",           hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + J",           hl.dsp.layout("togglesplit"))

-- Change focus
hl.bind(mainMod .. " + Left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + Right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + Up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + Down",  hl.dsp.focus({ direction = "down" }))
hl.bind("ALT + Tab",           hl.dsp.window.cycle_next())

-- Desktop switcher: hold Super, tap Tab to move along, let go of Super to switch
hl.bind(mainMod .. " + Tab",         hl.dsp.exec_cmd(qs .. "desktops switcher"))
hl.bind(mainMod .. " + SHIFT + Tab", hl.dsp.exec_cmd(qs .. "desktops switcherBack"))

-- Move active window around
hl.bind(mainMod .. " + SHIFT + Up",                   hl.dsp.window.move({ direction = "u" }))
hl.bind(mainMod .. " + SHIFT + Right",                hl.dsp.window.move({ direction = "r" }))
hl.bind(mainMod .. " + SHIFT + Left",                 hl.dsp.window.move({ direction = "l" }))
hl.bind(mainMod .. " + SHIFT + Down",                 hl.dsp.window.move({ direction = "d" }))
hl.bind(mainMod .. " + SHIFT + " .. digitCode(1),     hl.dsp.window.move({ monitor = MONITOR1 }))
hl.bind(mainMod .. " + SHIFT + " .. digitCode(2),     hl.dsp.window.move({ monitor = MONITOR2 }))
hl.bind(mainMod .. " + SHIFT + " .. digitCode(3),     hl.dsp.window.move({ monitor = MONITOR3 }))
hl.bind(mainMod .. " + SHIFT + mouse_up",             hl.dsp.window.move({ monitor   = "-1" }))
hl.bind(mainMod .. " + SHIFT + mouse_down",           hl.dsp.window.move({ monitor   = "+1" }))

-- Move active window to the next / previous desktop (linked desktops, follows the window)
hl.bind(mainMod .. " + CONTROL + SHIFT + Right",      hl.dsp.exec_cmd(qs .. "desktops moveWindowBy 1"))
hl.bind(mainMod .. " + CONTROL + SHIFT + Left",       hl.dsp.exec_cmd(qs .. "desktops moveWindowBy -1"))
hl.bind(mainMod .. " + CONTROL + SHIFT + mouse_up",   hl.dsp.exec_cmd(qs .. "desktops moveWindowBy -1"))
hl.bind(mainMod .. " + CONTROL + SHIFT + mouse_down", hl.dsp.exec_cmd(qs .. "desktops moveWindowBy 1"))

-- Move active window to desktop N: Super+Ctrl+Shift+N follows it, Super+Alt+Shift+N leaves it there
for i = 1, NUM_WPM do
    local key = i % 10
    hl.bind(mainMod .. " + SHIFT + CONTROL + " .. digitCode(key), hl.dsp.exec_cmd(qs .. "desktops moveWindowTo " .. i))
end
for i = 1, NUM_WPM do
    local key = i % 10
    hl.bind(mainMod .. " + SHIFT + ALT + " .. digitCode(key), hl.dsp.exec_cmd(qs .. "desktops sendWindowTo " .. i))
end

-- Move & Resize with mouse
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag())
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize())

-- Zoom
local function zoomfunction(value)
    local zoomvalue = hl.get_config("cursor:zoom_factor")
    if (zoomvalue + value) > 3.0 then
        hl.config({ cursor = { zoom_factor = 3.0 } })
    elseif (zoomvalue + value) < 1.0 then
        hl.config({ cursor = { zoom_factor = 1.0 } })
    else
        hl.config({ cursor = { zoom_factor = zoomvalue + value } })
    end
end
hl.bind(mainMod .. " + Minus", function() zoomfunction(-0.3) end, { repeating = true})
hl.bind(mainMod .. " + Plus", function() zoomfunction(0.3) end, { repeating = true })

--# Zoom with keypad
hl.bind(mainMod .. " + code:82", function() zoomfunction(-0.3) end, { repeating = true })
hl.bind(mainMod .. " + code:86", function() zoomfunction(0.3) end, { repeating = true })


------------------
---- LAUNCHER ----
------------------

hl.bind(mainMod .. " + Return",     hl.dsp.exec_cmd(launchPrefix .. TERMINAL))
hl.bind(mainMod .. " + E",          hl.dsp.exec_cmd(launchPrefix .. FILE_MANAGER))
hl.bind(mainMod .. " + T",          hl.dsp.exec_cmd(launchPrefix .. EDITOR))
hl.bind(mainMod .. " + C",          hl.dsp.exec_cmd(launchPrefix .. CALCULATOR))
hl.bind("XF86Calculator",           hl.dsp.exec_cmd(launchPrefix .. CALCULATOR))
hl.bind(mainMod .. " + W",          hl.dsp.exec_cmd(launchPrefix .. BROWSER))
hl.bind("CONTROL + SHIFT + Escape", hl.dsp.exec_cmd(launchPrefix .. TERMINAL .. " -e btop"))

-- Quickshell: launcher and the top hub
hl.bind(mainMod .. " + Space",      hl.dsp.exec_cmd(qs .. "launcher toggle"))
hl.bind(mainMod .. " + X",          hl.dsp.exec_cmd(qs .. "hub toggle"))      -- hub (Home)
hl.bind(mainMod .. " + Z",          hl.dsp.exec_cmd(qs .. "hub open 5"))      -- hub: System
hl.bind(mainMod .. " + ALT + C",    hl.dsp.exec_cmd(qs .. "hub open 5"))      -- hub: System (power buttons)
hl.bind(mainMod .. " + L",          hl.dsp.exec_cmd("hyprlock"))              -- lock screen (needs hyprlock)

---------------------------
---- HARDWARE CONTROLS ----
---------------------------

-- Audio
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })

-- Media
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd(qs .. "media toggle"),   { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd(qs .. "media toggle"),   { locked = true })
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd(qs .. "media next"),     { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd(qs .. "media previous"), { locked = true })

-- Brightness (laptops / supported monitors; does nothing otherwise)
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"), { locked = true, repeating = true })

-------------------
---- UTILITIES ----
-------------------

-- Screen Capture
hl.bind(mainMod .. " + P",             hl.dsp.exec_cmd("hyprpicker -a -n"))
hl.bind(mainMod .. " + SHIFT + A",                       hl.dsp.exec_cmd(capture .. "shot area 0"))     -- drag a box
hl.bind(mainMod .. " + SHIFT + M",         hl.dsp.exec_cmd(capture .. "shot screen 0"))   -- this monitor
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd(qs .. "hub open 6"))           -- Capture tab (recording etc.)

-- Wallpaper picker
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd(qs .. "wallpaper toggle"))

-- Notifications (hub: Alerts)
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd(qs .. "hub open 4"))

-------------------------------
---- WORKSPACES & MONITORS ----
-------------------------------

-- Focus on monitors
hl.bind(mainMod .. " + " .. digitCode(1), hl.dsp.focus({ monitor = MONITOR1 }))
hl.bind(mainMod .. " + " .. digitCode(2), hl.dsp.focus({ monitor = MONITOR2 }))
hl.bind(mainMod .. " + " .. digitCode(3), hl.dsp.focus({ monitor = MONITOR3 }))

-- Switch to desktop N on ALL monitors (linked desktops): Super+Alt+N or Super+Ctrl+N
for i = 1, NUM_WPM do
    local key = i % 10
    hl.bind(mainMod .. " + ALT + " .. digitCode(key), hl.dsp.exec_cmd(qs .. "desktops switchTo " .. i))
end
for i = 1, NUM_WPM do
    local key = i % 10
    hl.bind(mainMod .. " + CONTROL + " .. digitCode(key), hl.dsp.exec_cmd(qs .. "desktops switchTo " .. i))
end

-- Next / previous desktop, and a new one
hl.bind(mainMod .. " + CONTROL + Right",       hl.dsp.exec_cmd(qs .. "desktops next"))
hl.bind(mainMod .. " + CONTROL + Left",        hl.dsp.exec_cmd(qs .. "desktops prev"))
hl.bind(mainMod .. " + CONTROL + Down",        hl.dsp.exec_cmd(qs .. "desktops add"))

-- Scroll through desktops
hl.bind(mainMod .. " + mouse_down",           hl.dsp.exec_cmd(qs .. "desktops prev"))
hl.bind(mainMod .. " + mouse_up",             hl.dsp.exec_cmd(qs .. "desktops next"))
hl.bind(mainMod .. " + CONTROL + mouse_up",   hl.dsp.exec_cmd(qs .. "desktops prev"))
hl.bind(mainMod .. " + CONTROL + mouse_down", hl.dsp.exec_cmd(qs .. "desktops next"))

-- Special workspace (scratchpad)
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special" }))
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special())
hl.bind("SUPER + K", hl.dsp.exec_cmd("qs ipc call keys toggle"))  -- keyboard shortcut cheat sheet
