#  NOC Incident Report — WordPress Site Recovery

> A real-world incident report documenting the full **diagnosis and restoration** of a production WordPress website that went down due to multiple simultaneous failures.

---

##  Incident Summary

**Role:** NOC (Network Operations Center) Engineer
**Status:**  Resolved
**Environment:** Nginx + WordPress + Docker + MySQL/MariaDB

The website was completely non-functional. Through systematic diagnosis, four separate root causes were identified and resolved.

---

##  Root Causes Identified

| # | Component | Issue | Resolution |
|---|-----------|-------|------------|
| 1 | **Network / iptables** | Port 443 (HTTPS) was blocked | Opened required ports in iptables |
| 2 | **File System** | Corrupted/missing WordPress files (`wp-config.php`, themes, plugins) | Restored from backup archive |
| 3 | **Docker** | Volume mismatch and container cache issues | Full container restart via Docker Compose |
| 4 | **Database** | Missing WordPress tables (`wp_users`, `wp_options`) | Restored from database backup |

---

##  Technologies Used

![Nginx](https://img.shields.io/badge/Nginx-009639?style=flat-square&logo=nginx&logoColor=white)
![WordPress](https://img.shields.io/badge/WordPress-21759B?style=flat-square&logo=wordpress&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=flat-square&logo=docker&logoColor=white)
![MySQL](https://img.shields.io/badge/MySQL-4479A1?style=flat-square&logo=mysql&logoColor=white)
![Linux](https://img.shields.io/badge/Linux-FCC624?style=flat-square&logo=linux&logoColor=black)

---

##  Diagnosis Workflow

```
Initial Alert: Site Unreachable
         │
         ▼
   curl -I https://site.com     ← Connection refused / timeout
         │
         ▼
   Check iptables rules         ← Port 443 BLOCKED ✗
         │
         ▼
   Open port 443                ← Site partially accessible
         │
         ▼
   Check Nginx error logs       ← PHP/WordPress file errors
         │
         ▼
   Inspect WordPress files      ← wp-config.php missing ✗
         │
         ▼
   Restore from backup archive  ← Files restored ✓
         │
         ▼
   Restart Docker containers    ← Volume sync issues resolved ✓
         │
         ▼
   Check database tables        ← wp_users, wp_options missing ✗
         │
         ▼
   Restore DB from backup       ← Tables restored ✓
         │
         ▼
   Final verification           ← Site fully operational ✓
```

---

##  Key Commands Used

### Firewall Diagnosis & Fix
```bash
# Check current iptables rules
iptables -L -n -v

# Open HTTPS port
iptables -I INPUT -p tcp --dport 443 -j ACCEPT
iptables -I INPUT -p tcp --dport 80 -j ACCEPT

# Save rules
iptables-save > /etc/iptables/rules.v4
```

### File System Recovery
```bash
# Check for missing WordPress files
ls -la /var/www/html/wp-config.php

# Restore from backup
tar -xzf backup.tar.gz -C /var/www/html/

# Fix permissions
chown -R www-data:www-data /var/www/html/
chmod -R 755 /var/www/html/
```

### Docker Recovery
```bash
# Stop and remove containers (preserve volumes)
docker compose down

# Restart fresh
docker compose up -d

# Verify all containers running
docker compose ps
```

### Database Recovery
```bash
# Connect to MySQL container
docker exec -it mysql-container mysql -u root -p

# Check existing tables
SHOW TABLES;

# Restore from SQL dump
docker exec -i mysql-container mysql -u root -p wordpress < backup.sql

# Verify critical tables
SHOW TABLES LIKE 'wp_%';
```

---

##  Final Verification

```bash
# HTTP → HTTPS redirect
curl -I http://site.com
# Expected: 301 Moved Permanently → https://site.com

# HTTPS response
curl -I https://site.com
# Expected: 200 OK

# WordPress admin panel
curl -I https://site.com/wp-admin/
# Expected: 302 redirect to login page
```

---



---

##  License

This project is for portfolio and educational purposes.
