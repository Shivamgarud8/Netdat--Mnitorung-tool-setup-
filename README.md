# 🐳 Netdata — Docker Installation Guide

Complete guide to installing and running Netdata via Docker.  
All methods covered: `docker run`, `docker-compose`, and `.env` config.

---

## 📋 Table of Contents

- [Prerequisites](#prerequisites)
- [Method 1 — docker run (Quick Start)](#method-1--docker-run-quick-start)
- [Method 2 — docker run (Full Production)](#method-2--docker-run-full-production)
- [Method 3 — docker-compose.yml](#method-3--docker-composeyml)
- [Volume Explained](#volumes-explained)
- [Flag Breakdown](#flag-breakdown)
- [Verify Installation](#verify-installation)
- [Useful Docker Commands](#useful-docker-commands)
- [Troubleshooting](#troubleshooting)

---

## ✅ Prerequisites

Docker must be installed and running:

```bash
# Check Docker is installed
docker --version

# Check Docker daemon is running
sudo systemctl status docker

# If not running, start it
sudo systemctl start docker
sudo systemctl enable docker
```

---

## Method 1 — docker run (Quick Start)

Minimal command to get Netdata running immediately:

```bash
docker run -d \
  --name=netdata \
  -p 19999:19999 \
  --restart unless-stopped \
  netdata/netdata
```

Open dashboard:

```
http://YOUR_SERVER_IP:19999
```

> ⚠️ Quick start shows limited metrics only.  
> Use Method 2 for full host + Docker container monitoring.

---

## Method 2 — docker run (Full Production)

This is the complete command with all mounts for full host-level monitoring:

```bash
docker run -d \
  --name=netdata \
  -p 19999:19999 \
  --pid=host \
  --cap-add=SYS_PTRACE \
  --security-opt apparmor=unconfined \
  -v netdataconfig:/etc/netdata \
  -v netdatalib:/var/lib/netdata \
  -v netdatacache:/var/cache/netdata \
  -v /etc/passwd:/host/etc/passwd:ro \
  -v /etc/group:/host/etc/group:ro \
  -v /proc:/host/proc:ro \
  -v /sys:/host/sys:ro \
  -v /etc/os-release:/host/etc/os-release:ro \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  --restart unless-stopped \
  netdata/netdata
```

### What each flag does

| Flag | Purpose |
|------|---------|
| `-d` | Run in background (detached mode) |
| `--name=netdata` | Name the container `netdata` |
| `-p 19999:19999` | Expose dashboard on port 19999 |
| `--pid=host` | Share host PID namespace — **required** to see all host processes |
| `--cap-add=SYS_PTRACE` | Allow process inspection — needed for app-level metrics |
| `--security-opt apparmor=unconfined` | Disable AppArmor restrictions for full `/proc` access |
| `--restart unless-stopped` | Auto-restart on reboot or crash |

### Volume mounts explained

| Mount | Purpose |
|-------|---------|
| `netdataconfig:/etc/netdata` | Persist your Netdata config files |
| `netdatalib:/var/lib/netdata` | Persist Netdata state and DB |
| `netdatacache:/var/cache/netdata` | Persist collected metrics cache |
| `/etc/passwd:/host/etc/passwd:ro` | Read host users for process ownership labels |
| `/etc/group:/host/etc/group:ro` | Read host groups for process labels |
| `/proc:/host/proc:ro` | Read host kernel metrics (CPU, memory, network, disk) |
| `/sys:/host/sys:ro` | Read host hardware/device metrics |
| `/etc/os-release:/host/etc/os-release:ro` | Detect host OS version |
| `/var/run/docker.sock:ro` | Connect to Docker API — enables per-container monitoring |

> `:ro` = read-only mount (Netdata only reads, never writes to your host)

---

## Method 3 — docker-compose.yml

Create a file called `docker-compose.yml`:

```yaml
version: '3.8'

services:
  netdata:
    image: netdata/netdata
    container_name: netdata
    pid: host
    ports:
      - "19999:19999"
    restart: unless-stopped
    cap_add:
      - SYS_PTRACE
    security_opt:
      - apparmor=unconfined
    volumes:
      - netdataconfig:/etc/netdata
      - netdatalib:/var/lib/netdata
      - netdatacache:/var/cache/netdata
      - /etc/passwd:/host/etc/passwd:ro
      - /etc/group:/host/etc/group:ro
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /etc/os-release:/host/etc/os-release:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro
    environment:
      - NETDATA_CLAIM_TOKEN=${NETDATA_CLAIM_TOKEN:-}
      - NETDATA_CLAIM_URL=https://app.netdata.cloud
      - NETDATA_CLAIM_ROOMS=${NETDATA_CLAIM_ROOMS:-}

volumes:
  netdataconfig:
  netdatalib:
  netdatacache:
```

### Start with docker-compose

```bash
# Start in background
docker compose up -d

# Start and watch logs
docker compose up

# Stop
docker compose down

# Stop and remove volumes (deletes all data)
docker compose down -v
```

### Optional: .env file for Netdata Cloud

Create a `.env` file alongside your `docker-compose.yml`:

```env
# Get these from https://app.netdata.cloud → Connect Nodes
NETDATA_CLAIM_TOKEN=your_claim_token_here
NETDATA_CLAIM_ROOMS=your_room_id_here
```

Then bring it up:

```bash
docker compose --env-file .env up -d
```

---

## Volumes Explained

### Named Volumes (recommended)

Docker manages these automatically under `/var/lib/docker/volumes/`:

```
netdataconfig   →  /var/lib/docker/volumes/netdataconfig/_data
netdatalib      →  /var/lib/docker/volumes/netdatalib/_data
netdatacache    →  /var/lib/docker/volumes/netdatacache/_data
```

### Bind Mounts (alternative — easier to edit config)

Replace named volumes with local paths if you want direct file access:

```bash
mkdir -p ./netdata/config ./netdata/lib ./netdata/cache

docker run -d \
  --name=netdata \
  -p 19999:19999 \
  --pid=host \
  --cap-add=SYS_PTRACE \
  --security-opt apparmor=unconfined \
  -v ./netdata/config:/etc/netdata \
  -v ./netdata/lib:/var/lib/netdata \
  -v ./netdata/cache:/var/cache/netdata \
  -v /etc/passwd:/host/etc/passwd:ro \
  -v /etc/group:/host/etc/group:ro \
  -v /proc:/host/proc:ro \
  -v /sys:/host/sys:ro \
  -v /etc/os-release:/host/etc/os-release:ro \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  --restart unless-stopped \
  netdata/netdata
```

Now you can edit config directly:

```bash
nano ./netdata/config/netdata.conf
```

---

## ✅ Verify Installation

### Check container is running

```bash
docker ps | grep netdata
```

Expected output:

```
CONTAINER ID   IMAGE              COMMAND      STATUS          PORTS
abc123def456   netdata/netdata    ...          Up 2 minutes    0.0.0.0:19999->19999/tcp
```

### Check container logs

```bash
docker logs netdata
docker logs netdata --follow    # live logs
docker logs netdata --tail 50   # last 50 lines
```

### Check dashboard is responding

```bash
curl -s http://localhost:19999/api/v1/info | python3 -m json.tool
```

### Open in browser

```
http://YOUR_SERVER_IP:19999
```

### Inspect container details

```bash
docker inspect netdata
```

---

## 🛠️ Useful Docker Commands

```bash
# Start the container
docker start netdata

# Stop the container
docker stop netdata

# Restart the container
docker restart netdata

# Remove the container (keeps volumes)
docker rm netdata

# Remove container AND all volumes (deletes all data)
docker rm netdata
docker volume rm netdataconfig netdatalib netdatacache

# Pull latest Netdata image
docker pull netdata/netdata

# Update to latest version
docker stop netdata
docker rm netdata
docker pull netdata/netdata
# then re-run your docker run command

# Get a shell inside the container
docker exec -it netdata bash

# Check Netdata config inside container
docker exec netdata cat /etc/netdata/netdata.conf

# Edit config inside container
docker exec -it netdata /etc/netdata/edit-config netdata.conf
```

---

## 🧪 Troubleshooting

### Dashboard shows "No charts to display"

```bash
# Check container is running
docker ps

# Check logs for errors
docker logs netdata --tail 100

# Restart container
docker restart netdata
```

### Port 19999 not accessible

```bash
# Check port is bound
sudo ss -tulpn | grep 19999

# Check AWS Security Group allows port 19999
# EC2 → Security Groups → Inbound Rules → Add Custom TCP 19999
```

### Docker metrics not showing (no container charts)

The `/var/run/docker.sock` mount is missing or has wrong permissions:

```bash
# Check socket exists on host
ls -la /var/run/docker.sock

# Expected output:
# srw-rw---- 1 root docker ... /var/run/docker.sock

# Add your user to docker group if needed
sudo usermod -aG docker $USER
```

Then re-run the `docker run` command with the socket mount.

### Container exits immediately

```bash
# Check exit reason
docker logs netdata

# Common cause: AppArmor blocking access
# Make sure --security-opt apparmor=unconfined is present in your run command
```

### Permission errors on /proc or /sys

```bash
# Run with explicit privileged mode (less secure but works)
docker run -d \
  --name=netdata \
  -p 19999:19999 \
  --privileged \
  -v /proc:/host/proc:ro \
  -v /sys:/host/sys:ro \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  --restart unless-stopped \
  netdata/netdata
```

> ⚠️ Use `--privileged` only if the standard flags don't work. It grants full host access.

### Check which collectors are active

```bash
docker exec netdata netdatacli aclk-state
docker exec netdata bash -c "ls /usr/lib/netdata/conf.d/"
```

---

## 📌 Quick Reference

```bash
# Full production install (one command)
docker run -d --name=netdata -p 19999:19999 --pid=host \
  --cap-add=SYS_PTRACE --security-opt apparmor=unconfined \
  -v netdataconfig:/etc/netdata -v netdatalib:/var/lib/netdata \
  -v netdatacache:/var/cache/netdata \
  -v /etc/passwd:/host/etc/passwd:ro \
  -v /etc/group:/host/etc/group:ro \
  -v /proc:/host/proc:ro -v /sys:/host/sys:ro \
  -v /etc/os-release:/host/etc/os-release:ro \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  --restart unless-stopped netdata/netdata

# Dashboard
http://YOUR_IP:19999

# Logs
docker logs netdata -f

# Restart
docker restart netdata
```
