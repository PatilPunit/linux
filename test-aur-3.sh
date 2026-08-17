#!/bin/bash

# ==============================
# YAY + AUR PACKAGE INSTALLER
# ==============================

set -o pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAUVE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
BOLD='\033[1m'
RESET='\033[0m'

# ------------------------------
# Validate username argument
# ------------------------------
if [[ $# -ne 1 ]]; then
    echo -e "${RED}${BOLD}[✘]${RESET} Usage: $0 <username>"
    echo -e "${YELLOW}Example:${RESET} $0 pratham"
    exit 1
fi

USERNAME="$1"

if ! id "$USERNAME" &>/dev/null; then
    echo -e "${RED}${BOLD}[✘]${RESET} User '$USERNAME' does not exist."
    exit 1
fi

if [[ "$USERNAME" == "root" ]]; then
    echo -e "${RED}${BOLD}[✘]${RESET} Do not use root as the AUR build user."
    exit 1
fi

HOME_DIR="$(getent passwd "$USERNAME" | cut -d: -f6)"

if [[ -z "$HOME_DIR" || ! -d "$HOME_DIR" ]]; then
    echo -e "${RED}${BOLD}[✘]${RESET} Could not determine home directory for '$USERNAME'."
    exit 1
fi

# ------------------------------
# Helper functions
# ------------------------------
print_header() {
    echo ""
    echo -e "${MAUVE}${BOLD}╔══════════════════════════════════════════════════╗${RESET}"
    echo -e "${MAUVE}${BOLD}║  $1${RESET}"
    echo -e "${MAUVE}${BOLD}╚══════════════════════════════════════════════════╝${RESET}"
    echo ""
}

print_success() {
    echo -e "${GREEN}${BOLD}[✔]${RESET} $1"
}

print_warning() {
    echo -e "${YELLOW}${BOLD}[!]${RESET} $1"
}

print_step() {
    echo -e "${BLUE}${BOLD}[*]${RESET} $1"
}

print_error() {
    echo -e "${RED}${BOLD}[✘]${RESET} $1"
    exit 1
}

command_exists() {
    command -v "$1" &>/dev/null
}

run_as_user() {
    sudo -u "$USERNAME" "$@"
}

# ------------------------------
# One-time sudo authentication
# ------------------------------
authenticate_sudo() {
    print_header "Authenticating sudo"

    print_step "Sudo authentication is required."
    print_step "You should only need to enter your password once."

    if sudo -v; then
        print_success "Sudo authentication successful."
    else
        print_error "Sudo authentication failed."
    fi
}

# ------------------------------
# Keep sudo authentication alive
# ------------------------------
start_sudo_keepalive() {
    print_step "Starting sudo authentication keep-alive..."

    (
        while true; do
            sleep 60

            if ! sudo -n -v 2>/dev/null; then
                exit 1
            fi
        done
    ) &

    SUDO_KEEPALIVE_PID=$!
}

stop_sudo_keepalive() {
    if [[ -n "${SUDO_KEEPALIVE_PID:-}" ]]; then
        kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
        wait "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
    fi
}

# Always stop the keep-alive process when the script exits.
trap stop_sudo_keepalive EXIT

# ------------------------------
# Install prerequisites
# ------------------------------
install_prerequisites() {
    print_header "Installing prerequisites"

    print_step "Installing git and base-devel..."

    if sudo pacman -S --needed --noconfirm git base-devel; then
        print_success "Prerequisites installed."
    else
        print_error "Failed to install prerequisites."
    fi
}

# ------------------------------
# Install yay
# ------------------------------
install_yay() {
    print_header "Step 3 — Installing yay (AUR Helper)"

    if command_exists yay; then
        print_success "yay already installed — skipping."
        return
    fi

    local yay_dir
    yay_dir="$(mktemp -d /tmp/yay-build.XXXXXX)"

    print_step "Cloning yay..."

    if run_as_user git clone https://aur.archlinux.org/yay.git "$yay_dir/yay"; then
        print_success "yay cloned."
    else
        rm -rf "$yay_dir"
        print_error "Failed to clone yay. Check your internet connection."
    fi

    print_step "Building yay..."

    if run_as_user bash -c "cd '$yay_dir/yay' && makepkg -si --noconfirm --needed"; then
        print_success "yay build completed."
    else
        rm -rf "$yay_dir"
        print_error "Failed to build yay."
    fi

    rm -rf "$yay_dir"

    if command_exists yay; then
        print_success "Verified: yay is available."
    else
        print_error "yay installation completed, but the yay command was not found."
    fi
}

# ------------------------------
# Install AUR packages
# ------------------------------
install_aur() {
    local packages=("$@")

    for pkg in "${packages[@]}"; do
        print_step "Installing from AUR: $pkg"

        if run_as_user yay -S \
            --noconfirm \
            --needed \
            --answerdiff None \
            --answerclean None \
            --answerupgrade None \
            --removemake \
            --pgpfetch \
            --sudoloop \
            "$pkg"; then

            print_success "Installed from AUR: $pkg"
        else
            print_warning "Failed to install from AUR: $pkg — skipping."
        fi
    done
}

# ------------------------------
# Install AUR packages
# ------------------------------
install_aur_packages() {
    print_header "Step 7 — Installing AUR Packages"

    install_aur \
        i3lock-color \
        betterlockscreen \
        catppuccin-gtk-theme-mocha \
        preload \
        unrar \
        lightdm-gtk-greeter-settings \
        gtk-engine-murrine
}

# ------------------------------
# Main
# ------------------------------
main() {
    authenticate_sudo
    start_sudo_keepalive
    install_prerequisites
    install_yay
    install_aur_packages

    print_header "Installation Complete"
    print_success "yay and requested AUR packages have been processed."
}

main "$@"
