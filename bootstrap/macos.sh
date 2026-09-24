#!/usr/bin/env bash

set -euo pipefail

# -------------------------------------------------------------------
# Paths
# -------------------------------------------------------------------

# bootstrap/macos.sh -> bootstrap/ -> dotfiles/
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

# Make user-installed commands available during this script.
export PATH="$HOME/.local/bin:$PATH"

# -------------------------------------------------------------------
# Helpers
# -------------------------------------------------------------------

log() {
    printf '\n\033[1;36m==> %s\033[0m\n' "$1"
}

link_from_dotfiles() {
    local source="$1"
    local target="$2"

    if [[ ! -e "$source" ]]; then
        echo "Missing dotfiles source: $source"
        exit 1
    fi

    mkdir -p "$(dirname "$target")"

    if [[ -L "$target" ]]; then
        local current
        current="$(readlink "$target")"

        if [[ "$current" == "$source" ]]; then
            echo "OK      $target"
            return
        fi

        rm -f "$target"

    elif [[ -e "$target" ]]; then
        local backup
        backup="${target}.backup.$(date +%Y%m%d-%H%M%S)"
        echo "BACKUP  $target -> $backup"
        mv "$target" "$backup"
    fi

    ln -s "$source" "$target"
    echo "LINK    $target -> $source"
}

# -------------------------------------------------------------------
# Verify macOS
# -------------------------------------------------------------------

if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "This script is only for macOS."
    exit 1
fi

# -------------------------------------------------------------------
# Homebrew
# -------------------------------------------------------------------

log "Installing Homebrew"

if ! command -v brew >/dev/null 2>&1; then
    /bin/bash -c \
        "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Make brew available in the current shell.
if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

# -------------------------------------------------------------------
# Packages
# -------------------------------------------------------------------

log "Installing command-line tools"

brew update

brew install \
    git \
    git-lfs \
    curl \
    wget \
    openssh \
    zsh \
    tmux \
    fzf \
    zoxide \
    direnv \
    ripgrep \
    fd \
    bat \
    eza \
    jq \
    yq \
    tree \
    shellcheck \
    neovim \
    starship \
    alacritty \
    go \
    python \
    cmake \
    ninja \
    gcc \
    pkg-config \
    uv

# -------------------------------------------------------------------
# Fonts
# -------------------------------------------------------------------

log "Installing JetBrains Mono Nerd Font"

brew install --cask font-jetbrains-mono-nerd-font

# -------------------------------------------------------------------
# Git LFS
# -------------------------------------------------------------------

log "Initializing Git LFS"

git lfs install

# -------------------------------------------------------------------
# Zsh plugins
# -------------------------------------------------------------------

log "Installing Zsh plugins"

mkdir -p "$HOME/.zsh"

if [[ ! -d "$HOME/.zsh/zsh-autosuggestions" ]]; then
    git clone \
        https://github.com/zsh-users/zsh-autosuggestions.git \
        "$HOME/.zsh/zsh-autosuggestions"
fi

if [[ ! -d "$HOME/.zsh/zsh-syntax-highlighting" ]]; then
    git clone \
        https://github.com/zsh-users/zsh-syntax-highlighting.git \
        "$HOME/.zsh/zsh-syntax-highlighting"
fi

# -------------------------------------------------------------------
# SSH
# -------------------------------------------------------------------

log "Preparing SSH"

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

# -------------------------------------------------------------------
# AI workspace
# -------------------------------------------------------------------

log "Preparing AI workspace"

mkdir -p "$HOME/AI/models"
mkdir -p "$HOME/AI/bin"
mkdir -p "$HOME/src"
mkdir -p "$HOME/.local/bin"

# -------------------------------------------------------------------
# Dotfiles
# -------------------------------------------------------------------

log "Installing dotfiles"

# Shell
link_from_dotfiles \
    "$DOTFILES/zsh/.zshrc" \
    "$HOME/.zshrc"

link_from_dotfiles \
    "$DOTFILES/tmux/.tmux.conf" \
    "$HOME/.tmux.conf"

# Terminal
link_from_dotfiles \
    "$DOTFILES/starship/starship.toml" \
    "$HOME/.config/starship.toml"

link_from_dotfiles \
    "$DOTFILES/alacritty/alacritty.toml" \
    "$HOME/.config/alacritty/alacritty.toml"

# Neovim
link_from_dotfiles \
    "$DOTFILES/nvim" \
    "$HOME/.config/nvim"

# Local AI scripts
if [[ -f "$DOTFILES/scripts/ai-start" ]]; then
    link_from_dotfiles \
        "$DOTFILES/scripts/ai-start" \
        "$HOME/.local/bin/ai-start"
fi

if [[ -f "$DOTFILES/scripts/ai-stop" ]]; then
    link_from_dotfiles \
        "$DOTFILES/scripts/ai-stop" \
        "$HOME/.local/bin/ai-stop"
fi

if [[ -f "$DOTFILES/scripts/claude-local" ]]; then
    link_from_dotfiles \
        "$DOTFILES/scripts/claude-local" \
        "$HOME/.local/bin/claude-local"
fi

# -------------------------------------------------------------------
# Default shell
# -------------------------------------------------------------------

log "Configuring Zsh as default shell"

ZSH_PATH="$(command -v zsh)"

if [[ "$SHELL" != "$ZSH_PATH" ]]; then
    if ! grep -qx "$ZSH_PATH" /etc/shells; then
        echo "$ZSH_PATH" | sudo tee -a /etc/shells >/dev/null
    fi

    chsh -s "$ZSH_PATH"
fi

# -------------------------------------------------------------------
# Verification
# -------------------------------------------------------------------

log "Running verification"

echo
echo "Versions:"
echo "---------"

printf "macOS:      "
sw_vers -productVersion

printf "Homebrew:   "
brew --version | head -n1

printf "Git:        "
git --version

printf "Zsh:        "
zsh --version

printf "tmux:       "
tmux -V

printf "Neovim:     "
nvim --version | head -n1

printf "Alacritty:  "
alacritty --version | head -n1

printf "Starship:   "
starship --version | head -n1

printf "fzf:        "
fzf --version | head -n1

printf "zoxide:     "
zoxide --version

printf "Go:         "
go version

printf "Python:     "
python3 --version

echo
echo "Dotfile links:"
echo "-------------"

for target in \
    "$HOME/.zshrc" \
    "$HOME/.tmux.conf" \
    "$HOME/.config/starship.toml" \
    "$HOME/.config/alacritty/alacritty.toml" \
    "$HOME/.config/nvim" \
    "$HOME/.local/bin/ai-start" \
    "$HOME/.local/bin/ai-stop" \
    "$HOME/.local/bin/claude-local"; do
    if [[ -L "$target" ]]; then
        printf "OK  %-40s -> %s\n" \
            "$target" \
            "$(readlink "$target")"
    elif [[ -e "$target" ]]; then
        printf "SKIP %-40s (exists, not a symlink)\n" "$target"
    else
        printf "SKIP %-40s (not present)\n" "$target"
    fi
done

echo
echo "=============================================="
echo "macOS bootstrap completed successfully."
echo "=============================================="
echo
echo "Log out/in or start a new terminal if this is"
echo "the first time Zsh has been configured."
echo
