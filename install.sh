#!/bin/bash

# ==============================================================================
# SCRIPT DE INSTALACIÓN AUTOMATIZADA PARA FEDORA (DEV & PERSONAL ENVIRONMENT)
# Incluye: Purga de Bloatware, Zsh, OhMyPosh, Kitty, NvChad, Lenguajes, Apps 
#          (DNF/Flatpak), Temas Visuales, Extensiones y Preferencias de Sistema.
# ==============================================================================

# Colores para logs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}[*] Iniciando configuración completa de tu entorno en Fedora...${NC}"

# Detecta dinámicamente la ruta física real donde reside este script
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ==============================================================================
# 0. SANITIZACIÓN PREVIA (IDEMPOTENCIA)
# ==============================================================================
echo -e "${BLUE}[*] Limpiando caché y repositorios de intentos previos...${NC}"

# Eliminar cualquier rastro de repositorios externos conflictivos o rotos
sudo rm -f /etc/yum.repos.d/shiftkey-packages.repo
sudo rm -f /etc/yum.repos.d/gh-cli.repo
sudo rm -f /etc/yum.repos.d/vscode.repo
sudo rm -f /etc/yum.repos.d/_copr:copr.fedorainfracloud.org:ulauncher:ulauncher.repo

# Asegurar la eliminación de enlaces simbólicos rotos previos en el Home si existen
rm -f "$HOME/.zshrc"

# Limpiar la caché de DNF por completo
sudo dnf clean all

# ==============================================================================
# 1. PURGA DE BLOATWARE
# ==============================================================================
echo -e "${BLUE}[*] Eliminando Bloatware de Fedora (LibreOffice, GNOME Tour, etc.)...${NC}"

sudo dnf remove -y \
    libreoffice* \
    mediawriter \
    gnome-tour \
    rhythmbox \
    totem \
    gnome-connections

# ==============================================================================
# 2. CONFIGURACIÓN DE REPOSITORIOS EXTERNOS
# ==============================================================================
echo -e "${BLUE}[*] Configurando repositorios de software externos oficiales...${NC}"

# Repositorio oficial de Visual Studio Code
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'

# Repositorio oficial de GitHub CLI (Descarga directa del .repo)
sudo curl -fsSL https://cli.github.com/packages/rpm/gh-cli.repo -o /etc/yum.repos.d/gh-cli.repo

echo -e "${BLUE}[*] Refrescando repositorios del sistema...${NC}"
sudo dnf upgrade --refresh -y

# ==============================================================================
# 3. INSTALACIÓN DE PAQUETES DEL SISTEMA (DNF)
# ==============================================================================
echo -e "${BLUE}[*] Instalando aplicaciones y dependencias nativas vía DNF...${NC}"

sudo dnf install -y --skip-unavailable \
    kitty zsh git curl wget unzip tar bat lsd fzf zoxide neovim ripgrep fd-find \
    util-linux-user gcc-c++ make python3-pip pipx java-latest-openjdk-devel npm \
    code gh gnome-tweaks gnome-extensions-app ulauncher podman \
    gnome-shell-extension-user-theme bibata-cursor-themes

# ==============================================================================
# 4. INSTALACIÓN DE APLICACIONES EN RÁFAGA (FLATPAK VIA FLATHUB)
# ==============================================================================
echo -e "${BLUE}[*] Configurando Flathub e instalando aplicaciones gráficas...${NC}"
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

sudo flatpak install -y flathub \
    com.opera.Opera \
    com.rtosta.zapzap \
    com.discordapp.Discord \
    com.valvesoftware.Steam \
    com.getpostman.Postman \
    io.podman_desktop.PodmanDesktop \
    com.obsproject.Studio \
    org.kde.kdenlive \
    org.inkscape.Inkscape \
    org.audacityteam.Audacity \
    com.jgraph.drawio.desktop \
    org.onlyoffice.desktopeditors \
    eu.betterbird.Betterbird \
    com.beavernotes.beavernotes \
    io.github.shiftey.Desktop \
    com.parsecgaming.parsec

# ==============================================================================
# 5. FUENTES (FiraMono Nerd Font)
# ==============================================================================
FONT_DIR="$HOME/.local/share/fonts"
if [ ! -d "$FONT_DIR/FiraMono" ]; then
    echo -e "${BLUE}[*] Instalando FiraMono Nerd Font...${NC}"
    mkdir -p "$FONT_DIR"
    wget -P /tmp https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/FiraMono.zip
    unzip -o /tmp/FiraMono.zip -d "$FONT_DIR"
    fc-cache -fv
    rm /tmp/FiraMono.zip
