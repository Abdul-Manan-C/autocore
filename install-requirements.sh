#!/bin/bash
# ============================================================
#  Tool    : AUTOCORE — Requirements Installer
#  Author  : Ch Manan (OBLIQ_CORE)
#  Handle  : cynex
#  GitHub  : https://github.com/Abdul-Manan-C
#  Version : 2.0 — Universal + Ctrl+C Skip
# ============================================================

RED='\033[0;31m'; CYAN='\033[0;36m'; GREEN='\033[0;32m'
YELLOW='\033[1;33m'; WHITE='\033[1;37m'; DIM='\033[2m'; RESET='\033[0m'; BOLD='\033[1m'

ok()    { echo -e "  ${GREEN}✔${RESET}  $1"; }
warn()  { echo -e "  ${YELLOW}!${RESET}  $1"; }
err()   { echo -e "  ${RED}✘${RESET}  $1"; }
info()  { echo -e "  ${CYAN}→${RESET}  $1"; }
skip()  { echo -e "  ${YELLOW}⏭${RESET}  $1 ${DIM}(skipped)${RESET}"; }

echo -e "${CYAN}${BOLD}"
echo "  ╔══════════════════════════════════════════════════════╗"
echo "  ║       AUTOCORE — Requirements Installer v2.0         ║"
echo "  ║       Press Ctrl+C anytime to skip current step      ║"
echo "  ╚══════════════════════════════════════════════════════╝"
echo -e "${RESET}"

# ─── Ctrl+C skip handler ──────────────────────────────────
SKIP_STEP=false
trap 'SKIP_STEP=true; echo -e "\n  ${YELLOW}⏭  Skipping...${RESET}"' INT

run_step() {
    local LABEL="$1"; shift
    SKIP_STEP=false
    info "$LABEL"
    # run in subshell so Ctrl+C only kills the child
    ( trap 'exit 130' INT; "$@" ) &
    wait $!
    if [[ "$SKIP_STEP" == true ]]; then
        skip "$LABEL"
        SKIP_STEP=false
        return 0
    fi
}

# ─── Detect OS ────────────────────────────────────────────
detect_os() {
    [[ -d "/data/data/com.termux" || "$PREFIX" == *termux* ]] && echo "termux" && return
    [[ -f "/etc/nethunter-release" || ( -f "/etc/kali-release" && -n "$ANDROID_ROOT" ) ]] && echo "nethunter" && return
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        case "${ID,,}" in
            kali|parrot)                      echo "debian" ;;
            ubuntu|debian|linuxmint)          echo "debian" ;;
            fedora)                           echo "fedora" ;;
            arch|manjaro|endeavouros)         echo "arch" ;;
            *)
                case "${ID_LIKE,,}" in
                    *debian*|*ubuntu*)   echo "debian" ;;
                    *arch*)              echo "arch" ;;
                    *fedora*|*rhel*)     echo "fedora" ;;
                    *)                   echo "unknown" ;;
                esac ;;
        esac; return
    fi
    echo "unknown"
}

OS=$(detect_os)
info "Detected OS: ${WHITE}${BOLD}${OS^^}${RESET}"
echo ""

# ─── Install functions per OS ─────────────────────────────
install_debian() {
    run_step "Updating apt..." sudo apt update -qq
    run_step "Installing base tools..." \
        sudo apt install -y nmap hydra nikto whatweb gobuster curl wget whois dnsutils smbclient enum4linux dirb nano git
    # nikto fallback
    if ! command -v nikto &>/dev/null; then
        run_step "nikto apt failed — installing via git..." \
            bash -c 'sudo git clone https://github.com/sullo/nikto /opt/nikto 2>/dev/null && sudo ln -sf /opt/nikto/program/nikto.pl /usr/local/bin/nikto && sudo chmod +x /opt/nikto/program/nikto.pl'
    fi
    # rockyou extract
    if [[ -f /usr/share/wordlists/rockyou.txt.gz && ! -f /usr/share/wordlists/rockyou.txt ]]; then
        run_step "Extracting rockyou.txt..." sudo gzip -dk /usr/share/wordlists/rockyou.txt.gz
    fi
}

