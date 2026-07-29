#!/usr/bin/env bash
# =============================================================================
#  NipeX extends Nipe with comprehensive privacy & security tools for Debian.
#  Repo   : https://github.com/ricalnet/nipex/
# =============================================================================
set -o pipefail

# ─────────────────────────── Configuration ──────────────────────────────────
readonly LOGFILE="$HOME/.nipex.log"
readonly VERSION="2.0"
readonly DEPENDENCIES=("macchanger" "mat2" "ufw" "tcpdump" "rkhunter" "htop" "openssl" "xclip")

# ─────────────────────────── Color Palette ──────────────────────────────────
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly BOLD='\033[1m'
readonly NC='\033[0m'

# ──────────────────────── Dynamic paths ─────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OBFS4_DIR="$SCRIPT_DIR/obfs4-docker"

# ─────────────────────────── Utility Functions ─────────────────────────────
log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "$LOGFILE"; }
info() { echo -e "${CYAN}[i]${NC} $*"; log "INFO: $*"; }
ok()  { echo -e "${GREEN}[✓]${NC} $*"; log "OK: $*"; }
warn(){ echo -e "${YELLOW}[!]${NC} $*" >&2; log "WARN: $*"; }
err() { echo -e "${RED}[✗]${NC} $*" >&2; log "ERROR: $*"; }
banner_msg() { echo -e "\n${BOLD}${BLUE}─── $* ───${NC}\n"; }

require_root() {
    if [[ $EUID -ne 0 ]]; then
        warn "This action requires root access. Requesting sudo..."
        sudo bash "$0" "$@"
        exit $?
    fi
}

not_empty() { [[ -n "$1" ]] && return 0 || return 1; }

spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while ps -p "$pid" > /dev/null 2>&1; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

press_enter() {
    echo
    read -rsp $'\033[0;35mPress Enter to continue...\033[0m'
    echo
}

ensure_deps() {
    local missing=()
    for cmd in "${DEPENDENCIES[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing+=("$cmd")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        warn "The following dependencies were not found: ${missing[*]}"
        read -rp "Install now? [Y/n] " ans
        if [[ "$ans" =~ ^[yY]?$ ]]; then
            sudo apt update -qq && sudo apt install -y "${missing[@]}" && \
                ok "All dependencies installed." || err "Failed to install dependencies."
        else
            warn "Some features may not work."
        fi
    fi
}

# ──────────────────────── Header Display ────────────────────────────────────
display_header() {
    clear
    echo -e "${CYAN}"
    cat << "EOF"
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
EOF
    echo -e "${NC}"
}

# ─────────────────────────── PRIVACY TOOLS ──────────────────────────────────

change_hostname() {
    display_header
    banner_msg "Change Hostname"
    local current
    current=$(hostname)
    info "Current hostname: ${BOLD}$current${NC}"
    read -rp "Enter new hostname (leave empty to cancel): " new_host
    if ! not_empty "$new_host"; then
        warn "Cancelled."
        press_enter
        return
    fi
    require_root
    read -rp "Confirm: change hostname to '$new_host'? [y/N] " confirm
    if [[ "$confirm" =~ ^[yY] ]]; then
        hostnamectl set-hostname "$new_host" && \
            ok "Hostname successfully changed to: $new_host" || \
            err "Failed to change hostname."
    else
        warn "Cancelled."
    fi
    press_enter
}

change_timezone() {
    display_header
    banner_msg "Change Timezone"
    local current
    current=$(timedatectl show --property=Timezone --value)
    info "Current timezone: ${BOLD}$current${NC}"
    echo -e "${CYAN}Searching for timezones... (press q to exit the list)${NC}"
    timedatectl list-timezones | less
    read -rp "Type the desired timezone (example: Asia/Jakarta): " tz
    if ! not_empty "$tz"; then
        warn "Cancelled."
        press_enter
        return
    fi
    require_root
    if timedatectl set-timezone "$tz" 2>/dev/null; then
        ok "Timezone successfully changed to $tz"
    else
        err "Timezone '$tz' is invalid."
    fi
    press_enter
}