else
    echo -e "${GREEN}[OK] Las fuentes Nerd Fonts ya están configuradas.${NC}"
fi

# ==============================================================================
# 6. CONFIGURACIÓN DE NVCHAD (NEOVIM)
# ==============================================================================
NVIM_CONFIG="$HOME/.config/nvim"
if [ ! -d "$NVIM_CONFIG/.git" ]; then
    echo -e "${BLUE}[*] Clonando NvChad...${NC}"
    rm -rf "$NVIM_CONFIG" "$HOME/.local/share/nvim"
    git clone https://github.com/NvChad/starter "$NVIM_CONFIG"
fi

# ==============================================================================
# 7. OH MY POSH
# ==============================================================================
if ! command -v oh-my-posh &> /dev/null; then
    echo -e "${BLUE}[*] Instalando Oh My Posh...${NC}"
    mkdir -p "$HOME/.local/bin"
    curl -s https://ohmyposh.dev/install.sh | bash -s -- -d ~/.local/bin
fi

# ==============================================================================
# 8. PLUGINS DE ZSH
# ==============================================================================
echo -e "${BLUE}[*] Descargando plugins globales de Zsh...${NC}"
PLUGIN_DIR="$HOME/.zsh_plugins"
mkdir -p "$PLUGIN_DIR"

install_plugin() {
    if [ ! -d "$PLUGIN_DIR/$(basename $1)" ]; then
        git clone --depth 1 "https://github.com/$1.git" "$PLUGIN_DIR/$(basename $1)"
    fi
}
install_plugin "zsh-users/zsh-autosuggestions"
install_plugin "zsh-users/zsh-syntax-highlighting"
install_plugin "zsh-users/zsh-completions"

# ==============================================================================
# 9. GESTIÓN DE LENGUAJE (NVM, NODE, PNPM)
# ==============================================================================
export NVM_DIR="$HOME/.nvm"
if [ ! -d "$NVM_DIR" ]; then
    echo -e "${BLUE}[*] Configurando entorno Node con NVM...${NC}"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm install --lts
    nvm use --lts
    npm install -g pnpm
else
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
fi

# ==============================================================================
# 10. INSTALACIÓN AUTOMÁTICA DE EXTENSIONES DE GNOME
# ==============================================================================
echo -e "${BLUE}[*] Configurando inyector automatizado de GNOME Extensions...${NC}"
pipx install gnome-extensions-cli --force
export PATH="$PATH:$HOME/.local/bin"

~/.local/bin/gext install Vitals@CoreCoding.com
~/.local/bin/gext install logomenu@aryan_k
~/.local/bin/gext install space-bar@luchrioh

# ==============================================================================
# 11. DESCARGA E INYECCIÓN DE TEMAS (GRAPHITE CUSTOM LAYOUT, REVERSAL)
# ==============================================================================
echo -e "${BLUE}[*] Configurando temas visuales personalizados...${NC}"
mkdir -p "$HOME/.themes" "$HOME/.icons"
TEMP_THEMES="/tmp/fedora_themes"
mkdir -p "$TEMP_THEMES"

# Compilación exacta con tus tweaks favoritos (float, colorful, nord, rimless, teal)
echo -e "${BLUE}[*] Compilando e instalando Graphite Layout en modo Islas Flotantes...${NC}"
rm -rf "$HOME/.themes/Graphite-teal-Dark-nord"
git clone https://github.com/vinceliuice/Graphite-gtk-theme.git "$TEMP_THEMES/graphite"
"$TEMP_THEMES/graphite/install.sh" --tweaks float colorful nord rimless -t teal -d "$HOME/.themes"

# Iconos Reversal Dark
if [ ! -d "$HOME/.icons/Reversal-dark" ]; then
    git clone https://github.com/yeyushengfan258/Reversal-icon-theme.git "$TEMP_THEMES/reversal"
    "$TEMP_THEMES/reversal/install.sh" -a -d "$HOME/.icons"
fi
rm -rf "$TEMP_THEMES"

# Forzar Flatpak a heredar temas e iconos del sistema
sudo flatpak override --env=GTK_THEME=Graphite-teal-Dark-nord
sudo flatpak override --env=ICON_THEME=Reversal-dark
sudo flatpak override --filesystem=$HOME/.themes
sudo flatpak override --filesystem=$HOME/.icons

# ==============================================================================
# 12. COPIA DE CONFIGURACIONES (CERO ENLACES SIMBÓLICOS)
# ==============================================================================
echo -e "${BLUE}[*] Copiando tus dotfiles de forma permanente...${NC}"

