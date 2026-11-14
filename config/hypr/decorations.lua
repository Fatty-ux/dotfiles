
-- Keep the mouse where you left it: switching desktops (from the dock, the switcher or a
-- shortcut) or focusing a window on another monitor no longer teleports the cursor there.
hl.config({
    cursor = {
        no_warps = true,
    },
})

-- JoeOS Qt theme: KDE/Qt apps (Dolphin...) use qt6ct -> Kvantum glass + Papirus icons
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_STYLE_OVERRIDE", "kvantum")
