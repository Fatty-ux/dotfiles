source /usr/share/cachyos-fish-config/cachyos-config.fish

# overwrite greeting
# potentially disabling fastfetch
#function fish_greeting
#    # smth smth
#end

# JoeOS: no CachyOS welcome, the Pokémon greeting replaces it
function fish_greeting
end

# JoeOS: prompt and colours that follow the wallpaper
source ~/dotfiles/scripts/joeos-theme.fish
