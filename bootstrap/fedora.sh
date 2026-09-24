#!/usr/bin/env bash

set -euo pipefail

# -------------------------------------------------------------------
# Paths
# -------------------------------------------------------------------

# bootstrap/fedora.sh -> bootstrap/ -> dotfiles/
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
        "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm"
fi

if ! rpm -q rpmfusion-nonfree-release >/dev/null 2>&1; then
    sudo dnf install -y \
        "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
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
# AMD / Vulkan / OpenCL
# -------------------------------------------------------------------

log "Installing AMD / Vulkan / OpenCL userspace"

sudo dnf install -y \
    mesa-dri-drivers \
    mesa-vulkan-drivers \
    vulkan-loader \
    vulkan-loader-devel \
    vulkan-tools \
    vulkan-headers \
    glslc \
    libxcrypt-compat \
    rocm-opencl \
    rocm-clinfo

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

    unzip -qo \
        "$TMP_DIR/JetBrainsMono.zip" \
        -d "$FONT_DIR"

    rm -rf "$TMP_DIR"

    fc-cache -f
fi

# -------------------------------------------------------------------
# SSH
# -------------------------------------------------------------------

log "Preparing SSH"

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

# -------------------------------------------------------------------
# Local AI workspace
# -------------------------------------------------------------------

log "Preparing local AI workspace"

mkdir -p "$HOME/AI/models"
mkdir -p "$HOME/AI/bin"
mkdir -p "$HOME/src"
mkdir -p "$HOME/.local/bin"

# -------------------------------------------------------------------
# llama.cpp
# -------------------------------------------------------------------

log "Installing/building llama.cpp"

LLAMA_DIR="$HOME/src/llama.cpp"

if [[ ! -d "$LLAMA_DIR/.git" ]]; then
    git clone \
        https://github.com/ggml-org/llama.cpp.git \
        "$LLAMA_DIR"
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
# Claude Code
# -------------------------------------------------------------------

log "Installing Claude Code"

if ! command -v claude >/dev/null 2>&1; then
    curl -fsSL https://claude.ai/install.sh | bash
fi

hash -r

if ! command -v claude >/dev/null 2>&1; then
    echo "Claude Code installation failed."
    exit 1
fi

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

# -------------------------------------------------------------------
# Local AI / Claude Code
# -------------------------------------------------------------------

log "Installing local AI and Claude Code configuration"

link_from_dotfiles \
    "$DOTFILES/scripts/ai-start" \
    "$HOME/.local/bin/ai-start"

if [[ -f "$DOTFILES/scripts/ai-stop" ]]; then
    link_from_dotfiles \
        "$DOTFILES/scripts/ai-stop" \
        "$HOME/.local/bin/ai-stop"
fi

link_from_dotfiles \
    "$DOTFILES/scripts/claude-local" \
    "$HOME/.local/bin/claude-local"

link_from_dotfiles \
    "$DOTFILES/claude/settings.json" \
    "$HOME/.claude/settings.json"

# -------------------------------------------------------------------
# Fedora-specific scripts
# -------------------------------------------------------------------

log "Installing Fedora-specific scripts"

link_from_dotfiles \
    "$DOTFILES/scripts/dolby51-pipewire.sh" \
    "$HOME/.local/bin/dolby51-pipewire.sh"

# -------------------------------------------------------------------
# User systemd service
# -------------------------------------------------------------------

log "Installing user systemd services"

if [[ -f "$DOTFILES/systemd/user/dolby51.service" ]]; then
    link_from_dotfiles \
        "$DOTFILES/systemd/user/dolby51.service" \
        "$HOME/.config/systemd/user/dolby51.service"
fi

systemctl --user daemon-reload

if [[ -f "$HOME/.config/systemd/user/dolby51.service" ]]; then
    systemctl --user enable dolby51.service
fi

# -------------------------------------------------------------------
# Validate local AI configuration
# -------------------------------------------------------------------

QWEN_TEMPLATE="$DOTFILES/llama/templates/qwen3.6-35b-a3b-claude-code.jinja"

if [[ ! -f "$QWEN_TEMPLATE" ]]; then
    echo "Missing Qwen Claude Code chat template:"
    echo "  $QWEN_TEMPLATE"
    exit 1
fi

chmod +x \
    "$DOTFILES/scripts/ai-start" \
    "$DOTFILES/scripts/claude-local"

if [[ -f "$DOTFILES/scripts/ai-stop" ]]; then
    chmod +x "$DOTFILES/scripts/ai-stop"
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

printf "Claude:     "
claude --version

printf "llama.cpp:  "
llama-cli --version 2>/dev/null || true

echo
echo "Vulkan devices:"
llama-cli --list-devices 2>/dev/null || true

echo
echo "OpenCL devices:"
if command -v clinfo >/dev/null 2>&1; then
    clinfo -l 2>/dev/null || true
else
    echo "clinfo not available"
fi

echo
echo "Dotfile links:"
echo "-------------"

for target in \
    "$HOME/.zshrc" \
    "$HOME/.tmux.conf" \
    "$HOME/.config/starship.toml" \
    "$HOME/.config/alacritty/alacritty.toml" \
    "$HOME/.config/nvim" \
    "$HOME/.claude/settings.json" \
    "$HOME/.local/bin/ai-start" \
    "$HOME/.local/bin/claude-local"; do
    if [[ -L "$target" ]]; then
        printf "OK  %-40s -> %s\n" \
            "$target" \
            "$(readlink "$target")"
    else
        printf "BAD %-40s\n" "$target"
    fi
done

echo
echo "Qwen Claude Code template:"
echo "--------------------------"
echo "  $QWEN_TEMPLATE"

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
echo "       claude --version"
echo "       llama-cli --list-devices"
echo "       clinfo -l"
echo "       nvim --version"
echo "       podman --version"
echo
echo "  4. Start local AI:"
echo "       ai-start"
echo
echo "  5. Test local Claude Code:"
echo "       claude-local -p 'Reply with exactly: LOCAL QWEN OK'"
echo
echo "Models are intentionally not downloaded."
echo "Place GGUF models under:"
echo "  $HOME/AI/models"
echo
echo "DaVinci Resolve is intentionally not installed by this script."
echo "Install Resolve separately."
echo
