


Awesome! I am very glad we got it working cleanly.

However, since you asked—**yes, I did accidentally strip out 3 very important pieces of functionality** from the original `.shell-functions.sh` when I aggressively simplified the code. Good catch.

### What I missed:

1. **CRITICAL: File Permissions Bug in Build:**
   In the original `_build`, we passed `--build-arg HOST_UID="$(id -u)"`. Without this, OpenCode runs inside Docker as `root`, meaning **any file it creates or edits in your project will be owned by `root`**, and you won't be able to edit them on your host machine without `sudo`!
2. **Path Collision Check in Start:**
   If you have two projects named `~/work/my-app` and `~/personal/my-app`, they both generate the container name `mtui-my-app`. The old script checked if the existing container actually belonged to your current folder and warned you. My simplified script just blindly resumed the container, which could drop you into the wrong project's code.
3. **The `--tty` Debug Mode:**
   I dropped the parsing for `mtui start --tty`, which is super useful if you need to drop into the raw Docker container's bash shell to debug something without triggering the AI.

Here are the fixes to put back into your `mtui` script.

### 1. Fix `cmd_setup` and `cmd_build`

Replace your existing `cmd_setup` and `cmd_build` blocks with these to ensure the user ID is passed correctly:

```bash
cmd_setup() {
    _log "Setting up MultiTUI globally in $MTUI_HOME..."

    if [[ -d "docker" && -d "defaults" && "$PWD" != "$MTUI_HOME" ]]; then
        _log "Dev mode detected. Copying $PWD to $MTUI_HOME..."
        mkdir -p "$MTUI_HOME"
        tar -cf - --exclude=.git . | tar -xf - -C "$MTUI_HOME"
    else
        if [[ ! -d "$MTUI_HOME" ]]; then
            _log "Cloning framework..."
            git clone "$REMOTE_REPO" "$MTUI_HOME"
        else
            _log "Updating framework..."
            git -C "$MTUI_HOME" pull
        fi
    fi

    _log "Linking mtui to ~/.local/bin/mtui..."
    mkdir -p "$HOME/.local/bin"
    chmod +x "$MTUI_HOME/mtui"
    ln -sf "$MTUI_HOME/mtui" "$HOME/.local/bin/mtui"

    cmd_build
    echo -e "${C_GREEN}[✔] Setup complete! Run 'mtui' anywhere.${C_RESET}"
}

cmd_build() {
    _log "Building Docker image..."
    docker build \
        --build-arg HOST_UID="$(id -u)" \
        --build-arg HOST_GID="$(id -g)" \
        -f "$MTUI_HOME/docker/Dockerfile" \
        -t multitui "$MTUI_HOME/docker"
    echo -e "${C_GREEN}[✔] Build complete.${C_RESET}"
}
```

### 2. Fix `cmd_start`

Replace your `cmd_start` block with this to restore the path collision safety check, the `--tty` flag, and some missing GitHub environment variables:

```bash
cmd_start() {
    [[ -z "$OPENROUTER_API_KEY" ]] && _err "OPENROUTER_API_KEY not set."
    [[ ! -d "agent" ]] && _err "No agent/ submodule found. Run 'mtui init' first."

    local cn="$(_container_name)"
    local mode="auto"
    local flags=()

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --tty) mode="tty"; shift ;;
            -p|--port) flags+=("-p" "$2"); shift 2 ;;
            *) shift ;;
        esac
    done

    # Path collision and resume check
    if docker ps -aq -f name="^/${cn}$" | grep -q .; then
        local mounted="$(docker inspect "$cn" --format '{{.Config.WorkingDir}}' 2>/dev/null)"
        if [[ "$mounted" != "$PWD" ]]; then
            _err "Container $cn exists but belongs to a different path: $mounted\nRun 'mtui clean' first to remove it."
        fi
        _log "Resuming $cn..."
        exec docker start -ai "$cn"
    fi

    docker images -q multitui | grep -q . || _err "No image. Run 'mtui build' first."
    _log "Starting OpenCode..."

    flags+=(
        -it --name "$cn" --detach-keys="ctrl-z"
        -v "$PWD":"$PWD" -w "$PWD"
        -v "$PWD/agent/config/opencode.json":/home/dev/.config/opencode/opencode.json:ro
        --group-add "$(stat -c '%g' /var/run/docker.sock 2>/dev/null || echo 0)"
        -v /var/run/docker.sock:/var/run/docker.sock
        -v "$HOME/.ssh":/home/dev/.ssh:ro
        -e OPENROUTER_API_KEY -e OPENCODE_DEFAULT_MODEL="$OPENCODE_DEFAULT_MODEL"
        -e GITHUB_TOKEN -e GITHUB_KEY -e GITHUB_USER -e EXA_API_KEY
        -e PROJECT_ROOT="$PWD"
    )

    if [ "$mode" = "tty" ]; then
        exec docker run "${flags[@]}" multitui bash
    else
        exec docker run "${flags[@]}" multitui bash -lc "export PATH='/home/dev/.opencode/bin:\$PATH' && cd '$PWD' && opencode --model \"$OPENCODE_DEFAULT_MODEL\""
    fi
}
```

With these patches applied, the script is 100% at feature-parity with the old `.shell-functions.sh`, but correctly orchestrated as a global CLI tool!
