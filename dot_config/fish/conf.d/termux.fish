set -gx PAGER cat
set -gx SHELL (which fish)
set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx STARSHIP_LOG error

alias topen="termux-open"
alias tclip="termux-clipboard-set"
alias tpaste="termux-clipboard-get"
alias twifi="termux-wifi-connectioninfo"
alias tnotify="termux-notification"
alias tbattery="termux-battery-status"
alias tsensor="termux-sensor"
alias ttorch="termux-torch"