default_dns() {
    display_header
    banner_msg "Set Default DNS (LibreDNS & Quad9)"
    info "DNS to be applied: ${BOLD}116.202.176.26 (LibreDNS), 9.9.9.9 (Quad9)${NC}"
    if command -v resolvectl >/dev/null 2>&1; then
        info "Current DNS (systemd-resolved):"
        resolvectl dns 2>/dev/null || true
    fi

    read -rp "Proceed to apply DNS? [Y/n] " apply
    if [[ ! "$apply" =~ ^[yY]?$ ]]; then
        warn "Cancelled."
        press_enter
        return
    fi

    require_root
    if command -v resolvectl >/dev/null 2>&1; then
        local iface
        iface=$(ip -o -4 route show default | awk '{print $5}' | head -1)
        if [[ -z "$iface" ]]; then
            warn "Cannot detect default interface."
            read -rp "Enter interface name (example: eth0, wlan0): " iface
        fi
        resolvectl dns "$iface" 116.202.176.26 9.9.9.9
        resolvectl domain "$iface" "~."
        ok "systemd-resolved DNS for $iface has been updated."
    else
        warn "systemd-resolved is not active. Modifying /etc/resolv.conf (may be overwritten by DHCP)."
        {
            echo "nameserver 116.202.176.26"
            echo "nameserver 9.9.9.9"
        } | sudo tee /etc/resolv.conf > /dev/null
        ok "/etc/resolv.conf updated."
    fi
    press_enter
}

manage_mac() {
    display_header
    banner_msg "MAC Address Management"
    check_dep macchanger
    info "Available network interfaces:"
    ip -o link show | awk -F': ' '!/lo/ {print $2}' | nl -w2 -s') '
    read -rp "Select interface (leave empty to cancel): " iface
    if ! not_empty "$iface"; then
        warn "Cancelled."
        press_enter
        return
    fi
    if ! ip link show "$iface" >/dev/null 2>&1; then
        err "Interface '$iface' not found."
        press_enter
        return
    fi

    echo "1) Random MAC"
    echo "2) Custom MAC"
    read -rp "Choice [1-2]: " mac_choice
    require_root

    case "$mac_choice" in
        1)
            sudo ifconfig "$iface" down
            sudo macchanger -r "$iface"
            sudo ifconfig "$iface" up
            ok "Random MAC applied to $iface."
            ;;
        2)
            read -rp "Enter MAC (format: 00:11:22:33:44:55): " mac_addr
            if [[ ! "$mac_addr" =~ ^([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}$ ]]; then
                err "Invalid MAC format."
                press_enter
                return
            fi
            sudo ifconfig "$iface" down
            sudo macchanger -m "$mac_addr" "$iface"
            sudo ifconfig "$iface" up
            ok "Custom MAC applied to $iface."
            ;;
        *)
            warn "Invalid choice."
            ;;
    esac
    press_enter
}

manage_metadata() {
    display_header
    banner_msg "Metadata Cleaning with MAT2"
    check_dep mat2
    read -rp "Enter target file/directory: " target
    if [[ ! -e "$target" ]]; then
        err "Location '$target' does not exist."
        press_enter
        return
    fi
    info "Cleaning metadata... (may take a while)"
    mat2 --inplace "$target" 2>&1 | tee /tmp/mat2.log | tail -5
    ok "Metadata cleaned. Full log: /tmp/mat2.log"
    press_enter
}

# ─────────────────────────── SECURITY TOOLS ──────────────────────────────────

