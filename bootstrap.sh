#!/usr/bin/env bash

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() {
    printf '\n\033[1;36m==> %s\033[0m\n' "$1"
}

run_as_user() {
    sudo -u "$USER" "$@"
}

# -------------------------------------------------------------------
# Safety
# -------------------------------------------------------------------

if [[ "$EUID" -eq 0 ]]; then
    echo "Do not run bootstrap.sh as root."
    echo "Run it as your normal user."
    exit 1
fi

if ! command -v dnf >/dev/null 2>&1; then
    echo "This bootstrap script expects Fedora with dnf."
    exit 1
fi

# -------------------------------------------------------------------
# System update
# -------------------------------------------------------------------

log "Updating Fedora"

sudo dnf upgrade -y

# -------------------------------------------------------------------
# RPM Fusion
# -------------------------------------------------------------------

log "Installing RPM Fusion"

if ! rpm -q rpmfusion-free-release >/dev/null 2>&1; then
    sudo dnf install -y \
        https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
fi

if ! rpm -q rpmfusion-nonfree-release >/dev/null 2>&1; then
    sudo dnf install -y \
        https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
fi

sudo dnf makecache

# -------------------------------------------------------------------
# Core packages
# -------------------------------------------------------------------

log "Installing core development and workstation packages"

sudo dnf install -y \
    git \
    curl \
    wget \
    ca-certificates \
    openssh-clients \
    zsh \
    tmux \
    fzf \
    zoxide \
    direnv \
    ripgrep \
    fd-find \
    bat \
    eza \
    jq \
    yq \
    tree \
    unzip \
    zip \
    tar \
    gzip \
    bzip2 \
    xz \
    util-linux-user \
    procps-ng \
    psmisc \
    lsof \
    pciutils \
    usbutils \
    bind-utils \
    traceroute \
    iproute \
    iputils \
    net-tools \
    htop \
    btop \
    shellcheck \
    gcc \
    gcc-c++ \
    make \
    cmake \
    ninja-build \
    pkgconf-pkg-config \
    python3 \
    python3-pip \
    python3-devel \
    golang \
    neovim \
    alacritty \
    fontconfig \
    podman \
    podman-compose \
    git-lfs

# -------------------------------------------------------------------
# AMD / Vulkan
# -------------------------------------------------------------------

log "Installing AMD/Vulkan userspace and development packages"

sudo dnf install -y \
    mesa-dri-drivers \
    mesa-vulkan-drivers \
    vulkan-loader \
    vulkan-loader-devel \
    vulkan-tools \
    vulkan-headers \
    glslc

# -------------------------------------------------------------------
# Multimedia
# -------------------------------------------------------------------

log "Installing multimedia / audio packages"

sudo dnf install -y \
    ffmpeg \
    libavcodec-freeworld \
    alsa-utils \
    alsa-plugins \
    alsa-plugins-a52 \
    pipewire \
    pipewire-alsa \
    pipewire-pulseaudio \
    wireplumber

# -------------------------------------------------------------------
# Flatpak / Flathub
# -------------------------------------------------------------------

log "Setting up Flatpak / Flathub"

sudo dnf install -y flatpak

if ! flatpak remote-list | awk '{print $1}' | grep -qx flathub; then
    flatpak remote-add --if-not-exists \
        flathub \
        https://dl.flathub.org/repo/flathub.flatpakrepo
fi

# -------------------------------------------------------------------
# Desktop applications
# -------------------------------------------------------------------

log "Installing desktop applications"

flatpak install -y flathub \
    com.github.wwmm.easyeffects \
    com.discordapp.Discord

# -------------------------------------------------------------------
# Starship
# -------------------------------------------------------------------

log "Installing Starship"

if ! command -v starship >/dev/null 2>&1; then
    curl -sS https://starship.rs/install.sh | sh -s -- -y
fi

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
# JetBrains Mono Nerd Font
# -------------------------------------------------------------------

log "Installing JetBrains Mono Nerd Font"

FONT_DIR="$HOME/.local/share/fonts/JetBrainsMono"

mkdir -p "$FONT_DIR"

