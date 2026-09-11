<p align="center">
  <img src="https://heitorgouvea.me/images/projects/nipe/logo.png">
  <p align="center">A privacy & security toolkit built on top of Nipe.</p>
  <p align="center">
    <a href="/LICENSE.md">
      <img src="https://img.shields.io/badge/license-MIT-blue.svg">
    </a>
    <a href="#">
      <img src="https://img.shields.io/badge/version-0.1.2-blue.svg">
    </a>
  </p>
</p>

### Overview

NipeX (Nipe Extended) is a fork of [Nipe](https://github.com/htrgouvea/nipe) by Heitor Gouvêa, extended with additional privacy & security tools. Built for Debian-based systems (including Raspberry Pi OS), NipeX wraps Nipe's Tor gateway functionality together with a set of commands for encryption, anti-forensic cleanup, metadata stripping, MAC spoofing, and more — all from a single user-friendly CLI.

NipeX uses [Nipe](https://github.com/htrgouvea/nipe) as its Tor engine. When you run `nipex start-tor`, it calls the upstream `nipe.pl` script to route your traffic through the Tor network as the default gateway.

> The obfs4 bridge deployment feature that previously shipped with NipeX has been moved to a dedicated guide in the digital-independence wiki. See [Obfs4 — Deployment & Theory Guide](https://git.ricalnet.my.id/rical/digital-independence/wiki/Obfs4-%E2%80%94-Panduan-deployment-dan-Pemahaman-Teori). It now uses `podman-compose` (rootless) — no Docker daemon required.

### Privacy Mode

`privacy-on` is a one-command privacy session that applies 11 changes to the system, snapshots the original state in RAM, and auto-restores everything on reboot via a systemd unit. Non-persistent changes (MAC, swap, tmpfs, IPv6) reset automatically.

```bash
nipex privacy-on       # activate (snapshot + 11 changes)
nipex privacy-status   # check status + IPv6 state + manual steps
nipex privacy-off      # restore hostname + timezone + IPv6
```

What privacy-on does (11 steps):

| # | Action | Persistent? |
|---|---|---|
| 1 | Random Windows-style hostname (`DESKTOP-XXXXXXX`) | Snapshot-restored |
| 2 | Timezone → UTC | Snapshot-restored |
| 3 | DNS → LibreDNS + Quad9 | Session only |
| 4 | MAC randomization (all interfaces) | Auto-reset on reboot |
| 5 | IPv6 disable | Auto-reset on reboot |
| 6 | Swap off | Auto-reset on reboot |
| 7 | `/tmp` as tmpfs | Auto-reset on reboot |
| 8 | `spoof-tz-env` (prints `TZ=UTC` for shell) | Shell-only |
| 9 | `history-disable` (prints shell instructions) | Shell-only |
| 10 | Wipe shell history | Permanent |
| 11 | Wipe logs, journal, HSTS, zcompdump, editor histories | Permanent |

After privacy-on, manual steps required (shown at the end of the command output):

1. `source <(nipex history-disable-export)` — disable history in the current shell
2. `history -c && history -w` — clear in-memory history
3. `nipex start-tor` — change your IP via Tor (use `nipex restart-tor` if it fails)

Auto-restore: A systemd unit (`nipex-privacy-restore.service`) restores hostname and timezone on shutdown/reboot. Non-persistent changes reset on their own.

> Commands marked with `*` in `nipex help` require `sudo`. Commands marked with `◦` are included in `privacy-on`.

### Features

#### Privacy
| Command | Description |
|---|---|
| `privacy-on` `*` `◦` | Activate privacy mode (11 steps + snapshot) |
| `privacy-off` `*` | Restore hostname, timezone, IPv6 now |
| `privacy-status` | Show privacy mode status + IPv6 state |
| `privacy-restore` `*` | Internal — called by systemd on reboot |
| `hostname [name]` `*` `◦` | Change system hostname |
| `timezone [zone]` `*` `◦` | Change system timezone |
| `dns` `*` `◦` | Set DNS to LibreDNS + Quad9 |
| `mac [iface] [mac]` `*` | Randomize or set MAC address |
| `mac-all` `*` `◦` | Randomize MAC on all interfaces |
| `swap-off` `*` `◦` | Disable swap (session only, non-persistent) |
| `tmpfs` `*` `◦` | Mount `/tmp` as RAM (tmpfs) |
| `ipv6-disable` `*` `◦` | Disable IPv6 (sysctl, non-persistent) |
| `ipv6-enable` `*` | Re-enable IPv6 |

#### Privacy Extra
| Command | Description |
|---|---|
| `spoof-tz-env [zone]` `◦` | Print `TZ` export for current shell session |
| `history-disable` `◦` | Print commands to disable shell history |
| `history-disable-export` | Print shell commands (for `source <(...)`) |
| `strip-meta <file>` | Strip metadata from file (`exiftool`) |

#### Crypto
| Command | Description |
|---|---|
| `passwd [len]` | Generate password + Argon2id hash (default: 20 chars) |
| `ssh-key [name]` | Generate ed25519 SSH key |
| `ssh-copy [name]` | Copy public key to clipboard (`xclip`) |
| `ssh-add-auth [name]` | Add public key to `authorized_keys` |
| `ssh-del-auth [name]` | Remove public key from `authorized_keys` |
| `encrypt <file>` | Encrypt file with `age` (or `gpg` fallback) |
| `decrypt <file.age\|file.gpg>` | Decrypt file |
| `encrypt-dir <dir>` | Encrypt directory → `.tar.age` / `.tar.gpg` |
| `decrypt-dir <archive>` | Decrypt + extract directory archive |
| `vault-init <vault-dir>` | Initialize `gocryptfs` vault |
| `vault-mount <vault> [mnt]` | Mount `gocryptfs` vault |
| `vault-umount <mnt>` | Unmount `gocryptfs` vault |
| `vault-status` | List mounted `gocryptfs` vaults |

#### Anti-Forensic
| Command | Description |
|---|---|
| `wipe <path>` | Securely delete file/dir (`shred`) |
| `wipe-tmp` `*` | Wipe `/tmp` and `/var/tmp` |
| `wipe-history` `◦` | Wipe shell history files |
| `wipe-cache` | Wipe browser caches (Firefox, Chromium, Chrome, Brave) |
| `wipe-log` `*` `◦` | Wipe logs, journal, HSTS, zcompdump, editor histories |

#### Fingerprint
| Command | Description |
|---|---|
| `fingerprint` | Show HTTP fingerprint + local environment info |

#### Tor (via upstream Nipe)
| Command | Description |
|---|---|
| `install-tor` `*` | Install Nipe dependencies + run `nipe.pl install` |
| `start-tor` `*` | Start Nipe (route traffic through Tor) |
| `stop-tor` `*` | Stop Nipe |
| `restart-tor` `*` | Restart Nipe |
| `status-tor` `*` | Show Nipe status |

#### Other
| Command | Description |
|---|---|
| `help` / `version` | Show help / version |
| `install` `*` | Install `nipex` to `/usr/local/bin` |

### Requirements

- Debian-based system (Debian, Ubuntu, Raspberry Pi OS)
- `bash` 4.4+
- Root access via `sudo` for system-level commands

Optional dependencies (installed on demand by the relevant commands):

| Package | Used by |
|---|---|
| `macchanger` | `mac`, `mac-all` |
| `age` | `encrypt`, `encrypt-dir` (preferred) |
| `gpg` | fallback for `encrypt`, `encrypt-dir` |
| `xclip` | `ssh-copy` |
| `exiftool` | `strip-meta` (pkg: `libimage-exiftool-perl`) |
| `curl` | `fingerprint` |
| `argon2` | `passwd` |
| `gocryptfs` | `vault-init`, `vault-mount`, `vault-umount` |

### Download and Install

```bash
git clone https://git.ricalnet.my.id/rical/nipex.git
cd nipex

sudo apt update
sudo apt install -y \
    macchanger openssl curl gpg age argon2 gocryptfs \
    libimage-exiftool-perl xclip cpanminus

sudo cpanm --installdeps .

chmod +x nipex
./nipex install
nipex install-tor
```

The `install` command copies `nipex` to `/usr/local/bin/nipex` and saves `NIPE_DIR` to `~/.nipex.conf`.

### Usage

```bash
nipex <command> [args]
nipex help        # full list (legend: * = sudo, ◦ = in privacy-on)
```

#### Privacy Mode

```bash
# Activate privacy session (11 steps + snapshot + auto-restore)
nipex privacy-on

# After activation, run the manual steps printed at the end:
source <(nipex history-disable-export)
history -c && history -w
nipex start-tor
# if start-tor fails:
nipex restart-tor

# Check status anytime
nipex privacy-status

# Restore now (or just reboot for auto-restore)
nipex privacy-off
```

#### Individual Privacy Commands

```bash
nipex hostname workstation-01
nipex timezone Asia/Jakarta
nipex dns
nipex mac wlan0
nipex mac-all
nipex swap-off
nipex tmpfs
nipex ipv6-disable
nipex ipv6-enable

nipex spoof-tz-env Asia/Tokyo
nipex history-disable
source <(nipex history-disable-export)
nipex strip-meta photo.jpg
```

#### Crypto

```bash
# Password + Argon2id hash
nipex passwd 32

# SSH keys
nipex ssh-key id_ed25519
nipex ssh-copy id_ed25519
nipex ssh-add-auth id_ed25519
nipex ssh-del-auth id_ed25519

# File encryption
nipex encrypt secrets.txt
nipex decrypt secrets.txt.age

# Directory encryption (archive)
nipex encrypt-dir ~/projects/private
nipex decrypt-dir ~/projects/private.tar.age /tmp/restore

# Vault (gocryptfs)
nipex vault-init ~/vault-secret
nipex vault-mount ~/vault-secret
# → mountpoint default: ~/vault-secret.open
cp ~/Documents/secret.pdf ~/vault-secret.open/
nipex vault-umount ~/vault-secret.open
nipex vault-status
```

#### Anti-Forensic

```bash
nipex wipe ~/secret.txt
nipex wipe-tmp
nipex wipe-history
nipex wipe-cache
nipex wipe-log
```

#### Fingerprint

```bash
nipex fingerprint
```

#### Tor

```bash
nipex install-tor
nipex start-tor
nipex stop-tor
nipex restart-tor
nipex status-tor
```

### How Tor Integration Works

NipeX does **not** implement its own Tor client. It delegates to the upstream [Nipe](https://github.com/htrgouvea/nipe) project:

- `nipex install-tor` → `perl nipe.pl install`
- `nipex start-tor` → `perl nipe.pl start`
- `nipex stop-tor` → `perl nipe.pl stop`
- `nipex restart-tor` → `perl nipe.pl restart`
- `nipex status-tor` → `perl nipe.pl status`

For NipeX to find `nipe.pl`:

1. Place `nipex` in the same directory as `nipe.pl`, **or**
2. Set `NIPE_DIR` in `~/.nipex.conf`:
   ```bash
   NIPE_DIR="/path/to/nipe"
   ```

All credit for the Tor gateway logic goes to the Nipe project by Heitor Gouvêa.

### Obfs4 Bridge Deployment (Moved)

The obfs4 bridge deployment that was previously bundled with NipeX has been split into its own guide to keep NipeX focused on CLI privacy tooling.

- Location: [Obfs4 — Deployment & Theory Guide](https://git.ricalnet.my.id/rical/digital-independence/wiki/Obfs4-%E2%80%94-Panduan-deployment-dan-Pemahaman-Teori)
- Container runtime: `podman-compose` (rootless) — no Docker daemon required
- Why moved:
  - Keeps NipeX dependency-light (no Docker/Compose required)
  - obfs4 bridge operation has its own lifecycle and security model
  - Podman's rootless mode is a better fit for privacy-focused deployments

If you need to run an obfs4 bridge, follow the guide above. NipeX continues to provide the `nipex start-tor` / `stop-tor` / `status-tor` commands for routing traffic through the Tor network as the default gateway.

### Configuration

NipeX reads `~/.nipex.conf` if present.

| Variable | Purpose | Default |
|---|---|---|
| `NIPE_DIR` | Directory containing `nipe.pl` | `$SELF_DIR` |
| `NIPEX_LOG` | Enable logging (`1` = on, `0` = off) | `0` |
| `NIPEX_LOG_FILE` | Log file path | `$HOME/.nipex.log` |

Example:

```bash
NIPE_DIR="/home/user/nipe"
NIPEX_LOG="0"
```

### Security Notes

- **Logging is off by default** (`NIPEX_LOG=0`) — writing logs to disk defeats the purpose of a privacy tool.
- **`shred` is not effective on SSD/NVMe/CoW filesystems** (btrfs, ZFS). NipeX prints a warning before wiping.
- **`swap-off` is session-only** — does not modify `/etc/fstab` or `dphys-swapfile`. Swap returns after reboot.
- **`tmpfs` for `/tmp` is not persistent** across reboots.
- **`ipv6-disable` is session-only** — resets on reboot.
- **`dns` may be overwritten** by NetworkManager or `systemd-resolved` on reboot when falling back to `/etc/resolv.conf`.
- **`privacy-on` does NOT change your IP** — you must run `nipex start-tor` manually. This is by design (explicit control over Tor).
- **`vault-init` prints a master key** — save it offline. It is the only recovery method if you forget the password. Lost password = lost data.
- **`wipe-log` requires sudo** for `/var/log` and `journalctl`. It truncates active logs (safe for services) and deletes rotated logs.
- **`privacy-on` wipes shell history and logs permanently.** This cannot be undone. Manual steps (`history -c && history -w`, `source <(...)`) must be run by you — the script cannot affect your parent shell.

### Migration Notes

#### v0.1 — CLI Rewrite

NipeX v0.1 rewrites the tool from an interactive menu into a CLI subcommand interface. Several features were removed to keep the tool focused and dependency-light:

| Old (v2.0 menu) | New (v0.1 CLI) |
|---|---|
| `manage_metadata` (mat2) | `nipex strip-meta` (exiftool) |
| `generate_password` | `nipex passwd` (Argon2id) |
| `change_hostname` | `nipex hostname` |
| `change_timezone` | `nipex timezone` |
| `default_dns` | `nipex dns` |
| `manage_mac` | `nipex mac` / `nipex mac-all` |
| `main_tools_menu` (Nipe) | `nipex start-tor` / `stop-tor` / `status-tor` |
| `manage_obfs4` | Moved → [obfs4 guide](https://git.ricalnet.my.id/rical/digital-independence/wiki/Obfs4-%E2%80%94-Panduan-deployment-dan-Pemahaman-Teori) |
| `manage_firewall` (UFW) | Removed |
| `monitor_traffic` (tcpdump) | Removed |
| `run_rkhunter` | Removed |
| `check_file_integrity` | Removed |
| `service_status` | Removed |
| `system_monitor` (htop) | Removed |

#### v0.1.2 — Privacy Mode + IPv6

- **New:** `privacy-on` / `privacy-off` / `privacy-status` / `privacy-restore` — one-command privacy session with snapshot + auto-restore
- **New:** `ipv6-disable` / `ipv6-enable` — session-only IPv6 control
- **New:** help legend `◦` — marks commands included in `privacy-on`
- **Changed:** Tor is no longer auto-started by `privacy-on` — user runs `nipex start-tor` manually (explicit IP control)
- **Improved:** `passwd` uses Argon2id (via `argon2` CLI) instead of plaintext only
- **Improved:** `wipe-cache` also covers Brave (`Brave-Browser` / `Brave-Origin`)
- **Improved:** `wipe-log` also wipes HSTS, zcompdump, and editor histories

**New in v0.1.2:**
- Privacy mode: `privacy-on`, `privacy-off`, `privacy-status`, `privacy-restore`
- IPv6: `ipv6-disable`, `ipv6-enable`
- Crypto: `vault-init`/`vault-mount`/`vault-umount`/`vault-status` (gocryptfs), `passwd` (Argon2id)
- Anti-forensic: `wipe-log` (logs, journal, HSTS, zcompdump, editor histories)
- Privacy extra: `spoof-tz-env`, `history-disable`, `strip-meta`

### License

MIT — see [LICENSE.md](LICENSE.md).

NipeX is a fork of [Nipe](https://github.com/htrgouvea/nipe), which is also MIT-licensed. Original Nipe copyright belongs to Heitor Gouvêa.