check_file_integrity() {
    display_header
    banner_msg "File Integrity Check"
    read -rep "Enter file path: " fpath
    if [[ ! -f "$fpath" ]]; then
        err "File not found."
        press_enter
        return
    fi
    local hashfile="${fpath}.sha256"

    echo "1) Create SHA256 hash"
    echo "2) Verify with .sha256 file"
    read -rp "Choice [1-2]: " int_choice
    case "$int_choice" in
        1)
            sha256sum "$fpath" > "$hashfile"
            ok "Hash saved to $hashfile"
            ;;
        2)
            if [[ ! -f "$hashfile" ]]; then
                err "Hash file $hashfile not found. Create it first."
                press_enter
                return
            fi
            if sha256sum -c "$hashfile" --quiet 2>/dev/null; then
                ok "File integrity OK."
            else
                err "File has been modified!"
            fi
            ;;
        *)
            warn "Invalid choice."
            ;;
    esac
    press_enter
}

generate_password() {
    display_header
    banner_msg "Password Generator"
    read -rp "Password length (default 20): " length
    length=${length:-20}
    if ! [[ "$length" =~ ^[0-9]+$ ]] || [ "$length" -lt 4 ]; then
        err "Length must be a number >= 4."
        press_enter
        return
    fi
    local pass
    pass=$(openssl rand -base64 48 | tr -dc 'A-Za-z0-9!@#$%^&*()_+-=' | head -c "$length")
    echo -e "\n${GREEN}Password:${NC} ${BOLD}$pass${NC}\n"
    if command -v xclip >/dev/null 2>&1; then
        echo -n "$pass" | xclip -selection clipboard
        ok "Password copied to clipboard."
    fi
    press_enter
}

manage_firewall() {
    display_header
    banner_msg "Firewall Management (UFW)"
    check_dep ufw
    require_root
    while true; do
        echo -e "${BOLD}UFW Firewall${NC}"
        echo "--------------------------"
        echo "1) View status"
        echo "2) Enable firewall"
        echo "3) Disable firewall"
        echo "4) Allow port/service"
        echo "5) Block port/service"
        echo "6) Delete rule"
        echo "7) Reset UFW (careful!)"
        echo "8) Return to main menu"
        read -rp "Choose [1-8]: " fw_choice
        case "$fw_choice" in
            1) ufw status verbose; press_enter ;;
            2) ufw enable; ok "Firewall enabled."; press_enter ;;
            3) ufw disable; warn "Firewall disabled."; press_enter ;;
            4) read -rp "Port/service (example: 80/tcp, ssh): " rule
               ufw allow $rule && ok "Rule added." || err "Failed to add rule."
               press_enter ;;
            5) read -rp "Port/service (example: 80/tcp, ssh): " rule
               ufw deny $rule && ok "Rule added." || err "Failed to add rule."
               press_enter ;;
            6) ufw status numbered
               read -rp "Rule number to delete: " num
               ufw delete $num && ok "Rule deleted." || err "Failed to delete."
               press_enter ;;
            7) read -rp "Type 'YES' to reset all UFW rules: " conf
               if [[ "$conf" == "YES" ]]; then
                   ufw --force reset && ok "UFW reset to defaults." || err "Reset failed."
               else
                   warn "Reset cancelled."
               fi
               press_enter ;;
            8) break ;;
            *) warn "Invalid choice."; sleep 1 ;;
        esac
    done
}

monitor_traffic() {
    display_header
    banner_msg "Traffic Monitor with tcpdump"
    check_dep tcpdump
    info "Available interfaces:"
    ip -o link show | awk -F': ' '!/lo/ {print $2}' | nl -w2 -s') '
    read -rp "Interface (default: eth0): " iface
    iface=${iface:-eth0}
    read -rp "BPF filter (optional, example: 'port 80'): " filter
    require_root
    echo -e "${YELLOW}Starting capture... Press Ctrl+C to stop.${NC}"
    sleep 1
    if [[ -n "$filter" ]]; then
        sudo tcpdump -i "$iface" "$filter"
    else
        sudo tcpdump -i "$iface"
    fi
    ok "Capture complete."
    press_enter
}