if ! fc-list | grep -qi "JetBrainsMono Nerd Font"; then
    TMP_DIR="$(mktemp -d)"

    curl -L \
        -o "$TMP_DIR/JetBrainsMono.zip" \
        https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip

    unzip -qo "$TMP_DIR/JetBrainsMono.zip" -d "$FONT_DIR"

    rm -rf "$TMP_DIR"

    fc-cache -f
fi

# -------------------------------------------------------------------
# SSH directory
# -------------------------------------------------------------------

log "Preparing SSH"

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

# -------------------------------------------------------------------
# Local AI source tree
# -------------------------------------------------------------------

log "Preparing local AI workspace"

mkdir -p "$HOME/AI/models"
mkdir -p "$HOME/AI/bin"
mkdir -p "$HOME/src"

# -------------------------------------------------------------------
# llama.cpp
# -------------------------------------------------------------------

log "Installing/building llama.cpp"

LLAMA_DIR="$HOME/src/llama.cpp"

if [[ ! -d "$LLAMA_DIR/.git" ]]; then
    git clone https://github.com/ggml-org/llama.cpp.git "$LLAMA_DIR"
else
    git -C "$LLAMA_DIR" pull --ff-only
fi

cmake -S "$LLAMA_DIR" -B "$LLAMA_DIR/build" \
    -DCMAKE_BUILD_TYPE=Release \
    -DGGML_VULKAN=ON

cmake --build "$LLAMA_DIR/build" \
    --config Release \
    --target llama-cli llama-server llama-bench \
    -j"$(nproc)"

# -------------------------------------------------------------------
# llama.cpp convenience symlinks
# -------------------------------------------------------------------

log "Installing llama.cpp convenience commands"

mkdir -p "$HOME/.local/bin"

ln -sfn \
    "$LLAMA_DIR/build/bin/llama-cli" \
    "$HOME/.local/bin/llama-cli"

ln -sfn \
    "$LLAMA_DIR/build/bin/llama-server" \
    "$HOME/.local/bin/llama-server"

ln -sfn \
    "$LLAMA_DIR/build/bin/llama-bench" \
    "$HOME/.local/bin/llama-bench"

# -------------------------------------------------------------------
# Default shell
# -------------------------------------------------------------------

log "Configuring Zsh as the default shell"

ZSH_PATH="$(command -v zsh)"

if [[ "$SHELL" != "$ZSH_PATH" ]]; then
    if ! grep -qx "$ZSH_PATH" /etc/shells; then
        echo "$ZSH_PATH" | sudo tee -a /etc/shells >/dev/null
    fi

    chsh -s "$ZSH_PATH"
fi

# -------------------------------------------------------------------
# Git LFS
# -------------------------------------------------------------------

log "Initializing Git LFS"

git lfs install

# -------------------------------------------------------------------
# Dotfiles
# -------------------------------------------------------------------

log "Installing dotfiles"

"$DOTFILES/install.sh"

# -------------------------------------------------------------------
# User services
# -------------------------------------------------------------------

log "Reloading user systemd"

systemctl --user daemon-reload

if [[ -f "$HOME/.config/systemd/user/dolby51.service" ]]; then
    systemctl --user enable dolby51.service
fi

# -------------------------------------------------------------------
# Verification
# -------------------------------------------------------------------

log "Running verification"

echo
echo "Versions:"
echo "---------"

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

printf "Podman:     "
podman --version

printf "llama.cpp:  "
"$HOME/.local/bin/llama-cli" --version 2>/dev/null || true

echo
echo "Vulkan devices:"
"$HOME/.local/bin/llama-cli" --list-devices 2>/dev/null || true

echo
echo "=============================================="
echo "Bootstrap completed successfully."
echo "=============================================="
echo
echo "Next steps:"
echo
echo "  1. Log out/in so the new default shell is active."
echo "  2. Start a new terminal."
echo "  3. Verify:"
echo "       echo \$SHELL"
echo "       llama-cli --list-devices"
echo "       nvim --version"
echo "       podman --version"
echo
echo "LLM models are intentionally NOT downloaded."
echo "Place them under:"
echo "  $HOME/AI/models"
echo