install_fedora() {
    run_step "Installing via dnf..." \
        sudo dnf install -y nmap hydra nikto curl wget whois bind-utils samba-client nano git gobuster perl
    if ! command -v enum4linux &>/dev/null; then
        run_step "Installing enum4linux manually..." \
            bash -c 'wget -q https://raw.githubusercontent.com/CiscoCXSecurity/enum4linux/master/enum4linux.pl -O /tmp/enum4linux.pl && sudo cp /tmp/enum4linux.pl /usr/local/bin/enum4linux && sudo chmod +x /usr/local/bin/enum4linux'
    fi
    command -v whatweb &>/dev/null || run_step "Installing whatweb via gem..." sudo gem install whatweb
}

install_arch() {
    local PKG="sudo pacman"
    command -v yay &>/dev/null && PKG="yay"
    run_step "Installing via $PKG..." \
        $PKG -S --noconfirm nmap hydra nikto whatweb gobuster curl wget whois smbclient enum4linux nano git
}

install_termux() {
    run_step "Updating pkg..." pkg update -y
    for t in nmap hydra curl wget nikto git nano; do
        command -v "$t" &>/dev/null && ok "$t already installed" || \
        run_step "Installing $t..." pkg install -y "$t"
    done
}

# ─── Run install ──────────────────────────────────────────
case "$OS" in
    debian)    install_debian ;;
    fedora)    install_fedora ;;
    arch)      install_arch ;;
    termux|nethunter) install_termux ;;
    *)
        warn "Unknown OS — trying apt fallback..."
        run_step "Installing via apt..." \
            sudo apt install -y nmap hydra nikto whatweb gobuster curl wget whois dnsutils smbclient enum4linux dirb nano git
        ;;
esac

# ─── Wordlists ────────────────────────────────────────────
echo ""
info "Checking wordlists..."
echo ""

# rockyou
if [[ -f /usr/share/wordlists/rockyou.txt || -f $HOME/wordlists/rockyou.txt ]]; then
    ok "rockyou.txt ready"
else
    warn "rockyou.txt missing"
    run_step "Installing wordlists package..." sudo apt install -y wordlists 2>/dev/null
    [[ -f /usr/share/wordlists/rockyou.txt.gz ]] && \
        run_step "Extracting rockyou.txt..." sudo gzip -dk /usr/share/wordlists/rockyou.txt.gz
    [[ -f /usr/share/wordlists/rockyou.txt ]] && ok "rockyou.txt ready" || err "rockyou.txt still missing"
fi

# common.txt
if [[ -f /usr/share/wordlists/dirb/common.txt || -f $HOME/wordlists/common.txt ]]; then
    ok "common.txt ready"
else
    mkdir -p "$HOME/wordlists"
    run_step "Downloading common.txt..." \
        wget -q "https://raw.githubusercontent.com/v0re/dirb/master/wordlists/common.txt" -O "$HOME/wordlists/common.txt"
    [[ -f "$HOME/wordlists/common.txt" ]] && ok "common.txt downloaded" || err "common.txt failed"
fi

# unix_users.txt
if [[ -f /usr/share/wordlists/metasploit/unix_users.txt || -f $HOME/wordlists/unix_users.txt ]]; then
    ok "unix_users.txt ready"
else
    mkdir -p "$HOME/wordlists"
    printf "root\nadmin\nuser\ntest\nguest\nftp\npi\nwww\nubuntu\nkali\n" > "$HOME/wordlists/unix_users.txt"
    ok "unix_users.txt created"
fi

# ─── Verify all ───────────────────────────────────────────
echo ""
info "Verifying all tools..."
echo ""

PASS=0; FAIL=0
for t in nmap hydra nikto whatweb gobuster curl wget whois host nslookup smbclient enum4linux; do
    if command -v "$t" &>/dev/null; then
        ok "$t"
        ((PASS++))
    else
        warn "$t — NOT found"
        ((FAIL++))
    fi
done

# ─── Final ────────────────────────────────────────────────
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════╗${RESET}"
echo -e "${GREEN}║${RESET}  ${GREEN}✔${RESET}  ${WHITE}${BOLD}REQUIREMENTS INSTALL COMPLETE${RESET}"
echo -e "${GREEN}╠══════════════════════════════════════════════════════╣${RESET}"
echo -e "${GREEN}║${RESET}  ${DIM}Installed : $PASS tools${RESET}"
echo -e "${GREEN}║${RESET}  ${DIM}Missing   : $FAIL tools${RESET}"
echo -e "${GREEN}╠══════════════════════════════════════════════════════╣${RESET}"
echo -e "${GREEN}║${RESET}  ${DIM}Run: sudo autocore <TARGET_IP>${RESET}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════╝${RESET}"
echo ""

# restore default Ctrl+C
trap - INT
