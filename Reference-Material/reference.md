# MACCDC 2026 Competition Environment Reference

## Network Topology

The network has a three-tier architecture: VyOS Router at the top, two Palo Alto firewalls in the middle, and two separate LAN segments behind each firewall.

```
                        [Internet/Scoring]
                              |
                      [VyOS Router (VM 11)]
                       /                \
              [Firewall 1 (VM 9)]   [Firewall 2 (VM 10)]
                    |                       |
            [LAN Segment 1]         [LAN Segment 2]
            172.20.242.0/24         172.20.240.0/24
              |   |   |   |          |    |    |    |
             VM1 VM2 VM3 VM4       VM5  VM6  VM7  VM8
```

### LAN Segment 1 (Behind Firewall 1) — Linux/Mixed Zone
- Ubuntu Ecom (VM 1)
- Fedora Webmail (VM 2)
- Splunk (VM 3)
- Ubuntu Workstation (VM 4)

### LAN Segment 2 (Behind Firewall 2) — Windows Zone
- Server 2019 AD/DNS (VM 5)
- Server 2019 Web (VM 6)
- Server 2022 FTP (VM 7)
- Windows 11 Workstation (VM 8)

---

## VM Details

### VM 1 — Ubuntu Ecom
- **OS:** Ubuntu Server 24.04.3
- **Role:** E-commerce web server
- **Internal IP:** 172.20.242.30
- **Public IP:** 172.25.20+team#.11
- **Default Credentials:** sysadmin:changeme
- **LAN Segment:** 1 (behind Firewall 1)

### VM 2 — Fedora Webmail
- **OS:** Fedora 42
- **Role:** Webmail server (likely Roundcube or similar; handles SMTP/POP3 scoring)
- **Internal IP:** 172.20.242.40
- **Public IP:** 172.25.20+team#.39
- **Default Credentials:** sysadmin:changeme
- **LAN Segment:** 1 (behind Firewall 1)

### VM 3 — Splunk
- **OS:** Oracle Linux 9.2 with Splunk 10.0.2
- **Role:** SIEM / log aggregation
- **Internal IP:** 172.20.242.20
- **Public IP:** 172.25.20+team#.9
- **Default Credentials:**
  - root:changemenow
  - sysadmin:changemenow
  - admin:changeme (Splunk web interface)
- **LAN Segment:** 1 (behind Firewall 1)

### VM 4 — Ubuntu Workstation
- **OS:** Ubuntu Desktop 24.04.3
- **Role:** User workstation (must remain a workstation; cannot be re-tasked)
- **Internal IP:** DHCP
- **Public IP:** dynamic
- **Default Credentials:** sysadmin:changeme
- **LAN Segment:** 1 (behind Firewall 1)

### VM 5 — Server 2019 AD/DNS
- **OS:** Windows Server 2019 Standard
- **Role:** Active Directory Domain Controller + DNS server (DNS is a scored service)
- **Internal IP:** 172.20.240.102
- **Public IP:** 172.25.20+team#.155
- **Default Credentials:** administrator:!Password123
- **LAN Segment:** 2 (behind Firewall 2)

### VM 6 — Server 2019 Web
- **OS:** Windows Server 2019 Standard
- **Role:** Web server (HTTP/HTTPS are scored services)
- **Internal IP:** 172.20.240.101
- **Public IP:** 172.25.20+team#.140
- **Default Credentials:** administrator:!Password123
- **LAN Segment:** 2 (behind Firewall 2)

### VM 7 — Server 2022 FTP
- **OS:** Windows Server 2022 Standard
- **Role:** FTP server (FTP is a scored service; TFTP may also be hosted here)
- **Internal IP:** 172.20.240.104
- **Public IP:** 172.25.20+team#.162
- **Default Credentials:** administrator:!Password123
- **LAN Segment:** 2 (behind Firewall 2)

### VM 8 — Windows 11 Workstation
- **OS:** Windows 11 24H2
- **Role:** User workstation (must remain a workstation; cannot be re-tasked)
- **Internal IP:** 172.20.240.100
- **Public IP:** 172.25.20+team#.144
- **Default Credentials:**
  - administrator:!Password123
  - UserOne:ChangeMe123
- **LAN Segment:** 2 (behind Firewall 2)

### VM 9 — Firewall 1
- **OS:** Palo Alto PAN-OS 11.0.2
- **Role:** Firewall for LAN Segment 1 (Linux zone)
- **Outside Interface:** 172.16.101.254/24
- **Inside Interface:** 172.20.242.254/24
- **Management IP:** 172.20.242.150
- **Default Credentials:** admin:Changeme123

### VM 10 — Firewall 2
- **OS:** Palo Alto PAN-OS 11.0.2
- **Role:** Firewall for LAN Segment 2 (Windows zone)
- **Outside Interface:** 172.16.102.254/24
- **Inside Interface:** 172.20.240.254/24
- **Management IP:** 172.20.240.200
- **Default Credentials:** admin:Changeme123

### VM 11 — VyOS Router
- **OS:** VyOS 1.4.3
- **Role:** Core router connecting both firewall zones to the external/scoring network
- **External Interface:** 172.31.21.2/29 (connects to scoring/internet)
- **Net1 Interface:** 172.16.101.1/24 (connects to Firewall 1 outside)
- **Net2 Interface:** 172.16.102.1/24 (connects to Firewall 2 outside)
- **Default Credentials:** vyos:changeme

---

## Scored Services (from team packet)
- **HTTP** — Web page content match check
- **HTTPS** — SSL web page content match check
- **SMTP** — Email send/receive via valid accounts
- **POP3** — POP3 login using AD usernames
- **DNS** — DNS lookup resolution
- **FTP** — Authenticated and/or anonymous file access
- **TFTP** — File retrieval with integrity check
- **NTP** — Time synchronization check

## Likely Service-to-VM Mapping
| Service | Likely VM(s) | Notes |
|---------|-------------|-------|
| HTTP/HTTPS | VM 6 (Win Web), VM 1 (Ubuntu Ecom) | Both serve web content on public IPs |
| SMTP/POP3 | VM 2 (Fedora Webmail) | Mail services; uses AD accounts for POP3 |
| DNS | VM 5 (AD/DNS) | Active Directory integrated DNS |
| FTP | VM 7 (Server 2022 FTP) | Dedicated FTP server |
| TFTP | VM 7 (Server 2022 FTP) or VM 5 | Could be on either Windows server |
| NTP | VM 5 (AD/DNS) or VM 11 (VyOS) | DC commonly runs NTP; router also possible |

## Network Address Summary
| Subnet | Purpose |
|--------|---------|
| 172.31.21.0/29 | External/scoring network (router uplink) |
| 172.16.101.0/24 | Transit between VyOS and Firewall 1 |
| 172.16.102.0/24 | Transit between VyOS and Firewall 2 |
| 172.20.242.0/24 | LAN Segment 1 — Linux zone (behind FW1) |
| 172.20.240.0/24 | LAN Segment 2 — Windows zone (behind FW2) |
| 172.25.20+team#.0/24 | Public IP pool (NAT'd through firewalls) |

## Key Constraints (from team packet)
- Cannot change internal IP addresses or system names unless directed by inject
- Cannot re-task workstations (VM 4, VM 8)
- Cannot block entire subnets or whitelist only the scoring engine
- Password changes on scored service accounts require a support ticket via auth.ccdc.events
- Admin/root password changes do NOT require notification
- Inject responses must be submitted as PDF via NISE
- NISE times are in CST (team is in EST — 1 hour ahead)
- Red team is active the entire competition; they do NOT have direct NETLAB access
- SLA penalties accrue for extended service downtime