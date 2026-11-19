#! /usr/bin/env fish

# Some sessions (greeters, containers, non-login TTYs) do not export these.
set -q XDG_CONFIG_HOME; or set -gx XDG_CONFIG_HOME $HOME/.config
set -q XDG_DATA_HOME; or set -gx XDG_DATA_HOME $HOME/.local/share

# options
fish_default_key_bindings

bind \ea opencode
bind \ee nvim
bind \et btop
bind \eh "invoke_bash 'x --help'"
bind \e/ fzf

# All shutdown commands use the BusyBox-only wrapper (wmpoweroff hangs here).
function poweroff
    /usr/local/bin/busybox-poweroff $argv
end
function halt
    /usr/local/bin/busybox-poweroff $argv
end
function shutdown
    /usr/local/bin/busybox-poweroff $argv
end
function wmpoweroff
    /usr/local/bin/busybox-poweroff $argv
end
function reboot
    /usr/local/bin/busybox-reboot $argv
end
function wmreboot
    /usr/local/bin/busybox-reboot $argv
end

function _is_selecting
    set _sel_start (commandline -B)
    set _sel_end (commandline -E)
    if test -n "$_sel_start" -o -n "$_sel_end"
        return 0
    else
        return 1
    end
end

# Properly handle selection when shift+key is pressed
function _handle_selection
    if not _is_selecting
        commandline --function begin-selection
    end
    commandline --function $argv
end

# For keys like backspace/delete, delete the selection if it exists
function _kill_selection_or
    if _is_selecting
        commandline --function kill-selection
    else
        commandline --function $argv
    end
end

