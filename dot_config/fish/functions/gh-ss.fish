
function gh-ss
    # Run gh auth switch with passed arguments
    command gh auth switch $argv

    # Detect active user
    set active_user (gh auth status --show-token | grep 'Active account: true' -B1 | grep 'Logged in to github.com account' | awk '{print $7}')

    # Map usernames to Git identity
    switch $active_user
        case prjctimg
            git config --local user.name prjctimg
            git config --local user.email "prjctimg@outlook.com"
        case xmlwizard
            git config --local user.name xmlwizard
            git config --local user.email "xml-wizard@outlook.com"
    end

    echo "Using Git credentials for" $active_user
end
