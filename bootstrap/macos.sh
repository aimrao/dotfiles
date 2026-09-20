#!/usr/bin/env bash

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

log() {
    printf '\n\033[1;36m==> %s\033[0m\n' "$1"
}

# ---------------------------------------------------------------
# Verify macOS
# ---------------------------------------------------------------

if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "This script is only for macOS."
    exit 1
fi

# ---------------------------------------------------------------
# Homebrew
# ---------------------------------------------------------------

log "Installing Homebrew"

if ! command -v brew >/dev/null 2>&1; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Make brew available in the current shell.
if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

# ---------------------------------------------------------------
# Packages
# ---------------------------------------------------------------

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

# ---------------------------------------------------------------
# Fonts
# ---------------------------------------------------------------

log "Installing JetBrains Mono Nerd Font"

brew install --cask font-jetbrains-mono-nerd-font

# ---------------------------------------------------------------
# Git LFS
# ---------------------------------------------------------------

log "Initializing Git LFS"

git lfs install

# ---------------------------------------------------------------
# Zsh plugins
# ---------------------------------------------------------------

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

# ---------------------------------------------------------------
# SSH directory
# ---------------------------------------------------------------

log "Preparing SSH"

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

# ---------------------------------------------------------------
# AI workspace
# ---------------------------------------------------------------

log "Preparing AI workspace"

mkdir -p "$HOME/AI/models"
mkdir -p "$HOME/AI/bin"
mkdir -p "$HOME/src"

# ---------------------------------------------------------------
# Dotfiles
# ---------------------------------------------------------------

log "Installing dotfiles"

"$DOTFILES/install.sh"

# ---------------------------------------------------------------
# Default shell
# ---------------------------------------------------------------

log "Configuring Zsh as default shell"

ZSH_PATH="$(command -v zsh)"

if [[ "$SHELL" != "$ZSH_PATH" ]]; then
    if ! grep -qx "$ZSH_PATH" /etc/shells; then
        echo "$ZSH_PATH" | sudo tee -a /etc/shells >/dev/null
    fi

    chsh -s "$ZSH_PATH"
fi

# ---------------------------------------------------------------
# Verification
# ---------------------------------------------------------------

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
echo "=============================================="
echo "macOS bootstrap completed successfully."
echo "=============================================="
echo
echo "Log out/in or start a new terminal if this is"
echo "the first time Zsh has been configured."
