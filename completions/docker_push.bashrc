# Bash completion for docker_push and docker_tool
# This file is sourced by ~/.bashrc via install.sh

_docker_push_images() {
    docker images --format '{{.Repository}}:{{.Tag}}' 2>/dev/null | grep -v '<none>'
}

_docker_push_complete() {
    local cur prev
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    case "${prev}" in
    -m)
        COMPREPLY=($(compgen -W "aws ghcr scp" -- "${cur}"))
        return
        ;;
    -i)
        local images
        images="$(_docker_push_images)"
        COMPREPLY=($(compgen -W "${images}" -- "${cur}"))
        return
        ;;
    -R)
        COMPREPLY=($(compgen -W "us-east-1 us-west-2 ap-southeast-1 ap-northeast-1 eu-west-1 eu-central-1" -- "${cur}"))
        return
        ;;
    -H)
        COMPREPLY=($(compgen -A hostname -- "${cur}"))
        return
        ;;
    -K)
        COMPREPLY=($(compgen -f -- "${cur}"))
        return
        ;;
    -p)
        COMPREPLY=($(compgen -d -- "${cur}"))
        return
        ;;
    esac

    # Suggest flags if start with -
    if [[ "${cur}" == -* ]]; then
        COMPREPLY=($(compgen -W "-m -i -R -A -S -g -k -H -U -p -P -K -h" -- "${cur}"))
        return
    fi
}

_docker_tool_complete() {
    local cur prev
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    case "${prev}" in
    -t)
        COMPREPLY=($(compgen -W "latest" -- "${cur}"))
        return
        ;;
    -f|-o)
        COMPREPLY=($(compgen -f -- "${cur}"))
        return
        ;;
    esac

    if [[ "${cur}" == -* ]]; then
        COMPREPLY=($(compgen -W "-i -t -o -f -u -h" -- "${cur}"))
        return
    fi
}

complete -F _docker_push_complete docker_push
complete -F _docker_tool_complete docker_tool
