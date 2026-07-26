#!/usr/bin/env bash
#
# Zalo Installer for Linux Mint: version 2.0
# Author: Long Nguyen
#

set -e

PREFIX="$HOME/.wine-zalo"
ZALO="$HOME/Downloads/ZaloSetup.exe"

GREEN="\033[1;32m"
RED="\033[1;31m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
NC="\033[0m"

echo -e "${BLUE}"
echo "========================================="
echo "      ZALO INSTALLER v2.1"
echo "========================================="
echo -e "${NC}"

echo -e "${YELLOW}>> Updating packages...${NC}"
sudo apt update

echo -e "${YELLOW}>> Enable i386...${NC}"
sudo dpkg --add-architecture i386

sudo mkdir -p /etc/apt/keyrings

if [ ! -f /etc/apt/keyrings/winehq-archive.key ]; then
    sudo wget -q -O /etc/apt/keyrings/winehq-archive.key \
    https://dl.winehq.org/wine-builds/winehq.key
fi

if [ ! -f /etc/apt/sources.list.d/winehq-noble.sources ]; then
    sudo wget -q -O /etc/apt/sources.list.d/winehq-noble.sources \
    https://dl.winehq.org/wine-builds/ubuntu/dists/noble/winehq-noble.sources
fi

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

if [ ! -f "$ZALO" ]; then
    zenity --error \
    --title="Zalo Installer" \
    --text="Không tìm thấy:\n$ZALO"
    exit 1
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
wine "$ZALO"

echo
echo "Searching for Zalo.exe..."

sleep 3

ZALO_EXE=$(find "$PREFIX/drive_c/users/$USER/AppData/Local/Programs/Zalo" \
-type f -name "Zalo.exe" 2>/dev/null | grep -v "/plugins/" | head -n1)

if [ -z "$ZALO_EXE" ]; then
    zenity --error \
        --title="Zalo Installer" \
        --text="Không tìm thấy Zalo.exe.\nCó thể bạn chưa hoàn tất cài đặt."
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
