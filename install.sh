#!/usr/bin/env bash

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

link() {
    local source="$1"
    local target="$2"

    mkdir -p "$(dirname "$target")"

    if [[ -L "$target" ]]; then
        local current
        current="$(readlink -f "$target" 2>/dev/null || true)"

        if [[ "$current" == "$source" ]]; then
            echo "OK      $target"
            return
        fi

        rm "$target"

    elif [[ -e "$target" ]]; then
        local backup="${target}.backup.$(date +%Y%m%d%H%M%S)"
        echo "BACKUP  $target -> $backup"
        mv "$target" "$backup"
    fi

    ln -s "$source" "$target"
    echo "LINK    $target -> $source"
}

echo "Installing dotfiles from:"
echo "  $DOTFILES"
echo

# Shell
link "$DOTFILES/zsh/.zshrc" \
     "$HOME/.zshrc"

link "$DOTFILES/tmux/.tmux.conf" \
     "$HOME/.tmux.conf"

# Terminal
link "$DOTFILES/starship/starship.toml" \
     "$HOME/.config/starship.toml"

link "$DOTFILES/alacritty/alacritty.toml" \
     "$HOME/.config/alacritty/alacritty.toml"

# Neovim
link "$DOTFILES/nvim" \
     "$HOME/.config/nvim"

# Scripts
mkdir -p "$HOME/.local/bin"
mkdir -p "$HOME/AI/bin"

link "$DOTFILES/scripts/dolby51-pipewire.sh" \
     "$HOME/.local/bin/dolby51-pipewire.sh"

link "$DOTFILES/scripts/ai-start" \
     "$HOME/AI/bin/ai-start"

link "$DOTFILES/scripts/ai-stop" \
     "$HOME/AI/bin/ai-stop"

# User systemd services
link "$DOTFILES/systemd/user/dolby51.service" \
     "$HOME/.config/systemd/user/dolby51.service"

systemctl --user daemon-reload

echo
echo "Dotfiles installed successfully."
echo
echo "Restart your shell or run:"
echo "  exec zsh"
