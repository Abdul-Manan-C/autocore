#!/bin/bash
# ============================================================
#  Tool    : AUTOCORE — Installer
#  Author  : Ch Manan (OBLIQ_CORE)
#  Handle  : cynex
#  GitHub  : https://github.com/Abdul-Manan-C
#  Version : 1.0
# ============================================================

RED='\033[0;31m'; CYAN='\033[0;36m'; GREEN='\033[0;32m'
YELLOW='\033[1;33m'; WHITE='\033[1;37m'; DIM='\033[2m'; RESET='\033[0m'; BOLD='\033[1m'

echo -e "${RED}"
cat << 'EOF'
  ▄▄▄       █    ██ ▄▄▄█████▓ ▒█████   ▄████▄   ▒█████   ██▀███  ▓█████
 ▒████▄     ██  ▓██▒▓  ██▒ ▓▒▒██▒  ██▒▒██▀ ▀█  ▒██▒  ██▒▓██ ▒ ██▒▓█   ▀
 ▒██  ▀█▄  ▓██  ▒██░▒ ▓██░ ▒░▒██░  ██▒▒▓█    ▄ ▒██░  ██▒▓██ ░▄█ ▒▒███
 ░██▄▄▄▄██ ▓▓█  ░██░░ ▓██▓ ░ ▒██   ██░▒▓▓▄ ▄██▒▒██   ██░▒██▀▀█▄  ▒▓█  ▄
  ▓█   ▓██▒▒▒█████▓   ▒██▒ ░ ░ ████▓▒░▒ ▓███▀ ░░ ████▓▒░░██▓ ▒██▒░▒████▒
EOF
echo -e "${RESET}"
echo -e "${CYAN}${BOLD}         [ AUTOCORE INSTALLER v1.0 ]${RESET}"
echo -e "${DIM}         github.com/Abdul-Manan-C${RESET}\n"

ok()   { echo -e "  ${GREEN}✔${RESET}  $1"; }
warn() { echo -e "  ${YELLOW}!${RESET}  $1"; }
err()  { echo -e "  ${RED}✘${RESET}  $1"; }
info() { echo -e "  ${CYAN}→${RESET}  $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ─── OS Detection ─────────────────────────────────────────
detect_os() {
    # Termux detection
    if [[ -d "/data/data/com.termux" ]] || [[ -n "$PREFIX" && "$PREFIX" == *"termux"* ]]; then
        echo "termux"
        return
    fi

    # NetHunter detection
    if [[ -f "/etc/nethunter-release" ]] || [[ -d "/data/data/com.offsec.nethunter" ]] || \
       (command -v nh &>/dev/null) || [[ -f "/etc/kali-release" && -n "$ANDROID_ROOT" ]]; then
        echo "nethunter"
        return
    fi

    # Linux distro detection
    if [[ -f "/etc/os-release" ]]; then
        . /etc/os-release
        case "${ID,,}" in
            kali)             echo "kali" ;;
            fedora)           echo "fedora" ;;
            arch|manjaro|endeavouros) echo "arch" ;;
            blackarch)        echo "arch" ;;
            ubuntu|debian|linuxmint|parrot|kali) echo "debian" ;;
            *)
                # Fallback via ID_LIKE
                case "${ID_LIKE,,}" in
                    *debian*|*ubuntu*) echo "debian" ;;
                    *arch*)            echo "arch" ;;
                    *fedora*|*rhel*)   echo "fedora" ;;
                    *)                 echo "unknown" ;;
                esac ;;
        esac
        return
    fi

    echo "unknown"
}

OS=$(detect_os)
info "Detected OS: ${WHITE}${BOLD}${OS}${RESET}"

# ─── Select source file ───────────────────────────────────
case "$OS" in
    kali)       SRC="autocore-kali.sh";       INSTALL_PATH="/usr/local/bin/autocore" ;;
    fedora)     SRC="autocore-fedora.sh";     INSTALL_PATH="/usr/local/bin/autocore" ;;
    arch)       SRC="autocore-arch.sh";       INSTALL_PATH="/usr/local/bin/autocore" ;;
    debian)     SRC="autocore-debian.sh";     INSTALL_PATH="/usr/local/bin/autocore" ;;
    termux)     SRC="autocore-termux.sh";     INSTALL_PATH="$PREFIX/bin/autocore" ;;
    nethunter)  SRC="autocore-nethunter.sh";  INSTALL_PATH="$PREFIX/bin/autocore" ;;
    *)
        warn "Unknown OS. Trying generic Debian version..."
        SRC="autocore-debian.sh"
        INSTALL_PATH="/usr/local/bin/autocore"
        ;;
esac

# ─── Check source exists ──────────────────────────────────
if [[ ! -f "$SCRIPT_DIR/$SRC" ]]; then
    err "Source file not found: $SCRIPT_DIR/$SRC"
    err "Make sure all autocore-*.sh files are in the same directory as installer.sh"
    exit 1
fi

ok "Using: $SRC"
info "Installing to: $INSTALL_PATH"

# ─── Install ──────────────────────────────────────────────
if [[ "$OS" == "termux" || "$OS" == "nethunter" ]]; then
    cp "$SCRIPT_DIR/$SRC" "$INSTALL_PATH"
    chmod +x "$INSTALL_PATH"
else
    sudo cp "$SCRIPT_DIR/$SRC" "$INSTALL_PATH"
    sudo chmod +x "$INSTALL_PATH"
fi

if [[ $? -eq 0 ]]; then
    ok "Installed successfully to $INSTALL_PATH"
else
    err "Installation failed. Try running with sudo."
    exit 1
fi

# ─── Run setup for mobile platforms ───────────────────────
if [[ "$OS" == "termux" || "$OS" == "nethunter" ]]; then
    echo ""
    warn "Mobile platform detected — running --setup to install tools and wordlists..."
    sleep 1
    autocore --setup
fi

# ─── Success ──────────────────────────────────────────────
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════╗${RESET}"
echo -e "${GREEN}║${RESET}  ${GREEN}✔${RESET}  ${WHITE}${BOLD}AUTOCORE INSTALLED SUCCESSFULLY${RESET}"
echo -e "${GREEN}╠══════════════════════════════════════════════════════╣${RESET}"
echo -e "${GREEN}║${RESET}  ${DIM}Version  : $OS (${SRC})${RESET}"
echo -e "${GREEN}║${RESET}  ${DIM}Location : $INSTALL_PATH${RESET}"
echo -e "${GREEN}╠══════════════════════════════════════════════════════╣${RESET}"
echo -e "${GREEN}║${RESET}  ${WHITE}Usage:${RESET}"
echo -e "${GREEN}║${RESET}  ${DIM}  autocore <IP>${RESET}"
echo -e "${GREEN}║${RESET}  ${DIM}  autocore <IP> --web${RESET}"
echo -e "${GREEN}║${RESET}  ${DIM}  autocore <IP> --stealth${RESET}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════╝${RESET}"
echo ""
echo -e "  ${CYAN}Author: Ch Manan (OBLIQ_CORE) — github.com/Abdul-Manan-C${RESET}"
