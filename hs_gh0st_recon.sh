#!/usr/bin/env bash
# hs_gh0st_recon.sh — HSOCIETY Ghost Recon
# Usage: ./hs_gh0st_recon.sh <router_ip> [--deep]

set -euo pipefail
IFS=$'\n\t'

# === Colors ===
RED="\033[1;31m"
GREEN="\033[1;32m"
CYAN="\033[1;36m"
YELLOW="\033[1;33m"
MAG="\033[1;35m"
RESET="\033[0m"

# === HSOCIETY Banner ===
cat <<'HSOCIETY'
██████╗ ██╗  ██╗ ██████╗ ███████╗ ██████╗  ██████╗ ██╗   ██╗
██╔══██╗██║  ██║██╔═══██╗██╔════╝██╔═══██╗██╔═══██╗╚██╗ ██╔╝
██████╔╝███████║██║   ██║███████╗██║   ██║██║   ██║ ╚████╔╝ 
██╔═══╝ ██╔══██║██║   ██║╚════██║██║   ██║██║   ██║  ╚██╔╝  
██║     ██║  ██║╚██████╔╝███████║╚██████╔╝╚██████╔╝   ██║   
╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚══════╝ ╚═════╝  ╚═════╝    ╚═╝   
                 HSOCIETY — gh0st recon
HSOCIETY

# === Args ===
if [[ $# -lt 1 ]]; then
  echo -e "${RED}[!] Usage: $0 <router_ip> [--deep]${RESET}"
  exit 1
fi
ROUTER_IP="$1"
DEEP=${2:-false}

# === Output directory ===
OUTDIR="./gh0st_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUTDIR"

# === Helper loggers ===
info(){ echo -e "${CYAN}[+]${RESET} $*"; }
good(){ echo -e "${GREEN}[✓]${RESET} $*"; }
warn(){ echo -e "${YELLOW}[!]${RESET} $*"; }
bad(){ echo -e "${RED}[-]${RESET} $*"; }

# === Dependencies ===
for cmd in arp-scan nmap dig curl jq whois torsocks; do
  if ! command -v $cmd >/dev/null 2>&1; then
    warn "$cmd not installed — some modules disabled"
  fi
done

# === Ghost cloak (random UA + Tor if possible) ===
UA="Mozilla/5.0 (HSOCIETY Recon; $(shuf -n1 /usr/share/wordlists/rockyou.txt 2>/dev/null || echo "Gh0st"))"
CURL="curl -s -A \"$UA\""
if command -v torsocks >/dev/null 2>&1; then
  CURL="torsocks $CURL"
  info "Running curl through Tor (anonymous mode)"
fi

# === Basic checks ===
info "Target router: $ROUTER_IP"
echo "target=$ROUTER_IP" > "$OUTDIR/meta.txt"

# === ARP Scan (silent) ===
if command -v arp-scan >/dev/null 2>&1; then
  info "Scanning local net via ARP…"
  sudo arp-scan --localnet --ignoredups > "$OUTDIR/arp.txt" 2>/dev/null || warn "ARP scan failed"
  good "ARP results saved."
fi

# === Ping Sweep ===
info "Running nmap host discovery…"
nmap -sn "$ROUTER_IP/24" -oG "$OUTDIR/hosts.gnmap" >/dev/null 2>&1 || warn "nmap discovery failed"
awk '/Up/{print $2}' "$OUTDIR/hosts.gnmap" > "$OUTDIR/hosts_up.txt"
good "$(wc -l < "$OUTDIR/hosts_up.txt") live hosts found."

# === Banner Grab ===
info "Silent banner grab (22,80,443)…"
mkdir -p "$OUTDIR/banners"
for host in $(cat "$OUTDIR/hosts_up.txt"); do
  for p in 22 80 443; do
    timeout 3 bash -c "echo | nc -w 2 $host $p" > "$OUTDIR/banners/${host}_${p}.txt" 2>/dev/null || true
  done
done
good "Banners captured."

# === Optional Deep Scan ===
if [[ "$DEEP" == "--deep" ]]; then
  warn "Deep mode enabled. This is noisy."
  nmap -sS -sV --top-ports 50 -iL "$OUTDIR/hosts_up.txt" -oN "$OUTDIR/nmap_deep.txt" >/dev/null 2>&1
  good "Deep scan complete."
fi

# === WHOIS (anonymous if possible) ===
info "Performing WHOIS lookup for router IP…"
whois "$ROUTER_IP" > "$OUTDIR/whois.txt" 2>/dev/null || warn "WHOIS failed"

# === DNS Reverse ===
info "Reverse DNS lookup…"
dig -x "$ROUTER_IP" +short > "$OUTDIR/reverse_dns.txt" || true

# === crt.sh Subdomain Recon (Tor cloak) ===
info "Fetching cert transparency logs…"
eval $CURL "https://crt.sh/?q=%25.$ROUTER_IP&output=json" | jq -r '.[].name_value' | sort -u > "$OUTDIR/crt.txt" || true

# === Wrap up ===
echo
good "Recon complete."
info "Results saved in: ${OUTDIR}"
