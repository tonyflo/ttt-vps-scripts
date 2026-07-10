#!/bin/bash

SCRIPT_VERSION="v1.3"
# ==============================================================================
# Tony Teaches Tech's VPS Setup Script
# ==============================================================================
# This script is designed to take a freshly provisioned Ubuntu or Debian VPS
# and secure it while preparing it for Docker-based deployments.
#
# EXACTLY WHAT THIS SCRIPT DOES:
# 0. Initial Checks: Ensures the script is run as root and verifies that
#    the OS supports apt-get and systemd before proceeding.
# 1. User Setup: Prompts to create a new non-root user, asks you to set a
#    password, and adds them to the sudo group.
# 2. SSH Hardening: Disables password-based root login while keeping password
#    and public-key authentication enabled.
# 3. System Updates: Updates package lists and upgrades all system packages.
# 4. Core Utilities & Security: Installs essential tools (ufw, curl, wget, git,
#    ca-certificates, gnupg, htop) and starts Fail2Ban to block malicious IPs.
# 5. Auto-Patching: Installs and configures 'unattended-upgrades' to
#    automatically apply security updates.
# 6. Firewall Lockdown: Enables UFW, denying all incoming traffic by default,
#    allowing outgoing traffic, and explicitly allowing SSH.
# 7. Docker Engine: Fetches the official Docker installation script, installs
#    Docker, enables the systemd service, and adds the new user to the 'docker'
#    group so containers can be run without 'sudo'.
# 8. Final Output: Dynamically fetches the server's public IP, prints
#    login instructions for the new user, and detects if a system reboot is
#    required.
#
# SAFETY & LOGGING:
# This script is idempotent (safe to run multiple times). It backs up your SSH
# config before modifying it. All verbose installation output is cleanly
# redirected to /var/log/vps-setup.log to keep the terminal clean.
# ==============================================================================

set -uo pipefail

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

LOG_FILE="/var/log/vps-setup.log"
echo "Starting TTT VPS Setup ($SCRIPT_VERSION)..." > "$LOG_FILE"

die() {
    echo -e "\n${RED}❌ ERROR: $1${NC}"
    echo -e "${RED}Script aborted. Check log for possible details: cat $LOG_FILE${NC}"
    exit 1
}

step() {
    echo -e "\n${BLUE}====================================================${NC}"
    echo -e "${BLUE}[$1] $2${NC}"
    echo -e "${BLUE}====================================================${NC}"
}

ok() {
    echo -e "   ${GREEN}✔ Done${NC}"
}

info() {
    echo -e "   ${YELLOW}$1${NC}"
}

# Wait for background apt processes to release the dpkg lock
wait_for_apt() {
    if command -v fuser >/dev/null 2>&1; then
        while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 || fuser /var/lib/dpkg/lock >/dev/null 2>&1; do
            info "Waiting for background apt processes to finish..."
            sleep 5
        done
    fi
}

# ============================================================
# 0. INITIAL CHECKS
# ============================================================

[ "$EUID" -ne 0 ] && die "Run with: sudo bash setup-docker.sh"

command -v apt-get >/dev/null 2>&1 || die "Unsupported OS (Debian/Ubuntu required)"
command -v systemctl >/dev/null 2>&1 || die "Systemd required"

# ============================================================
# HEADER
# ============================================================

echo -e "${BLUE}====================================================${NC}"
echo -e "${GREEN}   VPS Setup Script ${SCRIPT_VERSION} by Tony Teaches Tech${NC}"
echo -e "${BLUE}====================================================${NC}"
echo
echo "On a fresh VPS instance, this script:"
echo "- Creates a new user"
echo "- Makes SSH access more secure"
echo "- Updates the system"
echo "- Installs recommended packages"
echo "- Enables automatic security updates"
echo "- Deny incoming traffic except SSH with UFW"
echo "- Installs Docker"

# ============================================================
# 1. USER SETUP
# ============================================================

step "1/7" "Create a new user"

while true; do
    read -r -p "Enter username (default: noname): " NEW_USER </dev/tty

    if [ -z "${NEW_USER:-}" ]; then
        NEW_USER="noname"
        info "Using default user: noname"
    fi

    NEW_USER=$(echo "$NEW_USER" | tr '[:upper:]' '[:lower:]')

    if [[ "$NEW_USER" =~ ^(root|admin|ubuntu|daemon)$ ]]; then
        info "Error: '$NEW_USER' is a reserved name. Try again."
        continue
    fi

    if [[ ! "$NEW_USER" =~ ^[a-z][a-z0-9_-]{0,31}$ ]]; then
        info "Error: Invalid format. Must start with a letter and contain no spaces."
        continue
    fi

    break
done

if id "$NEW_USER" &>/dev/null; then
    info "User '$NEW_USER' already exists"
else
    adduser "$NEW_USER" </dev/tty \
        || die "Failed to create user '$NEW_USER'"
    info "Created user '$NEW_USER'"
fi

usermod -aG sudo "$NEW_USER" \
    || die "Failed to add '$NEW_USER' to sudo group"

info "Added user '$NEW_USER' to sudo group"

ok

# ============================================================
# 2. SSH SAFETY
# ============================================================

step "2/7" "Secure SSH"

SSH_CONFIG="/etc/ssh/sshd_config"
SSH_BACKUP="/etc/ssh/sshd_config.bak"
SSH_DROP_IN="/etc/ssh/sshd_config.d/10-ttt.conf"

