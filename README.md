<p align="center">
  <img src="https://heitorgouvea.me/images/projects/nipe/logo.png">
  <p align="center">An engine to make Tor Network your default gateway.</p>
  <p align="center">
    <a href="/LICENSE.md">
      <img src="https://img.shields.io/badge/license-MIT-blue.svg">
    </a>
    <a href="https://github.com/htrgouvea/nipe/releases">
      <img src="https://img.shields.io/badge/version-0.9.8-blue.svg">
    </a>
     <br/>
    <img src="https://github.com/htrgouvea/nipe/actions/workflows/linter.yml/badge.svg">
    <img src="https://github.com/htrgouvea/nipe/actions/workflows/zarn.yml/badge.svg">
    <img src="https://github.com/htrgouvea/nipe/actions/workflows/security-gate.yml/badge.svg">
    <img src="https://github.com/htrgouvea/nipe/actions/workflows/test-on-ubuntu.yml/badge.svg">
  </p>
</p>

---

### Overview

**NipeX (Nipe Extended)** is a fork of [Nipe](https://github.com/htrgouvea/nipe) by Heitor Gouvêa, extended with various additional privacy & security tools. Built for Debian systems, NipeX integrates Nipe with other essential tools for cleaning metadata, managing MAC addresses, configuring firewalls (UFW), monitoring traffic, scanning for rootkits, and much more, all from a single user-friendly interface.

In addition to using Tor as the default gateway, you can also deploy your own obfs4 bridge using Docker to enhance resilience against censorship and Tor network blocking. This feature allows you to run a private obfs4 bridge that can help other users access the Tor network in highly restricted environments.

---

### Download and Install

```bash
# Download the NipeX repository
git clone https://github.com/ricalnet/nipex && cd nipex
    
# Install libraries and dependencies
sudo apt install -y cpanminus && sudo cpanm --installdeps .

# Nipe must be run as root
sudo perl nipe.pl install
  
# Run NipeX
./main.sh
```

---

### Commands:
```
╔═════════════════════════════════════════════════════════╗
║                    ____    _______                      ║
║                   /    \  |       \                     ║
║                  |  ()  | | PRIVACY!                    ║
║                   \____/  |_______/                     ║
║                                                         ║
║               N I P E   E X T E N D E D                 ║
║              Privacy & Security Toolkit                 ║
║                                                         ║
║           https://github.com/ricalnet/nipex/            ║
╚═════════════════════════════════════════════════════════╝

PRIVACY TOOLS
  1) Change hostname
  2) Change timezone
  3) Set DNS (LibreDNS+Quad9)
  4) MAC management (random/custom)
  5) Remove file metadata (MAT2)

SECURITY TOOLS
  6) Check file integrity
  7) Password generator
  8) Firewall (UFW)
  9) Monitor traffic (tcpdump)
 10) Rootkit Hunter (rkhunter)
 11) Service status
 12) System monitor (htop)

MAIN TOOLS
 13) Main Tools (Nipe)
 14) Deploy obfs4-Docker

  0) Exit

Select menu [0-14]: 
```

---

### Deploy Your Own obfs4 Bridge

NipeX includes support for deploying your own obfs4 bridge using Docker. An obfs4 bridge is a type of Tor bridge that uses obfuscation protocols to hide Tor traffic, making it more difficult to detect and block. By deploying your own obfs4 bridge, you can:

- Help other users access the Tor network in heavily censored environments
- Improve the overall resilience of the Tor network
- Run a private bridge that you can use yourself or share

To deploy an obfs4 bridge:

1. Make sure Docker and Docker Compose are installed on your system. If not, you can use the provided installation scripts:
   ```bash
   # For Debian
   curl -O https://raw.githubusercontent.com/ricalnet/digital-independence/main/install-docker-engine-on-debian.sh
   chmod +x install-docker-engine-on-debian.sh
   ./install-docker-engine-on-debian.sh
   
   # Or for Ubuntu
   curl -O https://raw.githubusercontent.com/ricalnet/digital-independence/main/install-docker-engine-on-ubuntu.sh
   chmod +x install-docker-engine-on-ubuntu.sh
   ./install-docker-engine-on-ubuntu.sh
   ```
2. Edit and customize the `.env` file from the `obfs4-docker` directory:
   ```bash
   cd obfs4-docker
   cp .env.example .env
   nano .env  # or use your preferred text editor
   ```
   Customize variables such as `OR_PORT`, `PT_PORT`, `NICKNAME`, `EMAIL`, and others according to your needs.
3. Run NipeX and select menu **14) Deploy obfs4-Docker**
4. Use the **Start** option to run the obfs4 bridge container
5. Verify that the bridge is running properly using the **Verify** option
6. Your bridge will be available and can be used by Tor clients that need it

---

### Contributing

Your contributions and suggestions are very welcome ♥. [See the contribution guide here.](/.github/CONTRIBUTING.md) Please report bugs through the [issues page](https://github.com/ricalnet/NipeX/issues) and for security issues, see the [security policy here.](/SECURITY.md) (✿ ◕‿◕)

---

### License

This work is licensed under the [MIT License.](/LICENSE.md)