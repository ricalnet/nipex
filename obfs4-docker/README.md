# Obfs4 Bridge - Docker Deployment

## Overview

An obfs4 bridge is a Tor bridge that uses the obfs4 pluggable transport protocol to help users bypass internet censorship. This project provides a Docker-based deployment solution for running your own obfs4 bridge with minimal configuration.

> **Reference:** [Official setup instructions](https://community.torproject.org/relay/setup/bridge/docker/)

## Prerequisites

- **Ubuntu Server** (20.04 LTS or newer recommended)
- **Docker Engine** (version 29.1.4 or higher)
- **Docker Compose** (version 5.0.1 or higher)
- **Git** (for cloning the repository)
- **Firewall access** (sudo/root privileges)

## Quick Start

### 1. Install Docker & Docker Compose

> **Reference:** [Install Docker Engine on Ubuntu](https://docs.docker.com/engine/install/ubuntu/)

### 2. Configure User Permissions

```bash
docker --version
docker compose version
docker run hello-world

# Add current user to docker group
sudo usermod -aG docker $USER

# Reload group membership (or log out and back in)
newgrp docker
```

### 3. Deploy Obfs4 Bridge

```bash
# Clone repository
git clone https://github.com/ricalnet/obfs4-docker.git
cd obfs4-docker

# Copy environment template
cp .env.example .env

# Edit configuration
nano .env  # or use your preferred editor
```

### 4. Configure Firewall

```bash
sudo ufw --force enable

# Allow required ports (replace with your configured ports)
sudo ufw allow 443/tcp comment 'Tor OR Port'
sudo ufw allow 9443/tcp comment 'Obfs4 PT Port'

sudo ufw status verbose
```

### 5. Launch Bridge

```bash
docker compose pull
docker compose up -d
docker compose ps
docker compose logs --tail=50 -f

```

### 6. Verification

```bash
chmod +x verify.sh
./verify.sh
```

## Configuration Guide

### Essential Configuration (.env)

Edit the `.env` file with these critical parameters:

```bash
# Required Configuration
OR_PORT=443          # Tor OR Port (443 blends with HTTPS traffic)
PT_PORT=9443         # Obfs4 pluggable transport port
EMAIL=your-email@example.com  # Valid email for notifications
NICKNAME=YourBridgeName       # Descriptive bridge identifier

# Performance Settings
OBFS4V_BandwidthRate=2 MBytes     # Sustained bandwidth rate
OBFS4V_BandwidthBurst=4 MBytes    # Maximum burst bandwidth
OBFS4V_MaxAdvertisedBandwidth=4 MBytes  # Advertised capacity

# Security Settings
OBFS4V_AddressDisableIPv6=1  # Disable IPv6 (recommended)
OBFS4V_LogLevel=notice       # Logging verbosity
```

### Port Configuration Recommendations

| Port | Purpose | Recommendation |
|------|---------|----------------|
| OR_PORT | Tor onion routing | 443 (best), 9001, or 8080 |
| PT_PORT | Obfs4 transport | 9443, 8080, or any high port |

**Note:** Using port 443 for OR_PORT helps blend Tor traffic with regular HTTPS traffic, making it harder to detect and block.

## Security Considerations

### Firewall Configuration

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ${OR_PORT}/tcp
sudo ufw allow ${PT_PORT}/tcp
sudo ufw allow ssh
```

### Regular Maintenance

1. **Update Docker images:**
   ```bash
   docker compose pull
   docker compose up -d
   ```

2. **Monitor logs for abuse:**
   ```bash
   docker compose logs | grep -i "error\|warn\|failed"
   ```

3. **Check disk usage:**
   ```bash
   docker system df
   ```

## Troubleshooting

### Log Analysis

Follow logs in real-time:
```bash
docker compose logs -f
```

Search for specific issues
```bash
docker compose logs | grep -E "(error|fail|warn|cert|fingerprint)"
```

## Performance Tuning

### Resource Limits

The default Docker Compose configuration includes reasonable limits:
- CPU: 0.5 cores maximum
- Memory: 512MB limit, 256MB reservation

Adjust based on your server capacity in `docker-compose.yml`:

```yaml
deploy:
  resources:
    limits:
      cpus: '1.0'      # Increase for higher traffic
      memory: 1G       # Increase if needed
    reservations:
      memory: 512M
```

### Bandwidth Optimization

Modify in `.env`:
- `OBFS4V_BandwidthRate`: Average bandwidth (e.g., "5 MBytes")
- `OBFS4V_BandwidthBurst`: Peak bandwidth (e.g., "10 MBytes")
- `OBFS4V_MaxAdvertisedBandwidth`: Advertised limit (e.g., "10 MBytes")

---

**Important:** Operating a Tor bridge may have legal implications in some jurisdictions. Ensure compliance with local laws and regulations. The email address provided will be publicly associated with your bridge in Tor metrics.