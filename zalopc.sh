#!/usr/bin/env bash
#
# Zalo Installer for Linux Mint
# Version: 2.2
# Author: Long Nguyen
#

set -e

PREFIX="$HOME/.wine-zalo"

GREEN="\033[1;32m"
RED="\033[1;31m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
NC="\033[0m"

echo -e "${BLUE}"
echo "========================================="
echo "      ZALO INSTALLER v2.2"
echo "========================================="
echo -e "${NC}"

echo -e "${YELLOW}>> Updating packages...${NC}"
sudo apt update

echo -e "${YELLOW}>> Enable i386...${NC}"
sudo dpkg --add-architecture i386

echo -e "${YELLOW}>> Installing required packages...${NC}"
sudo apt install -y \
gnupg \
curl \
wget \
ca-certificates \
software-properties-common

echo -e "${YELLOW}>> Configuring WineHQ repository...${NC}"

echo -e "${YELLOW}>> Removing old WineHQ configuration...${NC}"

sudo rm -f /etc/apt/sources.list.d/winehq-*.sources
sudo rm -f /etc/apt/keyrings/winehq-archive.*

sudo mkdir -p /etc/apt/keyrings

sudo rm -f /etc/apt/keyrings/winehq-archive.key
sudo rm -f /etc/apt/keyrings/winehq-archive.gpg

curl -fsSL https://dl.winehq.org/wine-builds/winehq.key \
| sudo gpg --dearmor -o /etc/apt/keyrings/winehq-archive.gpg

sudo wget -q -O /etc/apt/sources.list.d/winehq-noble.sources \
https://dl.winehq.org/wine-builds/ubuntu/dists/noble/winehq-noble.sources

sudo sed -i 's|winehq-archive.key|winehq-archive.gpg|g' \
/etc/apt/sources.list.d/winehq-noble.sources

sudo apt update

echo -e "${YELLOW}>> Installing WineHQ Stable...${NC}"

sudo apt install -y --install-recommends \
winehq-stable \
winetricks \
cabextract \
zenity \
wget \
curl \
unzip

echo -e "${YELLOW}>> Finding ZaloSetup.exe...${NC}"

INSTALLER="$HOME/Downloads/ZaloSetup.exe"

if [ ! -f "$INSTALLER" ]; then
    INSTALLER=$(zenity --file-selection \
        --title="Chọn file ZaloSetup.exe" \
        --filename="$HOME/" \
        --file-filter="*.exe")

    if [ -z "$INSTALLER" ]; then
        zenity --warning \
            --title="Zalo Installer" \
            --text="Bạn chưa chọn file cài đặt Zalo."
        exit 1
    fi
fi

echo -e "${YELLOW}>> Creating Wine Prefix...${NC}"

export WINEPREFIX="$PREFIX"
export WINEARCH=win64

if [ ! -d "$PREFIX" ]; then
    wineboot -u
fi

echo -e "${YELLOW}>> Setting Windows 10...${NC}"
winetricks -q win10

echo -e "${YELLOW}>> Installing Core Fonts...${NC}"
winetricks -q corefonts

echo -e "${YELLOW}>> Running Zalo Installer...${NC}"
wine "$INSTALLER"

echo
echo "Searching for Zalo.exe..."

sleep 3

ZALO_EXE=$(find "$PREFIX/drive_c/users/$USER/AppData/Local/Programs/Zalo" \
-type f -name "Zalo.exe" 2>/dev/null | grep -v "/plugins/" | head -n1)

if [ -z "$ZALO_EXE" ]; then
    zenity --error \
        --title="Zalo Installer" \
        --text="Không tìm thấy Zalo.exe.
Có thể bạn chưa hoàn tất cài đặt."
    exit 1
fi

echo "Found:"
echo "$ZALO_EXE"

########################################################################
# Desktop Shortcut
########################################################################

DESKTOP_DIR=$(xdg-user-dir DESKTOP 2>/dev/null || echo "$HOME/Desktop")
mkdir -p "$DESKTOP_DIR"

cat > "$DESKTOP_DIR/Zalo.desktop" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Zalo
Comment=Zalo Messenger
Exec=env WINEPREFIX=$PREFIX wine "$ZALO_EXE"
Icon=wine
Terminal=false
StartupNotify=true
Categories=Network;Chat;
EOF

chmod +x "$DESKTOP_DIR/Zalo.desktop"

rm -f "$DESKTOP_DIR/Zalo.lnk"
rm -f "$DESKTOP_DIR/Zalo.lnk.desktop"

########################################################################
# Linux Mint Menu
########################################################################

mkdir -p "$HOME/.local/share/applications"

cat > "$HOME/.local/share/applications/Zalo.desktop" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Zalo
Comment=Zalo Messenger
Exec=env WINEPREFIX=$PREFIX wine "$ZALO_EXE"
Icon=wine
Terminal=false
StartupNotify=true
Categories=Network;Chat;
EOF

chmod +x "$HOME/.local/share/applications/Zalo.desktop"

update-desktop-database "$HOME/.local/share/applications" >/dev/null 2>&1 || true

########################################################################
# Finish
########################################################################

zenity --info \
--width=420 \
--title="Zalo Installer" \
--text="🎉 Cài đặt Zalo hoàn tất!

✓ Đã tạo biểu tượng Desktop.

✓ Đã thêm vào Menu Linux Mint.

Bạn có thể mở Zalo từ Desktop hoặc Menu."

echo
echo "Done."