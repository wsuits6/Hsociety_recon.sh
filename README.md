# HSOCIETY gh0st recon

A lightweight network‑recon automation script for **authorized diagnostic testing** on local networks.  
It identifies active hosts, grabs basic banners, performs optional deeper scans, and stores everything in a timestamped results folder.

---

## Features

- Local network discovery (ARP scan, if available)
- Ping sweep using `nmap`
- Service banner grabbing on common ports (22, 80, 443)
- Optional deep scan with `--deep`
- WHOIS lookup
- Reverse DNS lookup
- Certificate transparency queries (crt.sh)
- Automatic anonymous mode via Tor when available
- Randomized user‑agent generation
- Output stored neatly inside a `gh0st_YYYYMMDD_HHMMSS` directory

---

## Requirements

The script can run with minimal tools, but fully supports:

- `arp-scan`
- `nmap`
- `dig`
- `curl`
- `jq`
- `whois`
- `torsocks`

Missing tools simply disable their related modules; the rest still works.

---

## Usage

Basic run:

```bash
./hs_gh0st_recon.sh <router_ip>
