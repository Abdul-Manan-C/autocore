<div align="center">
 
<img src="https://readme-typing-svg.demolab.com?font=Courier+New&weight=700&size=44&duration=3000&pause=1200&color=FF4444&background=00000000&center=true&vCenter=true&width=700&height=90&lines=AUTOCORE" alt="AUTOCORE" />
 
<img src="https://readme-typing-svg.demolab.com?font=Courier+New&size=14&duration=2500&pause=900&color=58A6FF&center=true&vCenter=true&width=700&lines=Automated+pentest+recon+%26+enumeration+orchestrator;v3.0+Bash+%7C+v4.0+AI-Powered+Python+TUI;Kali+%C2%B7+Fedora+%C2%B7+Arch+%C2%B7+Debian+%C2%B7+Termux+%C2%B7+NetHunter;Auto+OS+detection+%E2%80%94+one+script+rules+all" alt="subtitle" />
 
<br/>
 
![Version](https://img.shields.io/badge/bash-v3.0-ff4444?style=for-the-badge&logo=gnu-bash&logoColor=white)
![Version](https://img.shields.io/badge/python_TUI-v4.0-a371f7?style=for-the-badge&logo=python&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-58a6ff?style=for-the-badge)
![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20Android-3fb950?style=for-the-badge&logo=linux&logoColor=white)
![Use](https://img.shields.io/badge/Use-CTF%20%7C%20TryHackMe%20%7C%20Lab-ffa657?style=for-the-badge)
 
<br/>
 
*By **Ch Manan (OBLIQ_CORE)** · handle: `cynex` · [github.com/Abdul-Manan-C](https://github.com/Abdul-Manan-C)*
 
</div>
 
---
 
## `$ what is autocore?`
 
**AUTOCORE** comes in two flavors — a pure bash orchestrator and a full AI-powered Python TUI:
 
| | `autocore.sh` v3.0 | `autocore_v4.py` v4.0 |
|---|---|---|
| **Type** | Bash script | Python TUI (Textual) |
| **AI** | None — pure logic | Gemini · OpenAI · Ollama |
| **Interface** | Terminal / interactive menu | Full dashboard UI |
| **CVE Lookup** | — | Auto CVE lookup + CVSS scoring |
| **Reports** | `.txt` loot report | `.md` + `.json` reports |
| **Install** | Single script, no deps | `pip install -r requirements.txt` |
 
Both auto-detect your OS and use the correct scan type (`-sS` / `-sT`) automatically.
 
---
 
## `$ autocore --features`
 
### bash v3.0 — phases
 
| Phase | Tools | What happens |
|---|---|---|
| **1 · Recon** | ping · whois · host · nslookup | Target fingerprinting |
| **2 · Nmap** | nmap (5 stages) | Quick → full 65535 → services → vulns → OS |
| **3 · Web** | WhatWeb · Nikto · Gobuster · curl | Dirs · files · headers · robots · sitemap |
| **4 · SMB** | enum4linux · smbclient · nmap NSE | Shares · users · SMB vulns |
| **5 · Brute** | Hydra | SSH · FTP · Telnet · HTTP template |
| **6 · MSF** | Auto-generated notes | Ready-to-paste Metasploit commands |
| **7 · Report** | Custom bash | Open ports · creds · vulns · loot summary |
 
### python v4.0 — extras
 
```
✅  AI Chat           — ask anything about your findings
✅  AI Scan Analysis  — severity rating, attack recommendations
✅  AI Attack Plan    — full exploit plan, copy-paste commands
✅  CVE Lookup        — auto CVSS scoring from live CVE database
✅  TUI Dashboard     — sidebar nav, tabbed interface, live log
✅  Session Manager   — browse, view, and clear past sessions
✅  Tool Installer    — one-click install from TUI
✅  JSON Reports      — machine-readable output per session
✅  Scan Depths 1–5  — from recon-only to full attack mode
```
 
---
 
## `$ autocore --install`
 
### bash v3.0
 
```bash
git clone https://github.com/Abdul-Manan-C/autocore
cd autocore
chmod +x autocore.sh
 
# Install to PATH (auto-detects your OS)
sudo ./autocore.sh --install
 
# Or install tools first
sudo ./autocore.sh --setup
```
 
### python v4.0
 
```bash
git clone https://github.com/Abdul-Manan-C/autocore
cd autocore
pip install -r requirements.txt    # textual rich requests google-generativeai openai
 
python3 autocore_v4.py             # launch TUI
# or install to PATH:
sudo python3 autocore_v4.py --install
```
 
> **Requirements:** `textual` · `rich` · `requests` · `google-generativeai` · `openai`
 
---
 
## `$ autocore --help`
 
### bash v3.0
 
```bash
autocore                    # interactive menu
autocore <IP>               # full scan (all phases)
autocore <IP> --web         # web enumeration only
autocore <IP> --smb         # SMB enumeration only
autocore <IP> --brute       # brute force only
autocore <IP> --quick       # top 1000 ports only
autocore <IP> --stealth     # slow/quiet scan (-T2)
autocore --setup            # install all tools
autocore --install          # add autocore to PATH
autocore --sessions         # list past sessions
autocore --clear            # delete all sessions
```
 
### python v4.0
 
```bash
python3 autocore_v4.py                    # launch full TUI dashboard
python3 autocore_v4.py <IP>              # CLI scan (depth 4)
python3 autocore_v4.py <IP> --depth 1-5  # 1=recon only → 5=full attack
python3 autocore_v4.py <IP> --web        # web phase only
python3 autocore_v4.py <IP> --smb        # SMB phase only
python3 autocore_v4.py <IP> --brute      # brute force only
python3 autocore_v4.py <IP> --quick      # top 1000 ports
python3 autocore_v4.py <IP> --stealth    # slow/quiet
python3 autocore_v4.py --setup           # install all tools
python3 autocore_v4.py --sessions        # list sessions
python3 autocore_v4.py --clear           # delete sessions
python3 autocore_v4.py --uninstall       # remove autocore
```
 
**Scan depths (v4.0):**
```
1 = Recon only          (~1 min)
2 = Port discovery      (~3 min)
3 = Full ports          (~10 min)
4 = Deep enum + AI      (~20 min)   ← default
5 = Full attack mode    (~40 min)
```
 
**Examples:**
```bash
autocore 10.10.10.5
autocore 192.168.1.1 --web
autocore 10.0.0.20 --stealth
python3 autocore_v4.py 10.10.10.5 --depth 5
```
 
---
 
## `$ ls session/`
 
Every scan creates: `autocore_<IP>_<TIMESTAMP>/`
 
```
autocore_10.10.10.5_20260313_120000/
│
├── 📁 nmap/
│   ├── nmap_1_quick.txt          ← top 1000 ports
│   ├── nmap_2_fullports.txt      ← all 65535 ports
│   ├── nmap_3_services.txt       ← service + version detection
│   ├── nmap_4_vulns.txt          ← vuln NSE scripts
│   └── nmap_5_os.txt             ← OS fingerprinting
│
├── 📁 web/
│   ├── gobuster_1_dirs.txt       ← directory brute
│   ├── gobuster_2_files.txt      ← file brute (php, txt, html, js)
│   ├── headers_1.txt             ← HTTP headers
│   ├── robots_1.txt              ← robots.txt
│   └── sitemap_1.txt             ← sitemap.xml
│
├── 📁 nikto/  · 📁 whatweb/  · 📁 smb/  · 📁 hydra/
│
├── 📁 metasploit/
│   └── msf_notes.txt             ← ready-to-paste MSF commands
│
├── 📁 cve/                       ← v4.0 only
│   └── cve_report.json           ← CVE IDs, CVSS scores, severity
│
├── 📁 ai/                        ← v4.0 only
│   ├── ai_analysis.md            ← AI severity + recommendations
│   └── attack_plan.md            ← full exploit plan
│
├── 📁 enum/  · 📁 loot/  · 📁 screenshots/
│
├── 📄 REPORT_10.10.10.5.txt      ← bash v3.0 report
├── 📄 REPORT_10.10.10.5.md       ← v4.0 markdown report
└── 📄 REPORT_10.10.10.5.json     ← v4.0 machine-readable report
```
 
---
 
## `$ cat platform_support.txt`
 
| Platform | Auto-detected | Root | Scan type | SMB | Metasploit |
|---|---|---|---|---|---|
| Kali / Parrot | ✅ | `sudo` | `-sS` | Full | ✅ |
| Fedora | ✅ | `sudo` | `-sS` | Full | ✅ |
| Arch / BlackArch / Manjaro | ✅ | `sudo` | `-sS` | Full | ✅ |
| Debian / Ubuntu / Mint | ✅ | `sudo` | `-sS` | Full | ✅ |
| Termux (Android) | ✅ | None | `-sT` | Partial | Notes only |
| NetHunter Rootless | ✅ | None | `-sT/-sS` | Partial | Notes only |
 
> OS is detected automatically — no need to pick the right script manually.
 
---
 
## `$ cat ai_setup.txt`
 
The v4.0 Python TUI supports three AI backends, auto-detected in this order:
 
```
1. Ollama (local)   → runs automatically if Ollama is on localhost:11434
2. Gemini           → add API key in Settings (AIza...)
3. OpenAI           → add API key in Settings (sk-...)
```
 
Set keys via **TUI → Settings** or edit `~/.autocore/config.json`:
 
```json
{
  "ai_backend": "gemini",
  "gemini_api_key": "AIza...",
  "openai_api_key": "sk-...",
  "ollama_model": "llama3",
  "ollama_url": "http://localhost:11434"
}
```
 
---
 
## `$ cat requirements.txt`
 
```
textual>=0.47.0
rich>=13.0.0
requests>=2.31.0
google-generativeai>=0.5.0
openai>=1.0.0
```
 
**System tools** (installed via `--setup`):
```
nmap  hydra  nikto  whatweb  gobuster  curl  wget  whois  enum4linux  smbclient  subfinder
```
 
---
 
## `$ ./autocore-uninstall.sh`
 
```bash
chmod +x autocore-uninstall.sh
./autocore-uninstall.sh
# removes autocore files only — system tools (nmap, hydra etc) are untouched
```
 
---
 
## `$ cat disclaimer.txt`
 
> [!WARNING]
> **AUTOCORE is intended strictly for ethical and legal use only.**
> Use only on systems you own or have **explicit written permission** to test.
> Authorized platforms: CTF machines (TryHackMe, HackTheBox, VulnHub), personal labs, penetration testing with written consent.
> The author takes **no responsibility** for any misuse of this tool.
> Unauthorized scanning or access to systems is **illegal** and punishable by law.
 
---
 
## `$ whoami`
 
<div align="center">
 
**Ch Manan** · `OBLIQ_CORE` · handle: `cynex`
 
[![GitHub](https://img.shields.io/badge/GitHub-Abdul--Manan--C-181717?style=for-the-badge&logo=github)](https://github.com/Abdul-Manan-C)
[![TryHackMe](https://img.shields.io/badge/TryHackMe-mananhanif01-212C42?style=for-the-badge&logo=tryhackme)](https://tryhackme.com/p/mananhanif01)
[![Website](https://img.shields.io/badge/Website-abdulmannan.galaxydev.pk-0d1117?style=for-the-badge&logo=firefox)](https://abdulmannan.galaxydev.pk)
 
<img src="https://readme-typing-svg.demolab.com?font=Courier+New&size=14&pause=1500&color=3FB950&center=true&vCenter=true&width=500&lines=%22Learn+ethically.+Hack+legally.+Build+fearlessly.%22" alt="quote" />
 
<img src="https://komarev.com/ghpvc/?username=Abdul-Manan-C&label=Profile+Views&color=3fb950&style=flat-square" alt="views"/>
 
</div>
 
---
 
## `$ cat license.txt`
 
MIT License — free to use, modify, and distribute with attribution.
 
