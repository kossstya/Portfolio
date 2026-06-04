#  Proxmox VE in systemd-nspawn Container

> A complete guide for deploying **Proxmox VE** as a `systemd-nspawn` container on **Debian 12 (Bookworm)** — without needing a dedicated physical machine.

---

##  Overview

This guide documents how to run a full **Proxmox VE** installation inside a `systemd-nspawn` container on a Debian 12 host. This approach allows you to use Proxmox's web interface and management features on a shared host system using LVM volumes for storage.

---

##  Architecture

```
┌─────────────────────────────────────────┐
│           Debian 12 (Host)              │
│                                         │
│   ve-proxmox (bridge)                   │
│   Host IP: 10.0.0.1/24                  │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │   systemd-nspawn Container      │    │
│  │                                 │    │
│  │   Proxmox VE                    │    │
│  │   Container IP: 10.0.0.2/24     │    │
│  │   Web UI: https://10.0.0.2:8006 │    │
│  └─────────────────────────────────┘    │
│                                         │
│   Port forward: host:8006 → 10.0.0.2   │
└─────────────────────────────────────────┘
```

---

##  Technologies Used

| Component | Technology |
|-----------|-----------|
| Host OS | Debian 12 Bookworm |
| Container | systemd-nspawn |
| Storage | LVM (25GB root + data volumes) |
| Base install | debootstrap |
| Networking | systemd-networkd, IP masquerading |
| Firewall | iptables / NAT |
| Port forward | socat |
| Web UI | Proxmox VE on port 8006 (HTTPS) |

---

##  What's Covered

-  LVM physical volume and logical volume setup
-  Debian base system via `debootstrap`
-  Container network configuration (`10.0.0.x/24`)
-  DNS, hostname, and locale configuration
-  Proxmox VE repository setup and installation
-  `systemd-nspawn` configuration with FUSE support
-  External port forwarding via `socat` (port 8006)
-  IP forwarding and IP masquerading (NAT)
-  Troubleshooting common issues
-  Reference command table

---

##  Quick Start

### 1. Set up LVM volumes

```bash
pvcreate /dev/sdX
vgcreate proxmox-vg /dev/sdX
lvcreate -L 25G -n root proxmox-vg
mkfs.ext4 /dev/proxmox-vg/root
mount /dev/proxmox-vg/root /var/lib/machines/proxmox
```

### 2. Bootstrap Debian base system

```bash
debootstrap --arch=amd64 bookworm /var/lib/machines/proxmox http://deb.debian.org/debian
```

### 3. Configure networking

```bash
# On host — create bridge interface
ip link add ve-proxmox type bridge
ip addr add 10.0.0.1/24 dev ve-proxmox
ip link set ve-proxmox up

# Enable IP forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward

# NAT masquerade
iptables -t nat -A POSTROUTING -s 10.0.0.0/24 -j MASQUERADE
```

### 4. Start the container

```bash
systemd-nspawn -D /var/lib/machines/proxmox \
  --network-bridge=ve-proxmox \
  --capability=all \
  --bind=/dev/fuse \
  -b
```

### 5. Access Proxmox Web UI

```bash
# Port forward from host to container
socat TCP-LISTEN:8006,fork TCP:10.0.0.2:8006 &
```



---

##  Troubleshooting

| Issue | Solution |
|-------|----------|
| Web UI not accessible | Check socat port forward is running |
| No internet in container | Verify IP forwarding and iptables MASQUERADE |
| FUSE errors | Ensure `--bind=/dev/fuse` flag is set |
| SSL certificate error | Expected — Proxmox uses self-signed cert by default |

---



---

##  License

This project is for educational and documentation purposes.
