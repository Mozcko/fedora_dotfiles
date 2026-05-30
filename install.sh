#!/bin/bash

# ==============================================================================
# SCRIPT DE INSTALACIÓN AUTOMATIZADA PARA FEDORA (DEV & PERSONAL ENVIRONMENT)
# ==============================================================================

# Colores para logs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo -e "${BLUE}[*] Iniciando configuración completa de tu entorno en Fedora...${NC}"

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ==============================================================================
# 1. DETECCIÓN Y CONFIGURACIÓN DE DRIVERS NVIDIA
# ==============================================================================
if lspci | grep -i nvidia &> /dev/null; then
    echo -e "${YELLOW}[!] Tarjeta NVIDIA detectada. Configurando drivers propietarios...${NC}"
    sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
                        https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
    sudo dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda
else
    echo -e "${GREEN}[OK] No se detectó hardware NVIDIA.${NC}"
fi

# ==============================================================================
# 2. SANITIZACIÓN Y PURGA DE BLOATWARE
# ==============================================================================
echo -e "${BLUE}[*] Limpiando sistema y eliminando bloatware...${NC}"

sudo dnf remove -y libreoffice* mediawriter gnome-tour rhythmbox totem gnome-connections
sudo rm -f /etc/yum.repos.d/vscode.repo /etc/yum.repos.d/gh-cli.repo /etc/yum.repos.d/_copr:copr.fedorainfracloud.org:ulauncher:ulauncher.repo
rm -f "$HOME/.zshrc"
sudo dnf clean all
sudo dnf upgrade --refresh -y

# ==============================================================================
# 3. INSTALACIÓN DE PAQUETES (DNF)
# ==============================================================================
echo -e "${BLUE}[*] Instalando dependencias nativas...${NC}"
sudo dnf install -y --skip-unavailable \
    kitty zsh git curl wget unzip tar bat lsd fzf zoxide neovim ripgrep fd-find \
    util-linux-user gcc-c++ make python3-pip pipx java-latest-openjdk-devel npm \
    code gh gnome-tweaks gnome-extensions-app ulauncher podman \
    gnome-shell-extension-user-theme bibata-cursor-themes

# ==============================================================================
# 4. FLATPAK Y FLATHUB
# ==============================================================================
echo -e "${BLUE}[*] Configurando Flathub e instalando aplicaciones gráficas...${NC}"
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
sudo flatpak install -y flathub \
    com.opera.Opera com.rtosta.zapzap com.discordapp.Discord com.valvesoftware.Steam \
    com.getpostman.Postman io.podman_desktop.PodmanDesktop com.obsproject.Studio \
    org.kde.kdenlive org.inkscape.Inkscape org.audacityteam.Audacity com.jgraph.drawio.desktop \
    org.onlyoffice.desktopeditors eu.betterbird.Betterbird com.beavernotes.beavernotes \
    io.github.shiftey.Desktop com.parsecgaming.parsec

# ==============================================================================
# 5. CONFIGURACIÓN DE ENTORNO (FUENTES, NVCHAD, OH-MY-POSH)
# ==============================================================================
mkdir -p "$HOME/.local/share/fonts"
wget -P /tmp https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/FiraMono.zip
unzip -o /tmp/FiraMono.zip -d "$HOME/.local/share/fonts"
fc-cache -fv && rm /tmp/FiraMono.zip

NVIM_CONFIG="$HOME/.config/nvim"
rm -rf "$NVIM_CONFIG" "$HOME/.local/share/nvim"
git clone https://github.com/NvChad/starter "$NVIM_CONFIG"

mkdir -p "$HOME/.local/bin"
curl -s https://ohmyposh.dev/install.sh | bash -s -- -d ~/.local/bin

# ==============================================================================
# 6. PLUGINS Y LENGUAJES
# ==============================================================================
mkdir -p "$HOME/.zsh_plugins"
git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions "$HOME/.zsh_plugins/zsh-autosuggestions"
git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting "$HOME/.zsh_plugins/zsh-syntax-highlighting"
git clone --depth 1 https://github.com/zsh-users/zsh-completions "$HOME/.zsh_plugins/zsh-completions"

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install --lts && npm install -g pnpm

# ==============================================================================
# 7. TEMAS (GRAPHITE, REVERSAL) Y CONFIGURACIÓN GNOME
# ==============================================================================
mkdir -p "$HOME/.themes" "$HOME/.icons"
TEMP_THEMES="/tmp/fedora_themes"
mkdir -p "$TEMP_THEMES"

git clone https://github.com/vinceliuice/Graphite-gtk-theme.git "$TEMP_THEMES/graphite"
"$TEMP_THEMES/graphite/install.sh" --tweaks float colorful nord rimless -t teal -d "$HOME/.themes"

git clone https://github.com/yeyushengfan258/Reversal-icon-theme.git "$TEMP_THEMES/reversal"
"$TEMP_THEMES/reversal/install.sh" -a -d "$HOME/.icons"
rm -rf "$TEMP_THEMES"

# Copias permanentes de dotfiles (sin enlaces)
cp -f "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
cp -f "$DOTFILES_DIR/config/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf"
cp -f "$DOTFILES_DIR/config/ohmyposh/dev_mocha.toml" "$HOME/.config/ohmyposh/dev_mocha.toml"

# Kitty tema estático
curl -fsSL https://raw.githubusercontent.com/catppuccin/kitty/main/themes/mocha.conf -o "$HOME/.config/kitty/mocha.conf"
cat "$HOME/.config/kitty/mocha.conf" >> "$HOME/.config/kitty/kitty.conf"

# ==============================================================================
# 8. PREFERENCIAS Y CIERRE
# ==============================================================================
pipx install gnome-extensions-cli --force
~/.local/bin/gext install Vitals@CoreCoding.com logomenu@aryan_k space-bar@luchrioh

gsettings set org.gnome.shell favorite-apps "[]"
gsettings set org.gnome.desktop.interface gtk-theme 'Graphite-teal-Dark-nord'
gsettings set org.gnome.shell.extensions.user-theme name 'Graphite-teal-Dark-nord'
gsettings set org.gnome.desktop.interface icon-theme 'Reversal-dark'

systemctl --user enable --now podman.socket
chsh -s "$(which zsh)"

echo -e "${GREEN}=========================================================${NC}"
echo -e "${GREEN}  INSTALACIÓN FINALIZADA. POR FAVOR REINICIA TU EQUIPO.  ${NC}"
echo -e "${GREEN}=========================================================${NC}"
