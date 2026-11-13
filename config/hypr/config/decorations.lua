-- Look and feel configuration

-- Glassy grey window outlines (format: rgba(RRGGBBAA), the last two digits are see-through-ness)
local GLASS_LIGHT  = "rgba(e6e9efcc)"   -- bright silver edge on the focused window
local GLASS_DARK   = "rgba(8b909bcc)"   -- darker grey it fades into
local GLASS_FAINT  = "rgba(5c606870)"   -- unfocused windows: faint, mostly see-through
local GLASS_LOCKED = "rgba(a8adb8cc)"   -- locked window groups

hl.config({
    general = {
        gaps_in = 3,
        gaps_out = 8,
        border_size = 2,
        extend_border_grab_area = 10,
        resize_on_border = true,
        col = {
            active_border = {
                colors = { GLASS_LIGHT, GLASS_DARK },
                angle = 45,
            },
            inactive_border = GLASS_FAINT,
        },
    },
    group = {
        col = {
            border_active = GLASS_LIGHT,
            border_inactive = GLASS_FAINT,
            border_locked_active = GLASS_LOCKED,
            border_locked_inactive = GLASS_FAINT,
        },
        groupbar = {
            col = {
                active = GLASS_LIGHT,
                inactive = GLASS_FAINT,
                locked_active = GLASS_LOCKED,
                locked_inactive = GLASS_FAINT,
            },
        },
    },
    decoration = {
        dim_special = 0.3,
        rounding = 10,
        active_opacity = 0.95,
        inactive_opacity = 0.85,
        fullscreen_opacity = 1,
        blur = {
            size = 5,
            passes = 4,
            special = true,
        },
    },
})
