#!/usr/bin/env bash

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

OS="$(uname -s)"

case "$OS" in
    Linux)
        if [[ -f /etc/fedora-release ]]; then
            exec "$DOTFILES/bootstrap/fedora.sh"
        fi

        echo "Linux detected, but this distribution is not Fedora."
        echo "Currently supported: Fedora and macOS."
        exit 1
        ;;

    Darwin)
        exec "$DOTFILES/bootstrap/macos.sh"
        ;;

    *)
        echo "Unsupported operating system: $OS"
        exit 1
        ;;
esac
