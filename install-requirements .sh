#!/bin/bash
# ============================================================
#  Tool    : AUTOCORE — Requirements Installer
#  Author  : Ch Manan (OBLIQ_CORE)
#  Handle  : cynex
#  GitHub  : https://github.com/Abdul-Manan-C
#  Version : 1.0
#  Platform: Universal
# ============================================================

RED='\033[0;31m'; CYAN='\033[0;36m'; GREEN='\033[0;32m'
YELLOW='\033[1;33m'; WHITE='\033[1;37m'; DIM='\033[2m'; RESET='\033[0m'; BOLD='\033[1m'

ok()   { echo -e "  ${GREEN}✔${RESET}  $1"; }
warn() { echo -e "  ${YELLOW}!${RESET}  $1"; }
err()  { echo -e "  ${RED}✘${RESET}  $1"; }
info() { echo -e "  ${CYAN}→${RESET}  $1"; }

echo -e "${CYAN}${BOLD}"
echo "  ╔══════════════════════════════════════════════════════╗"
echo "  ║       AUTOCORE — Requirements Installer              ║"
echo "  ╚══════════════════════════════════════════════════════╝"
echo -e "${RESET}"

# ─── Detect OS ────────────────────────────────────────────
detect_os() {
    [[ -d "/data/data/com.termux" || "$PREFIX" == *termux* ]] && echo "termux" && return
    [[ -f "/etc/nethunter-release" || (-f "/etc/kali-release" && -n "$ANDROID_ROOT") ]] && echo "nethunter" && return
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        case "${ID,,}" in
            kali|parrot)                     echo "debian" ;;
            ubuntu|debian|linuxmint)         echo "debian" ;;
            fedora)                          echo "fedora" ;;
            arch|manjaro|endeavouros)        echo "arch" ;;
            *)
                case "${ID_LIKE,,}" in
                    *debian*|*ubuntu*)  echo "debian" ;;
                    *arch*)             echo "arch" ;;
                    *fedora*|*rhel*)    echo "fedora" ;;
                    *)                  echo "unknown" ;;
                esac ;;
        esac
        return
    fi
    echo "unknown"
}

OS=$(detect_os)
info "Detected OS: ${WHITE}${BOLD}${OS}${RESET}"
echo ""

# ─── Install ──────────────────────────────────────────────
case "$OS" in
    debian)
        info "Using apt..."
        sudo apt update -qq
        sudo apt install -y nmap hydra nikto whatweb gobuster curl wget whois dnsutils smbclient enum4linux dirb nano git 2>/dev/null
        command -v nikto &>/dev/null || {
            warn "nikto apt failed — installing via git..."
            sudo git clone https://github.com/sullo/nikto /opt/nikto 2>/dev/null
            sudo ln -sf /opt/nikto/program/nikto.pl /usr/local/bin/nikto
            sudo chmod +x /opt/nikto/program/nikto.pl
        }
        [[ -f /usr/share/wordlists/rockyou.txt.gz && ! -f /usr/share/wordlists/rockyou.txt ]] && \
            sudo gzip -dk /usr/share/wordlists/rockyou.txt.gz && ok "rockyou.txt extracted"
        ;;
    fedora)
        info "Using dnf..."
        sudo dnf install -y nmap hydra nikto curl wget whois bind-utils samba-client nano git gobuster 2>/dev/null
        command -v enum4linux &>/dev/null || {
            warn "Installing enum4linux manually..."
            wget -q https://raw.githubusercontent.com/CiscoCXSecurity/enum4linux/master/enum4linux.pl -O /tmp/enum4linux.pl
            sudo cp /tmp/enum4linux.pl /usr/local/bin/enum4linux && sudo chmod +x /usr/local/bin/enum4linux
        }
        command -v whatweb &>/dev/null || sudo gem install whatweb 2>/dev/null
        ;;
    arch)
        info "Using pacman/yay..."
        PKG="sudo pacman"
        command -v yay &>/dev/null && PKG="yay"
        $PKG -S --noconfirm nmap hydra nikto whatweb gobuster curl wget whois smbclient enum4linux nano git 2>/dev/null
        ;;
    termux|nethunter)
        info "Using pkg..."
        pkg update -y && pkg upgrade -y
        for t in nmap hydra curl wget nikto git nano; do
            command -v "$t" &>/dev/null && ok "$t already installed" || { pkg install -y "$t" 2>/dev/null && ok "$t installed" || warn "Failed: $t"; }
        done
        ;;
    *)
        warn "Unknown OS — trying apt fallback..."
        sudo apt update -qq 2>/dev/null
        sudo apt install -y nmap hydra nikto whatweb gobuster curl wget whois dnsutils smbclient enum4linux dirb nano git 2>/dev/null
        ;;
esac

# ─── Wordlists ────────────────────────────────────────────
echo ""
info "Checking wordlists..."
echo ""

[[ -f /usr/share/wordlists/rockyou.txt || -f $HOME/wordlists/rockyou.txt ]] && ok "rockyou.txt ready" || err "rockyou.txt missing — run: sudo apt install wordlists"
if [[ -f /usr/share/wordlists/dirb/common.txt || -f $HOME/wordlists/common.txt ]]; then
    ok "common.txt ready"
else
    mkdir -p "$HOME/wordlists"
    wget -q "https://raw.githubusercontent.com/v0re/dirb/master/wordlists/common.txt" -O "$HOME/wordlists/common.txt" && ok "common.txt downloaded"
fi
if [[ -f /usr/share/wordlists/metasploit/unix_users.txt || -f $HOME/wordlists/unix_users.txt ]]; then
    ok "unix_users.txt ready"
else
    mkdir -p "$HOME/wordlists"
    printf "root\nadmin\nuser\ntest\nguest\nftp\npi\nwww\n" > "$HOME/wordlists/unix_users.txt" && ok "unix_users.txt created"
fi

# ─── Verify ───────────────────────────────────────────────
echo ""
info "Verifying tools..."
echo ""
for t in nmap hydra nikto whatweb gobuster curl wget whois host nslookup smbclient enum4linux; do
    command -v "$t" &>/dev/null && ok "$t" || warn "$t — NOT found"
done

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════╗${RESET}"
echo -e "${GREEN}║${RESET}  ${GREEN}✔${RESET}  ${WHITE}${BOLD}REQUIREMENTS INSTALL COMPLETE${RESET}"
echo -e "${GREEN}╠══════════════════════════════════════════════════════╣${RESET}"
echo -e "${GREEN}║${RESET}  ${DIM}Run: sudo autocore <TARGET_IP>${RESET}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════╝${RESET}"
echo ""