mkdir -p "$HOME/.config/kitty"
mkdir -p "$HOME/.config/ohmyposh"

# Copias duras (independientes del repositorio)
cp -f "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
cp -f "$DOTFILES_DIR/config/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf"
cp -f "$DOTFILES_DIR/config/ohmyposh/dev_mocha.toml" "$HOME/.config/ohmyposh/dev_mocha.toml"

# FIX DE KITTY DESDE ORIGEN OFICIAL (Aislado e independiente de tu repositorio local)
echo -e "${BLUE}[*] Descargando paleta oficial de Catppuccin Mocha para Kitty...${NC}"
curl -fsSL https://raw.githubusercontent.com/catppuccin/kitty/main/themes/mocha.conf -o "$HOME/.config/kitty/mocha.conf"
cp -f "$HOME/.config/kitty/mocha.conf" "$HOME/.config/kitty/current-theme.conf"

# ==============================================================================
# 13. APLICACIÓN DE PREFERENCIAS, IDIOMAS Y KEYBINDINGS DE GNOME
# ==============================================================================
echo -e "${BLUE}[*] Inyectando tus configuraciones de dconf/gsettings...${NC}"

# Vaciar completamente la barra de tareas (Dash de GNOME)
gsettings set org.gnome.shell favorite-apps "[]"

gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'us'), ('xkb', 'latam')]"
gsettings set org.gnome.shell enabled-extensions "['background-logo@fedorahosted.org', 'user-theme@gnome-shell-extensions.gcampax.github.com', 'Vitals@CoreCoding.com', 'logomenu@aryan_k', 'space-bar@luchrioh']"

# Aplicación exacta del Layout de Graphite compilado con islas superiores
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface gtk-theme 'Graphite-teal-Dark-nord'
gsettings set org.gnome.shell.extensions.user-theme name 'Graphite-teal-Dark-nord'
gsettings set org.gnome.desktop.interface icon-theme 'Reversal-dark'
gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Ice'

# Atajos de Ventana
gsettings set org.gnome.desktop.wm.keybindings close "['<Super>q']"
gsettings set org.gnome.desktop.wm.keybindings switch-input-source "['<Control>space']"
gsettings set org.gnome.desktop.wm.keybindings switch-input-source-backward "['<Shift><Control>space']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-1 "['<Super>1']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-2 "['<Super>2']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-3 "['<Super>3']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-4 "['<Super>4']"

gsettings set org.gnome.shell.keybindings switch-to-application-1 "@as []"
gsettings set org.gnome.shell.keybindings switch-to-application-2 "@as []"
gsettings set org.gnome.shell.keybindings switch-to-application-3 "@as []"
gsettings set org.gnome.shell.keybindings switch-to-application-4 "@as []"
gsettings set org.gnome.desktop.wm.keybindings panel-main-menu "@as []"
gsettings set org.gnome.settings-daemon.plugins.media-keys home "['<Super>e']"

# Atajos de lanzadores (Kitty y Ulauncher)
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/']"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ name 'terminal'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command 'kitty'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ binding '<Super>Return'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ name 'launcher'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ command 'ulauncher'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ binding '<Super>space'

# ==============================================================================
# 14. CONFIGURACIONES ADICIONALES DE INTEGRACIÓN
# ==============================================================================
echo -e "${BLUE}[*] Configurando el socket de usuario para Podman...${NC}"
systemctl --user enable --now podman.socket

git config --global init.defaultBranch main
git config --global core.editor "nvim"

# ==============================================================================
# 15. CAMBIO DE SHELL POR DEFECTO
# ==============================================================================
if [ "$SHELL" != "$(which zsh)" ] && command -v zsh &> /dev/null; then
    echo -e "${BLUE}[*] Cambiando shell por defecto a Zsh...${NC}"
    chsh -s "$(which zsh)"
fi

# ==============================================================================
# 16. AUTENTICACIÓN INTERACTIVA (GITHUB)
# ==============================================================================
echo -e "${YELLOW}=========================================================${NC}"
echo -e "${YELLOW}  Fase final: Autenticación en GitHub                    ${NC}"
echo -e "${YELLOW}  Sigue las instrucciones en pantalla.                   ${NC}"
echo -e "${YELLOW}=========================================================${NC}"
gh auth login

echo -e "${GREEN}=========================================================${NC}"
echo -e "${GREEN}  ¡ENTORNO INSTALADO! CIERRA SESIÓN Y VUELVE A ENTRAR    ${NC}"
echo -e "${GREEN}  PARA QUE LAS ISLAS DE LA BARRA SE APLIQUEN.            ${NC}"
echo -e "${GREEN}=========================================================${NC}"
