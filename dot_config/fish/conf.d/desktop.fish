if type -q bat
    set -gx PAGER bat
    set -gx MANPAGER "bat -l man"
    set -gx MANROFFOPT "-c"
end

if type -q delta
    set -gx GIT_PAGER "delta"
end

alias open="xdg-open"
