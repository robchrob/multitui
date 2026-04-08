# mtui bash completion script
# MultiTUI (mtui) — OpenCode Docker Orchestrator
# Install: source this file in ~/.bashrc or copy to /etc/bash_completion.d/mtui
# Requires: bash 4+ (for associative arrays and [[ ]])

_mtui_version() {
    local mtui_path
    if [[ -f "./mtui" ]]; then
        mtui_path="./mtui"
    elif command -v mtui &>/dev/null; then
        mtui_path="mtui"
    else
        echo "unknown"
        return
    fi
    grep -m1 '^MTUI_VERSION=' "$mtui_path" 2>/dev/null | cut -d'"' -f2
}

_mtui_header() {
    echo "MultiTUI (mtui) — OpenCode Docker Orchestrator v$(_mtui_version)"
}

_mtui_containers() {
    docker ps -a --filter "name=^mtui-" --format '{{.Names}}' 2>/dev/null | sed 's/^mtui-//'
}

_mtui() {
    local cur prev words cword i
    
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    
    words=("${COMP_WORDS[@]}")
    cword=$COMP_CWORD
    
    if [[ $cword -eq 1 ]]; then
        COMPREPLY=($(compgen -W "setup build init bootstrap start stop clean list status branch update" -- "${cur}"))
        return
    fi
    
    case "${words[1]}" in
        branch)
            if [[ $cword -eq 2 ]]; then
                COMPREPLY=($(compgen -W "create status" -- "${cur}"))
                return
            fi
            ;;
        setup|init|bootstrap)
            return
            ;;
        build)
            if [[ "$cur" == -* ]]; then
                COMPREPLY=($(compgen -W "--no-cache" -- "${cur}"))
                return
            fi
            ;;
        start)
            if [[ "$prev" == "-p" || "$prev" == "--port" ]]; then
                return
            fi
            if [[ "$cur" == -* ]]; then
                COMPREPLY=($(compgen -W "--tty -p" -- "${cur}"))
                return
            fi
            local containers=$(_mtui_containers)
            COMPREPLY=($(compgen -W "$containers" -- "${cur}"))
            return
            ;;
        stop|clean)
            if [[ "$cur" == -* ]]; then
                return
            fi
            local containers=$(_mtui_containers)
            COMPREPLY=($(compgen -W "$containers" -- "${cur}"))
            return
            ;;
        ls|list|status)
            if [[ "$cur" == -* ]]; then
                return
            fi
            local containers=$(_mtui_containers)
            COMPREPLY=($(compgen -W "$containers" -- "${cur}"))
            return
            ;;
        update)
            if [[ "$cur" == -* ]]; then
                COMPREPLY=($(compgen -W "--continue" -- "${cur}"))
                return
            fi
            ;;
    esac
}

complete -F _mtui mtui
complete -F _mtui ./mtui
complete -F _mtui $PWD/mtui