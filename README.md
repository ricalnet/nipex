<p align="center">
  <img src="https://heitorgouvea.me/images/projects/nipe/logo.png">
  <p align="center">A privacy & security toolkit built on top of Nipe.</p>
  <p align="center">
    <a href="/LICENSE.md">
      <img src="https://img.shields.io/badge/license-MIT-blue.svg">
    </a>
    <a href="#">
      <img src="https://img.shields.io/badge/version-0.1-blue.svg">
    </a>
  </p>
</p>

### Overview

NipeX (Nipe Extended) is a fork of [Nipe](https://github.com/htrgouvea/nipe) by Heitor Gouvêa, extended with additional privacy & security tools. Built for Debian-based systems (including Raspberry Pi OS), NipeX wraps Nipe's Tor gateway functionality together with a set of commands for encryption, anti-forensic cleanup, metadata stripping, MAC spoofing, and more — all from a single user-friendly CLI.

NipeX uses [Nipe](https://github.com/htrgouvea/nipe) as its Tor engine. When you run `nipex start-tor`, it calls the upstream `nipe.pl` script to route your traffic through the Tor network as the default gateway.

> The obfs4 bridge deployment feature that previously shipped with NipeX has been moved to a dedicated guide in the digital-independence wiki. See [Obfs4 — Deployment & Theory Guide](https://git.ricalnet.my.id/rical/digital-independence/wiki/Obfs4-%E2%80%94-Panduan-deployment-dan-Pemahaman-Teori). That guide now uses `podman-compose` (rootless) instead of Docker Compose for improved security and no daemon requirement.

### Features

#### Privacy
- `hostname [name]` — Change system hostname
- `timezone [zone]` — Change system timezone
- `dns` — Set DNS to LibreDNS + Quad9
- `mac [iface] [mac]` — Randomize or set MAC address
- `mac-all` — Randomize MAC on all interfaces
- `swap-off` — Disable swap (session only, non-persistent)
- `tmpfs` — Mount `/tmp` as RAM (tmpfs)
- `spoof-tz-env [zone]` — Validate timezone and print `TZ` export for your shell
- `history-disable` — Print commands to disable shell history (with `source <(...)` helper)
- `strip-meta <file>` — Strip metadata from a file using `exiftool`

#### Crypto
- `passwd [len]` — Generate a strong password (default: 20 chars)
- `ssh-key [name]` — Generate an ed25519 SSH key
- `ssh-copy [name]` — Copy public key to clipboard (`xclip`)
- `ssh-add-auth [name]` — Add public key to `authorized_keys`
- `ssh-del-auth [name]` — Remove public key from `authorized_keys`
- `encrypt <file>` — Encrypt file with `age` (or `gpg` fallback)
- `decrypt <file.age|file.gpg>` — Decrypt file
- `encrypt-dir <dir>` — Encrypt a directory as `.tar.age` / `.tar.gpg`
- `decrypt-dir <archive>` — Decrypt and extract a directory archive

#### Anti-Forensic
- `wipe <path>` — Securely delete a file or directory using `shred`
- `wipe-tmp` — Wipe `/tmp` and `/var/tmp`
- `wipe-history` — Wipe shell history files
- `wipe-cache` — Wipe browser and cache directories

#### Fingerprint
- `fingerprint` — Show HTTP fingerprint and local environment info

#### Tor (via upstream Nipe)
- `install-tor` — Install Nipe dependencies and run `nipe.pl install`
- `start-tor` — Start Nipe (route traffic through Tor)
- `stop-tor` — Stop Nipe
- `restart-tor` — Restart Nipe
- `status-tor` — Show Nipe status

#### Other
- `help` / `version`
- `install` — Install `nipex` to `/usr/local/bin`

### Requirements

- Debian-based system (Debian, Ubuntu, Raspberry Pi OS)
- `bash` 4.4+
- Root access via `sudo` for system-level commands

Optional dependencies (installed on demand by the relevant commands):
- `macchanger` — for `mac` / `mac-all`
- `age` — for `encrypt` / `encrypt-dir` (preferred)
- `gpg` — fallback for `encrypt` / `encrypt-dir`
- `xclip` — for `ssh-copy`
- `exiftool` — for `strip-meta` (package: `libimage-exiftool-perl`)
- `curl` — for `fingerprint`

### Download and Install

```bash
git clone https://git.ricalnet.my.id/rical/nipex.git 
cd nipex

sudo apt update
sudo apt install -y macchanger openssl curl gpg age libimage-exiftool-perl xclip cpanminus

sudo cpanm --installdeps .

chmod +x nipex

./nipex install
nipex install-tor
```

The `install` command copies `nipex` to `/usr/local/bin/nipex` and saves the
`NIPE_DIR` path to `~/.nipex.conf`.

### Usage

```bash
nipex <command> [args]
```

Run `nipex help` for the full list of commands.

#### Examples

```bash
# Privacy
nipex hostname workstation-01
nipex timezone Asia/Jakarta
nipex dns
nipex mac wlan0
nipex mac-all
nipex swap-off
nipex tmpfs

# Privacy extra
nipex spoof-tz-env Asia/Tokyo
nipex history-disable
source <(nipex history-disable-export)
nipex strip-meta photo.jpg

# Crypto
nipex passwd 32
nipex ssh-key id_ed25519
nipex ssh-copy id_ed25519
nipex ssh-add-auth id_ed25519
nipex encrypt secrets.txt
nipex decrypt secrets.txt.age
nipex encrypt-dir ~/projects/private
nipex decrypt-dir ~/projects/private.tar.age /tmp/restore

# Anti-forensic
nipex wipe ~/secret.txt
nipex wipe-tmp
nipex wipe-history
nipex wipe-cache

# Fingerprint
nipex fingerprint

# Tor (requires Nipe source in the same directory or configured via NIPE_DIR)
nipex install-tor
nipex start-tor
nipex stop-tor
nipex status-tor
```

### How Tor Integration Works

NipeX does **not** implement its own Tor client. Instead, it delegates to the
upstream [Nipe](https://github.com/htrgouvea/nipe) project:

- `nipex install-tor` runs `perl nipe.pl install` and installs CPAN dependencies.
- `nipex start-tor` runs `perl nipe.pl start`.
- `nipex stop-tor` runs `perl nipe.pl stop`.
- `nipex status-tor` runs `perl nipe.pl status`.

For NipeX to find `nipe.pl`, either:

1. Place `nipex` in the same directory as `nipe.pl`, or
2. Set `NIPE_DIR` in `~/.nipex.conf`:
   ```bash
   NIPE_DIR="/path/to/nipe"
   ```

All credit for the Tor gateway logic goes to the Nipe project by Heitor Gouvêa.

### Obfs4 Bridge Deployment (Moved)

The obfs4 bridge deployment that was previously bundled with NipeX has been
split into its own guide to keep NipeX focused on CLI privacy tooling.

- Location: [Obfs4 — Deployment & Theory Guide](https://git.ricalnet.my.id/rical/digital-independence/wiki/Obfs4-%E2%80%94-Panduan-deployment-dan-Pemahaman-Teori)
- Container runtime: `podman-compose` (rootless) — no Docker daemon required
- Why moved:
  - Keeps NipeX dependency-light (no Docker/Compose required)
  - obfs4 bridge operation has its own lifecycle and security model
  - Podman's rootless mode is a better fit for privacy-focused deployments

If you need to run an obfs4 bridge, follow the guide above. NipeX will
continue to provide the `nipex start-tor` / `stop-tor` / `status-tor` commands
for routing traffic through the Tor network as the default gateway.

### Configuration

NipeX reads `~/.nipex.conf` if present. Supported variables:

| Variable | Purpose | Default |
|---|---|---|
| `NIPE_DIR` | Directory containing `nipe.pl` | `$SELF_DIR` |
| `NIPEX_LOG` | Enable logging (`1` = on, `0` = off) | `0` |
| `NIPEX_LOG_FILE` | Log file path | `$HOME/.nipex.log` |

Example `~/.nipex.conf`:

```bash
NIPE_DIR="/home/user/nipe"
NIPEX_LOG="0"
```

### Security Notes

- Logging is off by default (`NIPEX_LOG=0`) — this tool is designed for
  privacy, and writing logs to disk would defeat that purpose.
- `shred` is not effective on SSD/NVMe/CoW filesystems (btrfs, ZFS).
  NipeX prints a warning before wiping, but be aware of this limitation.
- `swap-off` is session-only and does not modify `/etc/fstab` or
  `dphys-swapfile`. Swap will return after reboot.
- `tmpfs` for `/tmp` is not persistent across reboots.
- `dns` may be overwritten by NetworkManager or `systemd-resolved` on reboot
  when falling back to `/etc/resolv.conf`.

### Migration Notes

#### v0.1 — CLI Rewrite

NipeX v0.1 rewrites the tool from an interactive menu into a CLI
subcommand interface. Several features were removed to keep the
tool focused and dependency-light:

| Old (v2.0 menu) | New (v0.1 CLI) |
|---|---|
| `manage_metadata` (mat2) | `nipex strip-meta` (exiftool) |
| `generate_password` | `nipex passwd` |
| `change_hostname` | `sudo nipex hostname` |
| `change_timezone` | `sudo nipex timezone` |
| `default_dns` | `sudo nipex dns` |
| `manage_mac` | `sudo nipex mac` / `sudo nipex mac-all` |
| `main_tools_menu` (Nipe) | `sudo nipex start-tor` / `stop-tor` / `status-tor` |
| `manage_obfs4` | Moved → [obfs4 guide](https://git.ricalnet.my.id/rical/digital-independence/wiki/Obfs4-%E2%80%94-Panduan-deployment-dan-Pemahaman-Teori) |
| `manage_firewall` (UFW) | Removed |
| `monitor_traffic` (tcpdump) | Removed |
| `run_rkhunter` | Removed |
| `check_file_integrity` | Removed |
| `service_status` | Removed |
| `system_monitor` (htop) | Removed |

New in v0.1:
- Anti-forensic: `wipe`, `wipe-tmp`, `wipe-history`, `wipe-cache`
- Crypto: `encrypt`, `decrypt`, `encrypt-dir`, `decrypt-dir`,
  `ssh-key`, `ssh-copy`, `ssh-add-auth`, `ssh-del-auth`
- Privacy: `swap-off`, `tmpfs`, `spoof-tz-env`, `history-disable`
- Fingerprint: `fingerprint`
- Config: `~/.nipex.conf` (`NIPE_DIR`, `NIPEX_LOG`, `NIPEX_LOG_FILE`)

### License

MIT — see [LICENSE.md](LICENSE.md).

NipeX is a fork of [Nipe](https://github.com/htrgouvea/nipe), which is also
MIT-licensed. Original Nipe copyright belongs to Heitor Gouvêa.