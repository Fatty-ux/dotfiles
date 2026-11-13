# JoeOS terminal theme for fish.
# Every colour here is a terminal palette colour, and Quickshell builds that palette from the
# wallpaper, so the prompt and the colours of what you type follow the wallpaper too.
#   blue = the wallpaper's accent colour      brblack = soft tinted grey
# Sourced at the end of ~/.config/fish/config.fish so it wins over CachyOS's defaults.

# ---- Colours of what you type ----
set -g fish_color_normal normal
set -g fish_color_command blue --bold
set -g fish_color_keyword magenta --bold
set -g fish_color_param cyan
set -g fish_color_option cyan
set -g fish_color_quote green
set -g fish_color_redirection magenta
set -g fish_color_end blue
set -g fish_color_operator blue
set -g fish_color_escape magenta
set -g fish_color_error red
set -g fish_color_comment brblack --italics
set -g fish_color_autosuggestion brblack
set -g fish_color_valid_path --underline
set -g fish_color_cwd blue
set -g fish_color_user blue
set -g fish_color_host cyan
set -g fish_color_search_match --background=brblack
set -g fish_color_selection --background=brblack

# ---- Tab-completion menu ----
set -g fish_pager_color_prefix blue --bold
set -g fish_pager_color_completion normal
set -g fish_pager_color_description brblack
set -g fish_pager_color_progress brblack
set -g fish_pager_color_selected_background --background=brblack

# ---- Prompt ----
#   ~/dotfiles   main ●        (● = uncommitted changes)
#   ❯                          (turns red if the last command failed)
function fish_prompt
    set -l last $status
    echo
    set_color --bold blue
    echo -n (prompt_pwd --full-length-dirs 2)
    set -l branch (command git branch --show-current 2>/dev/null)
    if test -n "$branch"
        set_color normal
        set_color magenta
        echo -n "   $branch"
        if test -n "$(command git status --porcelain 2>/dev/null | head -n1)"
            set_color yellow
            echo -n " ●"
        end
    end
    echo
    if test $last -ne 0
        set_color --bold red
    else
        set_color --bold blue
    end
    echo -n "❯ "
    set_color normal
end

# no clutter on the right side
function fish_right_prompt
end
