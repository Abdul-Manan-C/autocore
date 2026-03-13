```
  ▄▄▄       █    ██ ▄▄▄█████▓ ▒█████   ▄████▄   ▒█████   ██▀███  ▓█████
 ▒████▄     ██  ▓██▒▓  ██▒ ▓▒▒██▒  ██▒▒██▀ ▀█  ▒██▒  ██▒▓██ ▒ ██▒▓█   ▀
 ▒██  ▀█▄  ▓██  ▒██░▒ ▓██░ ▒░▒██░  ██▒▒▓█    ▄ ▒██░  ██▒▓██ ░▄█ ▒▒███
 ░██▄▄▄▄██ ▓▓█  ░██░░ ▓██▓ ░ ▒██   ██░▒▓▓▄ ▄██▒▒██   ██░▒██▀▀█▄  ▒▓█  ▄
  ▓█   ▓██▒▒▒█████▓   ▒██▒ ░ ░ ████▓▒░▒ ▓███▀ ░░ ████▓▒░░██▓ ▒██▒░▒████▒
  ▒▒   ▓▒█░░▒▓▒ ▒ ▒   ▒ ░░   ░ ▒░▒░▒░ ░ ░▒ ▒  ░░ ▒░▒░▒░ ░ ▒▓ ░▒▓░░░ ▒░ ░
```

<div align="center">

