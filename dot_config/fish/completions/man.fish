# ~/.config/fish/completions/man.fish

# Helper function to get a list of all available man pages, including subpages.
# This version is more robust. Instead of splitting by space, it uses a
# regular expression to remove the section and description, leaving only the page name.
# This correctly handles pages like `git-commit`, `docker-run`, etc.
function __fish_man_pages
    # 'apropos .' lists all known man pages.
    # 'string replace' with a regex removes the ' (section) - description' part.
    apropos . | string replace -r -- '\s+\(.+\)\s+.*$' ''
end

# Main completions for the `man` command.

# A list of all options that require a parameter. This is used in the condition below.
set -l man_opts_with_arg -k --apropos -f --whatis -l --local-file -P --pager -L --locale --sections

# Define all the options (flags) for `man`.
# -r or --require-parameter indicates the option needs an argument.
complete -c man -s k -l apropos -d "Search for keyword (apropos)" -r
complete -c man -s f -l whatis -d "Show 'whatis' descriptions" -r
complete -c man -s w -l where -l path -d "Print path of man page(s)"
complete -c man -s l -l local-file -d "Use local file instead of searching" -r
complete -c man -s a -l all -d "Show all matching pages"
complete -c man -s d -l debug -d "Print debugging info"
complete -c man -s h -l help -d "Display help and exit"
complete -c man -s P -l pager -d "Specify pager to use" -r
complete -c man -s L -l locale -d "Define the locale for this run" -r
complete -c man -l sections -d "Specify sections to search" -r
complete -c man -l no-subpages -d 'Do not show subpages like git-commit(1)'

# Complete the section numbers (e.g., `man 3 printf`).
complete -c man -n "count (commandline -opc) = 1" -a "1 2 3 4 5 6 7 8 9 n l p o" -d Section

# **THE FIX IS HERE**
# Provide the list of all man pages as arguments.
# The condition now correctly checks if the PREVIOUS token on the command line
# is one of the options that requires an argument. If it is, we don't suggest pages.
complete -c man -n "not contains -- (commandline -opc)[-1] \$man_opts_with_arg" -a "(__fish_man_pages)" -d Page