run_rkhunter() {
    display_header
    banner_msg "Rootkit Hunter"
    check_dep rkhunter
    require_root
    echo "1) Scan system (--check-all)"
    echo "2) Update file properties database (--propupd)"
    read -rp "Choice [1-2]: " rk_choice
    case "$rk_choice" in
        1)
            info "Rootkit scan... (may take a few minutes)"
            sudo rkhunter --check-all &
            spinner $!
            ok "Scan complete. Results above."
            ;;
        2)
            sudo rkhunter --propupd
            ok "Properties database updated."
            ;;
        *)
            warn "Invalid choice."
            ;;
    esac
    press_enter
}

service_status() {
    display_header
    banner_msg "System Service Status"
    require_root
    if command -v systemctl >/dev/null 2>&1; then
        systemctl list-units --type=service --state=running --no-pager | less
    else
        sudo service --status-all 2>&1 | less
    fi
    press_enter
}

system_monitor() {
    display_header
    check_dep htop
    exec htop
}

# ─────────────────────────── MAIN TOOLS (NIPE) ──────────────────────────────
main_tools_menu() {
    display_header
    banner_msg "Main Tools - Nipe (Anonymity)"
    if [[ ! -f "./nipe.pl" ]]; then
        err "nipe.pl file not found in current directory."
        press_enter
        return
    fi
    while true; do
        echo -e "${BOLD}Nipe Control${NC}"
        echo "  1) Start Nipe"
        echo "  2) Stop Nipe"
        echo "  3) Restart Nipe"
        echo "  4) Status Nipe"
        echo "  0) Return to main menu"
        echo
        read -rp "Choose [0-4]: " nipe_choice
        case "$nipe_choice" in
            1) sudo perl nipe.pl start; press_enter ;;
            2) sudo perl nipe.pl stop; press_enter ;;
            3) sudo perl nipe.pl restart; press_enter ;;
            4) sudo perl nipe.pl status; press_enter ;;
            0) break ;;
            *) warn "Invalid choice."; sleep 1 ;;
        esac
    done
}

# ──────────────────────── DEPLOY OBFS4-DOCKER ───────────────────────────────
manage_obfs4() {
    display_header
    banner_msg "Deploy obfs4-Docker"

    # Basic checks
    if ! command -v docker >/dev/null 2>&1; then
        err "Docker is not installed. Please install Docker and Docker Compose first."
        press_enter
        return
    fi

    if [[ ! -d "$OBFS4_DIR" ]]; then
        err "obfs4-docker directory not found at: $OBFS4_DIR"
        press_enter
        return
    fi

    if [[ ! -f "$OBFS4_DIR/docker-compose.yml" ]]; then
        err "docker-compose.yml file not found inside $OBFS4_DIR"
        press_enter
        return
    fi

    while true; do
        echo -e "${BOLD}obfs4-Docker Control${NC}"
        echo "  1) Start  (docker compose up -d)"
        echo "  2) Stop   (docker compose down)"
        echo "  3) Restart(docker compose restart)"
        echo "  4) Logs   (docker compose logs -f)"
        echo "  5) Verify (./verify.sh)"
        echo "  0) Return to main menu"
        echo
        read -rp "Choose [0-5]: " obfs_choice

        case "$obfs_choice" in
            1)
                info "Starting obfs4 container..."
                (cd "$OBFS4_DIR" && docker compose up -d) && \
                    ok "obfs4 container is running." || err "Failed to start container."
                press_enter
                ;;
            2)
                info "Stopping obfs4 container..."
                (cd "$OBFS4_DIR" && docker compose down) && \
                    ok "obfs4 container stopped." || err "Failed to stop container."
                press_enter
                ;;
            3)
                info "Restarting obfs4 container..."
                (cd "$OBFS4_DIR" && docker compose restart) && \
                    ok "obfs4 container restarted." || err "Failed to restart container."
                press_enter
                ;;
            4)
                echo -e "${YELLOW}Showing logs (press Ctrl+C to exit)...${NC}"
                sleep 1
                (cd "$OBFS4_DIR" && docker compose logs -f)
                press_enter
                ;;
            5)
                info "Running verify.sh..."
                if [[ -x "$OBFS4_DIR/verify.sh" ]]; then
                    (cd "$OBFS4_DIR" && ./verify.sh)
                else
                    bash "$OBFS4_DIR/verify.sh"
                fi
                press_enter
                ;;
            0) break ;;
            *) warn "Invalid choice."; sleep 1 ;;
        esac
    done
}

