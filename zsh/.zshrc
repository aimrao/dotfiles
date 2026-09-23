# ============================================================
# ZSH
# ============================================================

# ------------------------------------------------------------
# Environment
# ------------------------------------------------------------

export EDITOR="nvim"
export VISUAL="nvim"

export PAGER="less"
export LESS="-R"

# ------------------------------------------------------------
# History
# ------------------------------------------------------------

HISTFILE="$HOME/.zsh_history"

HISTSIZE=100000
SAVEHIST=100000

setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt EXTENDED_HISTORY

setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY
setopt HIST_EXPIRE_DUPS_FIRST

# ------------------------------------------------------------
# Zsh behavior
# ------------------------------------------------------------

setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT

setopt EXTENDED_GLOB
setopt NO_BEEP

# ------------------------------------------------------------
# Completion
# ------------------------------------------------------------

autoload -Uz compinit

# Cache completion for faster startup.
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$HOME/.cache/zsh"

compinit

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' list-colors ''
zstyle ':completion:*' rehash true
zstyle ':completion:*' squeeze-slashes true

# ------------------------------------------------------------
# Autosuggestions
# ------------------------------------------------------------

source "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh"

ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# ------------------------------------------------------------
# fzf
# ------------------------------------------------------------

if [[ -f /usr/share/fzf/shell/key-bindings.zsh ]]; then
    source /usr/share/fzf/shell/key-bindings.zsh
fi

if [[ -f /usr/share/fzf/shell/completion.zsh ]]; then
    source /usr/share/fzf/shell/completion.zsh
fi

# ------------------------------------------------------------
# zoxide
# ------------------------------------------------------------

if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh)"
fi

# ------------------------------------------------------------
# direnv
# ------------------------------------------------------------

if command -v direnv >/dev/null 2>&1; then
    eval "$(direnv hook zsh)"
fi

# ------------------------------------------------------------
# Kubernetes completion
# ------------------------------------------------------------

if command -v kubectl >/dev/null 2>&1; then
    source <(kubectl completion zsh)
fi

# ------------------------------------------------------------
# Docker completion
# ------------------------------------------------------------

if command -v docker >/dev/null 2>&1; then
    if docker completion zsh >/dev/null 2>&1; then
        source <(docker completion zsh)
    fi
fi

# ------------------------------------------------------------
# Podman completion
# ------------------------------------------------------------

if command -v podman >/dev/null 2>&1; then
    if podman completion zsh >/dev/null 2>&1; then
        source <(podman completion zsh)
    fi
fi

# ------------------------------------------------------------
# Git aliases
# ------------------------------------------------------------

alias gs='git status'
alias ga='git add'
alias gaa='git add --all'
alias gc='git commit'
alias gca='git commit --amend'
alias gp='git push'
alias gpl='git pull'
alias gf='git fetch'
alias gl='git log --oneline --graph --decorate --all'
alias gd='git diff'
alias gds='git diff --staged'
alias gb='git branch'
alias gba='git branch -a'
alias gco='git checkout'
alias gsw='git switch'

# ------------------------------------------------------------
# Kubernetes aliases
# ------------------------------------------------------------

alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgn='kubectl get nodes'
alias kga='kubectl get all'
alias kl='kubectl logs'
alias kexec='kubectl exec -it'

# ------------------------------------------------------------
# Container aliases
# ------------------------------------------------------------

alias d='docker'
alias dc='docker compose'

alias p='podman'
alias pc='podman compose'

# ------------------------------------------------------------
# Systemd
# ------------------------------------------------------------

alias sc='systemctl'
alias scu='systemctl --user'
alias jctl='journalctl'

# ------------------------------------------------------------
# Networking
# ------------------------------------------------------------

alias ports='ss -tulpn'
alias ipinfo='ip -br addr'

# ------------------------------------------------------------
# Useful aliases
# ------------------------------------------------------------

alias ll='eza -lah --group-directories-first'
alias la='eza -a --group-directories-first'
alias ls='eza --group-directories-first'
alias lt='eza --tree --level=2'

alias cat='bat --paging=never'
alias ccat='/usr/bin/cat'

alias grep='rg'
alias find='fd'

alias vi='nvim'
alias vim='nvim'

# ------------------------------------------------------------
# Functions
# ------------------------------------------------------------

mkcd() {
    mkdir -p "$1" && cd "$1"
}

extract() {
    if [[ ! -f "$1" ]]; then
        echo "File not found: $1"
        return 1
    fi

    case "$1" in
        *.tar.bz2) tar xjf "$1" ;;
        *.tar.gz)  tar xzf "$1" ;;
        *.tar.xz)  tar xJf "$1" ;;
        *.tar)     tar xf "$1" ;;
        *.bz2)     bunzip2 "$1" ;;
        *.gz)      gunzip "$1" ;;
        *.zip)     unzip "$1" ;;
        *.7z)      7z x "$1" ;;
        *.rar)     unrar x "$1" ;;
        *)         echo "Unsupported archive: $1"; return 1 ;;
    esac
}

kctx() {
    kubectl config current-context
}

kuse() {
    kubectl config use-context "$1"
}

# ------------------------------------------------------------
# Starship
# ------------------------------------------------------------

eval "$(starship init zsh)"

# ------------------------------------------------------------
# Automatic tmux
# ------------------------------------------------------------

if [[ -o interactive ]] && [[ -z "${TMUX:-}" ]]; then
    tmux attach-session -t main 2>/dev/null || tmux new-session -s main
fi

# ------------------------------------------------------------
# Syntax highlighting
# MUST be loaded last.
# ------------------------------------------------------------

source "$HOME/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
export PATH="$HOME/.local/bin:$PATH"
