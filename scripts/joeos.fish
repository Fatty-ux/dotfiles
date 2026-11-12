# JoeOS shell settings for fish (linked into ~/.config/fish/conf.d/ by install.sh)
set -gx TERMINAL kitty
alias ff pokefetch

# Greeting: a random Pokémon next to fastfetch, only in the first prompt of a kitty window
if status is-interactive
    and type -q pokefetch
    and test "$TERM" = xterm-kitty
    pokefetch
end