# ─────────────────────────── MAIN MENU ─────────────────────────────────────
show_main_menu() {
    ensure_deps

    while true; do
        display_header
        echo -e "${BOLD}PRIVACY TOOLS${NC}"
        echo "  1) Change hostname"
        echo "  2) Change timezone"
        echo "  3) Set DNS (LibreDNS+Quad9)"
        echo "  4) MAC management (random/custom)"
        echo "  5) Remove file metadata (MAT2)"
        echo
        echo -e "${BOLD}SECURITY TOOLS${NC}"
        echo "  6) Check file integrity"
        echo "  7) Password generator"
        echo "  8) Firewall (UFW)"
        echo "  9) Monitor traffic (tcpdump)"
        echo " 10) Rootkit Hunter (rkhunter)"
        echo " 11) Service status"
        echo " 12) System monitor (htop)"
        echo
        echo -e "${BOLD}MAIN TOOLS${NC}"
        echo " 13) Main Tools (Nipe)"
        echo " 14) Deploy obfs4-Docker"
        echo
        echo "  0) Exit"
        echo
        read -rp "Select menu [0-14]: " choice
        case "$choice" in
            1) change_hostname ;;
            2) change_timezone ;;
            3) default_dns ;;
            4) manage_mac ;;
            5) manage_metadata ;;
            6) check_file_integrity ;;
            7) generate_password ;;
            8) manage_firewall ;;
            9) monitor_traffic ;;
            10) run_rkhunter ;;
            11) service_status ;;
            12) system_monitor ;;
            13) main_tools_menu ;;
            14) manage_obfs4 ;;
            0) echo -e "${GREEN}Goodbye!${NC}"; exit 0 ;;
            *) warn "Invalid choice. Try again."; sleep 1 ;;
        esac
    done
}

# ─────────────────────────── DIRECT CALL HANDLER ────────────────────────────
dispatch_tool() {
    case "$1" in
        change_hostname)     change_hostname ;;
        change_timezone)     change_timezone ;;
        default_dns)         default_dns ;;
        manage_mac)          manage_mac ;;
        manage_metadata)     manage_metadata ;;
        check_file_integrity) check_file_integrity ;;
        generate_password)   generate_password ;;
        manage_firewall)     manage_firewall ;;
        monitor_traffic)     monitor_traffic ;;
        rkhunter)            run_rkhunter ;;
        service_status)      service_status ;;
        system-monitor)      system_monitor ;;
        obfs4)               manage_obfs4 ;;
        help|--help|-h)
            echo "Usage: $0 [tool_name]"
            echo "Available tools:"
            echo "  Privacy : change_hostname, change_timezone, default_dns, manage_mac, manage_metadata"
            echo "  Security: check_file_integrity, generate_password, manage_firewall, monitor_traffic, rkhunter, service_status, system-monitor"
            echo "  Main    : nipe (only from interactive menu), obfs4 (deploy obfs4-docker)"
            ;;
        *)
            echo "Unknown tool: $1"
            echo "Run '$0 help' for a list of tools."
            exit 1
            ;;
    esac
}

# ─────────────────────────── MAIN ───────────────────────────────────────────
if [[ $# -eq 1 ]]; then
    dispatch_tool "$1"
else
    show_main_menu
fi