if [ ! -f "$SSH_BACKUP" ]; then
    cp "$SSH_CONFIG" "$SSH_BACKUP" \
        || die "Failed to back up SSH config"

    info "Backed up SSH config"
fi

cat > "$SSH_DROP_IN" <<EOF || die "Failed to write SSH configuration"
PermitRootLogin prohibit-password
PasswordAuthentication yes
PubkeyAuthentication yes
EOF

if ! sshd -t; then
    rm -f "$SSH_DROP_IN"
    die "Invalid SSH configuration"
fi

if [ "$(sshd -T | awk '$1 == "passwordauthentication" {print $2}')" != "yes" ]; then
    rm -f "$SSH_DROP_IN"
    die "Password authentication is being overridden by another SSH configuration"
fi

systemctl restart ssh 2>/dev/null \
    || systemctl restart sshd \
    || die "Failed to restart SSH"

info "Secured and restarted SSH"

ok

# ============================================================
# 3. SYSTEM UPDATE
# ============================================================

step "3/7" "Updating system"

wait_for_apt
apt-get update -qq >> "$LOG_FILE" 2>&1 || die "apt update failed"
info "Updated package lists"

wait_for_apt
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -qq >> "$LOG_FILE" 2>&1 || die "upgrade failed"
info "Upgraded system packages"

ok

# ============================================================
# 4. RECOMMENDED PACKAGES
# ============================================================

step "4/7" "Installing recommended packages"

PACKAGES="ufw curl wget git ca-certificates gnupg fail2ban htop"

wait_for_apt
DEBIAN_FRONTEND=noninteractive apt-get install -y $PACKAGES \
>> "$LOG_FILE" 2>&1 || die "package install failed"

systemctl enable --now fail2ban >> "$LOG_FILE" 2>&1 \
    || die "Failed to enable or start Fail2Ban"

info "Installed the following packages:"
for pkg in $PACKAGES; do
    echo -e "   ${YELLOW}- $pkg${NC}"
done

ok

# ============================================================
# 5. SECURITY UPDATES
# ============================================================

step "5/7" "Enabling automatic security updates"

wait_for_apt
DEBIAN_FRONTEND=noninteractive apt-get install -y unattended-upgrades \
>> "$LOG_FILE" 2>&1 || die "failed to install unattended-upgrades"

echo unattended-upgrades unattended-upgrades/enable_auto_updates boolean true | debconf-set-selections \
    >> "$LOG_FILE" 2>&1 || die "failed to configure unattended-upgrades"

DEBIAN_FRONTEND=noninteractive dpkg-reconfigure -f noninteractive unattended-upgrades \
    >> "$LOG_FILE" 2>&1 \
    || die "failed to enable unattended-upgrades"

info "Enabled automatic security updates"

ok

# ============================================================
# 6. FIREWALL
# ============================================================

step "6/7" "Configuring ufw firewall"

ufw default deny incoming >> "$LOG_FILE" 2>&1 || die "ufw deny incoming failed"
info "Set default policy: Deny incoming"

ufw default allow outgoing >> "$LOG_FILE" 2>&1 || die "ufw allow outgoing failed"
info "Set default policy: Allow outgoing"

ufw allow OpenSSH >> "$LOG_FILE" 2>&1 || die "ufw ssh rule failed"
info "Allowed only SSH traffic"

ufw --force enable >> "$LOG_FILE" 2>&1 || die "ufw enable failed"
info "Enabled UFW firewall"

ok

# ============================================================
# 7. DOCKER
# ============================================================

step "7/7" "Installing Docker"

if ! command -v docker >/dev/null 2>&1; then
    curl -fsSL https://get.docker.com -o /tmp/docker.sh \
        >> "$LOG_FILE" 2>&1 \
        || die "docker download failed"

    info "Downloaded Docker install script"

    wait_for_apt
    sh /tmp/docker.sh >> "$LOG_FILE" 2>&1 \
        || die "docker install failed"

    info "Installed Docker Engine"
else
    info "Docker already installed"
fi

systemctl enable --now docker >> "$LOG_FILE" 2>&1 \
    || die "Docker service start failed"

info "Started Docker daemon"

usermod -aG docker "$NEW_USER" >> "$LOG_FILE" 2>&1 || die "docker group add failed"
info "Added user '$NEW_USER' to docker group"

ok

# ============================================================
# FINAL OUTPUT
# ============================================================

echo -e "\n${BLUE}====================================================${NC}"
echo -e "${GREEN}            🎉 SETUP COMPLETE                       ${NC}"
echo -e "${BLUE}====================================================${NC}\n"

IP=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}')
[ -z "$IP" ] && IP=$(hostname -I | awk '{print $1}')
[ -z "$IP" ] && IP="YOUR_SERVER_IP"

echo "🚨 IMPORTANT NEXT STEPS:"
echo -e "⚠ Log out and reconnect before running Docker as the new user.\n"

if [ -f /var/run/reboot-required ]; then
    echo -e "${YELLOW}Reboot required. Server restarting in 5 seconds...${NC}"
    echo -e "Once it boots up, reconnect using: ${GREEN}ssh $NEW_USER@$IP${NC}\n"
    sleep 5
    reboot
else
    echo "1. Type 'exit' to log out of this root session."
    echo -e "2. Reconnect using: ${GREEN}ssh $NEW_USER@$IP${NC}\n"
fi