![Bash](https://img.shields.io/badge/Shell-Bash-green?logo=gnu-bash&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-blue)
![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20Android-informational)
![Version](https://img.shields.io/badge/Version-2.0-red)
![CTF](https://img.shields.io/badge/Use-CTF%20%7C%20TryHackMe%20%7C%20Lab-yellow)

**Automated bash-based pentest recon & enumeration orchestrator**

*By Ch Manan (OBLIQ_CORE) — [github.com/Abdul-Manan-C](https://github.com/Abdul-Manan-C)*

</div>

---

## What is AUTOCORE?

AUTOCORE is a fully rule-based, no-AI automated penetration testing script that runs all standard recon and enumeration phases automatically based on detected services. It outputs a beautiful colored terminal UI with structured output files and a final loot report.

- ✅ No AI backend — pure bash logic and conditionals
- ✅ Detects open ports → runs appropriate tools automatically
- ✅ All output saved to organized numbered files
- ✅ Works across Kali, Fedora, Arch, Debian, Ubuntu, Parrot, Termux, NetHunter

---

## Features

- 🔍 **Auto-recon** — WHOIS, DNS, Ping, host/nslookup
- 🔓 **Smart Nmap** — quick scan → full port scan → service detection → vuln scripts → OS detect
- 🌐 **Web enum** — WhatWeb, Nikto, Gobuster (dirs + files), curl headers, robots.txt, sitemap.xml
- 🗂️ **SMB enum** — enum4linux, smbclient, Nmap SMB NSE scripts
- 💥 **Brute force** — Hydra for SSH, FTP, Telnet, HTTP template
- 🎯 **MSF notes** — Ready-to-use Metasploit commands auto-generated
- 📋 **Final report** — Loot summary, all files listed, open ports, creds, vulns
- 🎨 **Color UI** — Dracula-style terminal with boxes, phase headers, status icons
- 🛡️ **Graceful failure** — Skips tools not installed, never crashes

---

## Installation

### Kali Linux
```bash
git clone https://github.com/Abdul-Manan-C/autocore
cd autocore
chmod +x installer.sh
sudo ./installer.sh
```

### Fedora (39/40/41/42/43)
```bash
chmod +x autocore-fedora.sh
sudo cp autocore-fedora.sh /usr/local/bin/autocore
sudo chmod +x /usr/local/bin/autocore
```

### Arch / BlackArch / Manjaro
```bash
chmod +x autocore-arch.sh
sudo cp autocore-arch.sh /usr/local/bin/autocore
sudo chmod +x /usr/local/bin/autocore
```

### Debian / Ubuntu / Parrot OS
```bash
chmod +x autocore-debian.sh
sudo cp autocore-debian.sh /usr/local/bin/autocore
sudo chmod +x /usr/local/bin/autocore
```

### Termux (Android, No Root)
```bash
chmod +x autocore-termux.sh
cp autocore-termux.sh $PREFIX/bin/autocore
autocore --setup    # installs all tools + wordlists
```

### NetHunter Rootless
```bash
chmod +x autocore-nethunter.sh
cp autocore-nethunter.sh $PREFIX/bin/autocore
autocore --setup
```

### Auto-detect (all platforms)
```bash
chmod +x installer.sh
./installer.sh     # Detects your OS and installs the correct version
```

---

## Usage

```bash
autocore <IP>             # Full automated scan (recommended)
autocore <IP> --web       # Web enumeration only
autocore <IP> --smb       # SMB enumeration only
autocore <IP> --brute     # Brute force only
autocore <IP> --full      # All phases (alias for default)
autocore <IP> --stealth   # Slow/quiet scan (-T2)
autocore --setup          # Termux/NetHunter: install tools
```

### Examples
```bash
autocore 10.10.10.5
autocore 192.168.1.100 --web
autocore 10.0.0.20 --stealth
```

---

## Output Structure

Every scan creates a session folder: `autocore_<IP>_<TIMESTAMP>/`

```
autocore_10.10.10.5_20250101_120000/
├── nmap/
│   ├── nmap_1_quick.txt          ← Top 1000 ports
│   ├── nmap_2_fullports.txt      ← All 65535 ports
│   ├── nmap_3_services.txt       ← Service + version detection
│   ├── nmap_4_vulns.txt          ← Vuln NSE scripts
│   └── nmap_5_os.txt             ← OS fingerprinting
├── web/
│   ├── gobuster_1_dirs.txt       ← Directory brute
│   ├── gobuster_2_files.txt      ← File brute (php,txt,html...)
│   ├── headers_1.txt             ← HTTP headers
│   ├── robots_1.txt              ← robots.txt
│   └── sitemap_1.txt             ← sitemap.xml
├── nikto/
│   └── nikto_1.txt               ← Nikto web vuln scan
├── smb/
│   ├── enum4linux_1_full.txt     ← Full SMB enumeration
│   ├── smb_1_shares.txt          ← SMB shares list
│   └── nmap_smb_scripts.txt      ← SMB vuln/enum NSE scripts
├── hydra/
│   ├── hydra_1_ssh.txt           ← SSH brute results
│   ├── hydra_2_ftp.txt           ← FTP brute results
│   ├── hydra_3_telnet.txt        ← Telnet brute results
│   └── hydra_4_http_template.txt ← HTTP brute template
├── metasploit/
│   └── metasploit_notes.txt      ← Ready-to-use MSF commands
├── whatweb/
│   └── whatweb_1.txt             ← Web technology fingerprint
├── enum/
│   └── recon.txt                 ← Ping, WHOIS, DNS
├── loot/
│   └── loot_summary.txt          ← Quick loot overview
└── REPORT_10.10.10.5.txt         ← Final full report
```

---

## Platform Support

| Platform | Version | Root | SMB | Metasploit | Scan Type |
|---|---|---|---|---|---|
| Kali Linux | autocore-kali.sh | sudo | Full | ✅ | -sS |
| Fedora | autocore-fedora.sh | sudo | Full | ✅ | -sS |
| Arch/BlackArch | autocore-arch.sh | sudo | Full | ✅ | -sS |
| Debian/Ubuntu/Parrot | autocore-debian.sh | sudo | Full | ✅ | -sS |
| Termux | autocore-termux.sh | None | Partial | Notes only | -sT |
| NetHunter Rootless | autocore-nethunter.sh | None | Partial | Notes only | -sS/-sT |

---

## Requirements

**Desktop/PC (Kali/Fedora/Arch/Debian):** nmap, hydra, nikto, whatweb, gobuster, curl, wget, enum4linux, smbclient

**Mobile (Termux/NetHunter):** nmap, hydra, nikto, curl, wget — all installable via `autocore --setup`

---

## ⚠️ Disclaimer

> AUTOCORE is intended **strictly for ethical and legal use only.**
> Use only on systems you own or have **explicit written permission** to test.
> Authorized platforms: CTF machines (TryHackMe, HackTheBox, VulnHub), personal labs, penetration testing with written consent.
> The author takes **no responsibility** for any misuse of this tool.
> Unauthorized scanning or access to systems is **illegal** and punishable by law.

---

## Author

**Ch Manan (OBLIQ_CORE)**
Handle: `cynex`
GitHub: [github.com/Abdul-Manan-C](https://github.com/Abdul-Manan-C)

> *"Learn ethically. Hack legally. Build fearlessly."*

---

## License

MIT License — free to use, modify, and distribute with attribution.