# ctrl+shift-right
bind \e\[1\;6C '_handle_selection forward-word'

# ctrl+shift-left
bind \e\[1\;6D '_handle_selection backward-word'

bind \e\[1\;6A '_handle_selection up-line'
bind \e\[1\;6B '_handle_selection down-line'


# Load shift-selection bindings
# fish_vi_key_bindings
function wk

    cd $HOME/workspace/

end

function x
    x-cmd $argv

end


function chssh_key --description="Change the passphrase for SSH key"


    ssh-keygen -p -f .ssh/id_ed25519


end

function zigfmt

    zig fmt $argv

end


function cron

    crontab $argv
end
function rc
    cd $HOME/sources/

end


function xx

    exit 0
end


function vig
    nvim $HOME/.config/ghostty/config

end

function ai
    opencode $argv
end

function vif
    vi $HOME/.config/fish/ $argv


end




function time_greeting
    set hour (date +"%H")
    # Display name for the greeter (different from the system user 'root').
    set name prjctimg
    if test $hour -ge 5 -a $hour -lt 12
        set greeting "Good morning, $name ☀️"
    else if test $hour -ge 12 -a $hour -lt 17
        set greeting "Good afternoon, $name 🌤️"
    else if test $hour -ge 17 -a $hour -lt 21
        set greeting "Good evening, $name 🌆"
    else
        set greeting "What is sleep, $name? 🌙"
    end

    printf (set_color blue)"%s"(set_color normal)"\n" "$greeting"

end
function daily_verse
    # Define the path to your verses JSON file.
    # You might want to adjust this path based on where you saved the file.
    set -l verse_file "$HOME/.config/fish/verses.json"

    set -l day_of_month (date +%d | sed 's/^0*//' | string trim)
    set -l index (math "$day_of_month" - 1)
    # Ensure the file exists before trying to read it
    if not test -f "$verse_file"
        return
    end

    set -l current_hour (date +%H)


    # Use 'jq' to read the JSON file, get the current day of the month,
    # and use it as an index to pick a verse.

    # Use 'jq' to extract the verse at the calculated index
    set -l verse (jq -r ".[$index % length].text" < "$verse_file")

    set -l verse_ref (jq -r ".[$index % length].reference" < "$verse_file")
    # Print the verse, with some styling

    if test $current_hour -lt 12
        echo $(random choice "🌅" "🌄" "🍃" )
    else if test $current_hour -lt 18
        echo $(random choice "🏙️" "🏖️" )
    else
        echo $(random choice "🌆" "🌇"  "🌃" "🌉")
    end
    # printf (set_color green)"Day $day_of_month\n\n"(set_color normal)

    echo ""
    printf (set_color cyan)"%s"(set_color normal)"\n" "$verse"

    echo ""
    printf (set_color blue)"%s"(set_color normal)"\n" "📜 $verse_ref"

end

function dashboard_greeter_nvim

    set options square alpha crunchbang-mini six fade suckless
    while true
        set choice $options[(math (random) % (count $options) + 1)]
        colorscript -e $choice | pv -qL 80 | lolcat -at
        sleep 6
        clear
    end
end

function fish_greeting


    time_greeting | pv -qL 70

end


## Run the specified module. Supports Zig, JS/TS, Fish/Bash, Lua and Python.

function run --description="Run a script. It will pick the program based on the extension."


    if not set -q argv[1]

        echo "Usage $0 <file>"
        exit 1
    end

    set file $argv[1]
    set ext (echo $file | awk -F '.' '{print $NF}')
    set -l rest $argv[2..-1]


    if test "$ext" = "$file"
        if not test -x $file
            echo "File not executable."
            chmod +x $file
            echo "File made executable. Running it..."
            $file $rest
        else
            $file $rest

        end
    else
        switch $ext
            case lua

                lua $file $rest

            case js ts mts mjs cjs


                bun $file $rest


            case sh
                bash $file $rest
            case fish

                fish $file $rest
            case zig

                zig run $file -- $rest
        end
    end
end
function vicron --description="Modify the cron scripts inside Neovim"
    vi $HOME/.config/.routines/
end


function manx

    invoke_bash "x --help"

end
function lsx --description="Like the ls command but supercharged"

    invoke_bash "x ls $argv"
end


# Source the configuration files
function so

    # @fish-lsp-disable-next-line 1004
    source $HOME/.config/fish/config.fish
end

function invoke_bash
    bash -ci $argv
end


function rm

    if command -q sudo
        command sudo rm -rfv $argv
    else
        command rm -rfv $argv
    end

end

function cdd --description="View directories as you change into them"
    if has_args $argv
        cd $HOME
    else if command -q x-cmd
        invoke_bash "x cd $argv"
    else
        cd $argv
    end
end


function agg --description="Convert terminal session recordings to GIF"

    for cast in $argv
        command agg $cast gif/$cast.gif
    end
end



function see --description="See an image in the terminal (requires Viu/chafa)"

    viu $argv


end

function has_args
    set len $(count $argv)
    test $len -eq 0
end

function to --description="Alias for the touch command"

    touch $argv

end

function git
    if command -q x-cmd
        x git $argv
    else
        command git $argv
    end
end


function lsp --description="List the PATH"
    invoke_bash "x path $argv"
end


function mtrx
    tr -c "[:digit:]" " " </dev/urandom | dd cbs=$COLUMNS conv=unblock | GREP_COLOR="132" grep --color "[^ ]"

end

function chrome --description="Launch the Chrome browser"
    garcon-url-handler --client $argv
end


function vi
    nvim $argv
end




function mv
    command mv -v $argv

end

function cp
    command cp $argv -rvf

end



function du
    command du -sh $argv

end



function add-pkg --description="Add package(s) using Nala"
    if command -q nala
        if command -q sudo; command sudo nala install $argv; else; command nala install $argv; end
    else
        if command -q sudo; command sudo apt-get install -y $argv; else; command apt-get install -y $argv; end
    end
end


function rm-pkg --description="Remove package(s) using Nala"
    if command -q nala
        if command -q sudo; command sudo nala remove $argv; else; command nala remove $argv; end
        if command -q sudo; command sudo nala clean; else; command nala clean; end
    else
        if command -q sudo; command sudo apt-get remove -y $argv; else; command apt-get remove -y $argv; end
    end
end

function top
    btop $argv

end




function tree --description="Show the top level directory structure"
    lsd -td --tree $argv
end

function cfg
    git --git-dir=$HOME/.cfg/ --work-tree=$HOME $argv

end

set -x EDITOR nvim
set -x MYVIMRC "$XDG_CONFIG_HOME/nvim/"
set -x TERMRC "$XDG_CONFIG_HOME/ghostty/config"
set -x GHOSTTY_SHELL_INTEGRATION_NO_SUDO 0
set -l _oldpath $PATH
set -gx PATH $HOME/.bun/bin $HOME/.opencode/bin $HOME/.local/bin \
    $HOME/go/bin $HOME/.local/share/nvim/mason/bin \
    /usr/local/sbin /usr/local/bin /usr/sbin /usr/bin /sbin /bin
# Keep other inherited entries, but de-duplicate and drop the Rust/Zig dirs we
# no longer install.
for _p in $_oldpath
    string match -q '*/.cargo/bin' -- $_p; and continue
    string match -q '*/.zvm/*' -- $_p; and continue
    contains -- $_p $PATH; or set -a PATH $_p
end
set -e _p
set -e _oldpath
set -x SHELL fish
set -x SUDO_EDITOR (command -s nvim)
set -x OPENSSL_DIR (command -s openssl)

# Interactive-only integrations (keeps `fish -c ...` output clean).
if status is-interactive
    carapace _carapace | source
    eval (starship init fish)
end
