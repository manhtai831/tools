# Zsh completion for docker_push and docker_tool
# This file is sourced by ~/.zshrc via install.sh

_docker_push_images() {
    docker images --format '{{.Repository}}:{{.Tag}}' 2>/dev/null | grep -v '<none>'
}

_docker_push() {
    local context state line
    typeset -A opt_args

    _arguments -s \
        '-m[Push method]:method:(aws ghcr scp)' \
        '-i[Full image reference (name:tag)]:image_ref:->image_ref' \
        '-R[AWS region]:region:(us-east-1 us-west-2 ap-southeast-1 ap-northeast-1 eu-west-1 eu-central-1)' \
        '-A[AWS Access Key ID]:key_id:' \
        '-S[AWS Secret Key]:secret:' \
        '-g[GitHub username]:username:' \
        '-k[GitHub token]:token:' \
        '-H[Remote host]:host:_hosts' \
        '-U[Remote user]:user:_users' \
        '-p[Remote destination path]:path:_files -/' \
        '-P[SSH port]:port:(22 2222)' \
        '-K[SSH private key path]:keyfile:_files' \
        '-h[Show help]'

    case $state in
    image_ref)
        local images
        images=(${(f)"$(_docker_push_images)"})
        _describe 'docker images' images
        ;;
    esac
}

_docker_tool() {
    local context state line
    typeset -A opt_args

    _arguments -s \
        '*-i[Image reference as name:tag (repeatable)]:image_ref:->image_ref' \
        '-o[Docker build context directory]:dir:_files -/' \
        '-f[Dockerfile path]:dockerfile:_files' \
        '-u[Upload image archive to API after saving]' \
        '-U[Upload API URL]:url:' \
        '-h[Show help]'

    case $state in
    image_ref)
        local images
        images=(${(f)"$(_docker_push_images)"})
        _describe 'docker images' images
        ;;
    esac
}

compdef _docker_push docker_push
compdef _docker_tool docker_tool
