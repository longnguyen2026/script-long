#!/usr/bin/env bash
#
# WinBoat Installer
# Author: LongNguyen2026
#

set -e

APP_NAME="WinBoat Installer"
VERSION="1.0"

GREEN='\033[1;32m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
RESET='\033[0m'

# ==========================
# CONFIG
# ==========================

# Thay bằng link Release của bạn
# WB_URL="https://github.com/longnguyen2026/winboat/releases/latest/download/WinBoat.deb"
WB_URL="https://github.com/longnguyen2026/winboat-installer/releases/latest/download/wb.deb"

# ==========================
# UI
# ==========================

banner() {
clear

echo -e "${CYAN}"
cat << "EOF"

 __          ___       _ ____              _
 \ \        / (_)     | |  _ \            | |
  \ \  /\  / / _ _ __ | | |_) | ___   __ _| |_
   \ \/  \/ / | | '_ \| |  _ < / _ \ / _` | __|
    \  /\  /  | | | | | | |_) | (_) | (_| | |_
     \/  \/   |_|_| |_|_|____/ \___/ \__,_|\__|

          Windows for Mint Installer

EOF
echo -e "${RESET}"

echo "Version : $VERSION"
echo
}

step() {
echo -e "${BLUE}==>${RESET} $1"
}

ok() {
echo -e "${GREEN}[ OK ]${RESET} $1"
}

warn() {
echo -e "${YELLOW}[WARN]${RESET} $1"
}

fail() {
echo -e "${RED}[FAIL]${RESET} $1"
exit 1
}

# ==========================
# ROOT
# ==========================

check_root(){

if [ "$EUID" -eq 0 ]; then
    fail "Please run as normal user."
fi

sudo -v

}

# ==========================
# INTERNET
# ==========================

check_net(){

step "Checking Internet..."

# if ping -c1 github.com >/dev/null 2>&1
if ping -c1 google.com >/dev/null 2>&1
then
    ok "Internet OK"
else
    fail "No Internet"
fi

}

# ==========================
# KVM
# ==========================

check_kvm(){

step "Checking KVM..."

if [ -e /dev/kvm ]
then
    ok "KVM detected"
else
    warn "KVM not found"
fi

}

# ==========================
# UPDATE
# ==========================

update_system(){

step "Updating packages..."

sudo apt update

}

# ==========================
# DOCKER
# ==========================

install_docker(){

    step "Installing Docker..."

    if command -v docker >/dev/null
    then
        ok "Docker already installed"
    else
        sudo apt install -y docker.io

        if ! command -v docker >/dev/null 2>&1; then
            fail "Unable to install Docker."
        fi
    fi

    sudo systemctl enable --now docker

    sudo usermod -aG docker "$USER"
    # ================
    # Install Docker Compose v2
    step "Installing Docker Compose..."
    
    if docker compose version >/dev/null 2>&1; then
        ok "Docker Compose v2 already installed"
    else
        if sudo apt install -y docker-compose-plugin; then
            ok "Docker Compose Plugin installed"
        elif sudo apt install -y docker-compose-v2; then
            ok "Docker Compose v2 installed"
        else
            warn "Docker Compose v2 package not found"
    
            # Install official Docker Compose plugin
            DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
            mkdir -p "$DOCKER_CONFIG/cli-plugins"
    
            ARCH=$(dpkg --print-architecture)
            case "$ARCH" in
                amd64) ARCH="x86_64" ;;
                arm64) ARCH="aarch64" ;;
            esac
    
            curl -fSL \
            "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-${ARCH}" \
            -o "$DOCKER_CONFIG/cli-plugins/docker-compose"
    
            chmod +x "$DOCKER_CONFIG/cli-plugins/docker-compose"
    
            export PATH="$DOCKER_CONFIG/cli-plugins:$PATH"
    
            if docker compose version >/dev/null 2>&1; then
                 ok "Docker Compose v2 installed"
            else
                warn "Docker Compose installation failed"
             fi
        fi
    fi
# ========================
    ok "Docker Ready"

}

# ==========================
# FREERDP
# ==========================

install_freerdp(){

step "Installing FreeRDP..."

if command -v xfreerdp >/dev/null
then
    ok "FreeRDP already installed"
else
   sudo apt install -y freerdp3-x11 || \
   sudo apt install -y freerdp2-x11 || \
   fail "Unable to install FreeRDP."
fi

}

# ==========================
# DOWNLOAD
# ==========================

download_winboat(){

step "Downloading WinBoat..."

cd /tmp

# wget -O WinBoat.deb "$WB_URL"
curl -fL "$WB_URL" -o /tmp/winboat_latest.deb
if ! dpkg-deb --info /tmp/winboat_latest.deb >/dev/null 2>&1
then
    fail "Downloaded file is not a valid Debian package."
fi

ok "Download completed"

}

# ==========================
# INSTALL
# ==========================

install_winboat(){

step "Installing WinBoat..."

#sudo apt install -y ./WinBoat.deb
sudo apt install -y /tmp/winboat_latest.deb
rm -f /tmp/winboat_latest.deb

ok "WinBoat Installed"


}

# ==========================
# FINISH
# ==========================

finish(){

echo
echo -e "${GREEN}"
echo "======================================="
echo
echo " Installation Completed!"
echo
echo " Launch WinBoat from menu"
echo
echo " Logout/Login once before first use."
echo
echo "======================================="
echo -e "${RESET}"

}

# ==========================
# MAIN
# ==========================

banner
check_root
check_net
check_kvm
update_system
install_docker
install_freerdp
download_winboat
install_winboat
finish
