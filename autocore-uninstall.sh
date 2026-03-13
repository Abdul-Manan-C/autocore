#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
#  AUTOCORE — Uninstaller (AUTOCORE files only, no system tools)
#  Author  : Ch Manan (OBLIQ_CORE) | cynex
#  GitHub  : https://github.com/Abdul-Manan-C
# ╚══════════════════════════════════════════════════════════════════╝

R='\033[0;31m' G='\033[0;32m' Y='\033[1;33m' C='\033[0;36m'
W='\033[1;37m' D='\033[2m' RESET='\033[0m' BOLD='\033[1m'

ok()   { echo -e "  ${G}✔${RESET}  $1"; }
warn() { echo -e "  ${Y}!${RESET}  $1"; }
info() { echo -e "  ${C}→${RESET}  $1"; }
skip() { echo -e "  ${D}–  $1 (not found)${RESET}"; }

echo -e "\n${R}${BOLD}"
echo "  ╔══════════════════════════════════════════════════════╗"
echo "  ║        AUTOCORE — Uninstaller                        ║"
echo "  ║        Removes AUTOCORE only — no system tools       ║"
echo "  ╚══════════════════════════════════════════════════════╝"
echo -e "${RESET}"

read -rp "  $(echo -e "${Y}Continue? [y/N]: ${RESET}")" CONFIRM
[[ "${CONFIRM,,}" != "y" ]] && echo -e "\n  ${D}Cancelled.${RESET}\n" && exit 0
echo ""

# 1. Binary from PATH
for BIN in /usr/local/bin/autocore /usr/bin/autocore; do
    [[ -f "$BIN" ]] && sudo rm -f "$BIN" && ok "Removed $BIN" || skip "$BIN"
done

# Termux/NetHunter
[[ -n "$PREFIX" && -f "$PREFIX/bin/autocore" ]] && \
    rm -f "$PREFIX/bin/autocore" && ok "Removed $PREFIX/bin/autocore" || skip "Termux bin"

# 2. Script files in common locations
for F in \
    ~/autocore.sh \
    ~/AutoPwn/AutoCore/autocore.sh \
    ~/AutoPwn/AutoCore/autocore-kali.sh \
    ~/AutoPwn/AutoCore/autocore-termux.sh \
    ~/AutoPwn/AutoCore/autocore-nethunter.sh \
    ~/AutoPwn/AutoCore/autocore-fedora.sh \
    ~/AutoPwn/AutoCore/autocore-arch.sh \
    ~/AutoPwn/AutoCore/autocore-debian.sh \
    ~/AutoPwn/AutoCore/install-requirements.sh \
    ~/AutoPwn/AutoCore/installer.sh \
    ~/autocore/autocore*.sh \
    ~/autocore/install*.sh; do
    [[ -f "$F" ]] && rm -f "$F" && ok "Removed $F"
done

# 3. Scan sessions (ask)
SESSIONS=($(ls -d autocore_*/ 2>/dev/null) $(ls -d ~/autocore_*/ 2>/dev/null))
if [[ ${#SESSIONS[@]} -gt 0 ]]; then
    echo ""
    info "Found ${#SESSIONS[@]} scan session(s)"
    read -rp "  $(echo -e "${Y}Delete all scan sessions? [y/N]: ${RESET}")" DEL
    [[ "${DEL,,}" == "y" ]] && rm -rf autocore_*/ ~/autocore_*/ && ok "Sessions deleted" || warn "Sessions kept"
fi

echo ""
echo -e "${G}╔══════════════════════════════════════════════════════╗${RESET}"
echo -e "${G}║${RESET}  ${G}✔${RESET}  ${W}${BOLD}AUTOCORE REMOVED CLEANLY${RESET}"
echo -e "${G}║${RESET}  ${D}System tools (nmap, hydra etc) untouched${RESET}"
echo -e "${G}╚══════════════════════════════════════════════════════╝${RESET}"
echo ""
