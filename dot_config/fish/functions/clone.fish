function clone
    argparse 'h/help' -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: clone [username/repo]"
        echo "Clone a GitHub repository with depth 1"
        return 0
    end

    if test (count $argv) -ne 1
        echo "Error: Exactly one argument required (username/repo)"
        return 1
    end

    set repo $argv[1]
    git clone --depth 1 https://github.com/$repo.git
end