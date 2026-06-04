#  Virtual Network Lab

> A fully functional virtual network lab built on **KVM** with **pfSense** firewall, **VLAN segmentation**, and a live **HTTPS web server** — including deep OSI model analysis with Wireshark captures.

---

##  Overview

This project demonstrates building a complete enterprise-style network environment using only open-source virtualization tools. The lab includes a firewall/router, isolated client and server VLANs, and full packet-level analysis of HTTPS traffic.

---

##  Network Architecture

```
                        Internet (NAT)
                             │
                    ┌────────┴────────┐
                    │    pfSense      │
                    │  WAN: 192.168.100.47 (DHCP)
                    │  VLAN10 GW: 192.168.10.1
                    │  VLAN20 GW: 192.168.20.1
                    └────────┬────────┘
                             │
                    ┌────────┴────────┐
                    │  Open vSwitch   │
                    │    (ovs-br0)    │
                    │  802.1Q Trunk   │
                    └──────┬──────┬──┘
                           │      │
               ┌───────────┘      └───────────┐
               │                              │
        VLAN 10 (LAN)                  VLAN 20 (OPT1)
        192.168.10.0/24                192.168.20.0/24
               │                              │
    ┌──────────┴──────────┐      ┌────────────┴────────────┐
    │    Windows 10       │      │      Kali Linux          │
    │  192.168.10.10      │      │    192.168.20.10         │
    │  (Client)           │      │  Apache2 + HTTPS         │
    └─────────────────────┘      └──────────────────────────┘
```

---

##  Technologies Used

| Category | Technology |
|----------|-----------|
| Hypervisor | KVM (Kernel-based Virtual Machine) |
| Virtual Switch | Open vSwitch (OVS) with 802.1Q VLAN |
| Firewall/Router | pfSense |
| Client OS | Windows 10 |
| Server OS | Kali Linux |
| Web Server | Apache2 with HTTPS (self-signed cert) |
| Network Analysis | Wireshark |
| Protocols | TCP/IP, DNS, TLS 1.2/1.3, HTTP, ARP, ICMP |

---

##  What's Covered

### Part 1 — Lab Setup
-  KVM hypervisor configuration
-  Open vSwitch setup with VLAN tagging and trunk ports
-  pfSense installation and interface assignment (WAN + 2 VLANs)
-  Inter-VLAN routing and firewall rules
-  NAT configuration for internet access
-  Apache2 HTTPS with self-signed certificate
-  HTTP → HTTPS redirect (port 80 → 443)
-  End-to-end connectivity verification

### Part 2 — OSI Model Analysis
Full analysis of an HTTPS request (`rnb-team.com`) across all 7 OSI layers:

| Layer | Protocol | Details |
|-------|----------|---------|
| 7 — Application | HTTP/DNS | GET request, DNS resolution (UDP:53), SNI |
| 6 — Presentation | TLS 1.2/1.3 | Handshake, gzip/Brotli, UTF-8 |
| 5 — Session | TLS Session | HTTP Keep-Alive, cookies, session resumption |
| 4 — Transport | TCP | 3-way handshake, MSS 1460, 4-way close |
| 3 — Network | IP | TTL, MTU, NAT through pfSense |
| 2 — Data Link | Ethernet | ARP, MAC resolution, 802.1Q VLAN tags |
| 1 — Physical | Virtio-net | KVM virtual NIC emulation |

---

##  Key Configurations

### Open vSwitch — VLAN Setup

```bash
# Create bridge
ovs-vsctl add-br ovs-br0

# Add trunk port (to pfSense)
ovs-vsctl add-port ovs-br0 vnet0
ovs-vsctl set port vnet0 trunks=10,20

# Add access port — VLAN 10 (Windows 10)
ovs-vsctl add-port ovs-br0 vnet1
ovs-vsctl set port vnet1 tag=10

# Add access port — VLAN 20 (Kali Linux)
ovs-vsctl add-port ovs-br0 vnet2
ovs-vsctl set port vnet2 tag=20
```

### Apache2 HTTPS — Self-Signed Certificate

```bash
# Generate certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/ssl/private/apache-selfsigned.key \
  -out /etc/ssl/certs/apache-selfsigned.crt

# Enable SSL and redirect
a2enmod ssl rewrite
a2ensite default-ssl
```

---

##  Network Diagram

The full L3 network diagram   <img width="627" height="711" alt="image" src="https://github.com/user-attachments/assets/ee5b74d3-7b42-4a63-8eea-1cca04a383c7" />

---



---

##  License

This project is for educational and portfolio purposes.
