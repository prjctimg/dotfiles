
function ssh_agent --description "Start or reuse a persistent ssh-agent"
    set -l agent_file ~/.ssh/agent_env

    # If we already have an agent file, source it
    if test -f $agent_file
        source $agent_file ^/dev/null
    end

    # Check if the agent is alive; if not, start a new one
    if not ssh-add -l >/dev/null 2>&1
        ssh-agent -c | sed 's/^echo/#echo/' >$agent_file
        source $agent_file ^/dev/null

        if test -f ~/.ssh/id_rsa
            ssh-add ~/.ssh/id_rsa >/dev/null 2>&1
        end
        if test -f ~/.ssh/id_ed25519
            ssh-add ~/.ssh/id_ed25519 >/dev/null 2>&1
        end
    end

    clear
end
