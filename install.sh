#!/bin/bash

# ==============================================================================
# SCRIPT DE INSTALACIÓN AUTOMATIZADA PARA FEDORA (DEV & PERSONAL ENVIRONMENT)
# Incluye: Zsh, OhMyPosh, Kitty, NvChad, Lenguajes, Apps (DNF/Flatpak), 
#          Temas Visuales, Extensiones de GNOME y Preferencias de Sistema.
# ==============================================================================

# Colores para logs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}[*] Iniciando configuración completa de tu entorno en Fedora...${NC}"

# Guardar el directorio actual del repositorio de dotfiles
DOTFILES_DIR=$(pwd)

# ==============================================================================
# 1. ACTUALIZACIÓN Y REPOSITORIOS EXTERNOS
# ==============================================================================
echo -e "${BLUE}[*] Configurando repositorios de software externos...${NC}"

# Actualizar índices base
sudo dnf upgrade --refresh -y

# Repositorio oficial de Visual Studio Code
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'

# Repositorio oficial de GitHub CLI
sudo dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo

# Repositorio de la comunidad para GitHub Desktop (Shiftkey)
sudo rpm --import https://rpm.packages.shiftkey.dev/gpg.key
sudo sh -c 'echo -e "[shiftkey-packages]\nname=GitHub Desktop\nbaseurl=https://rpm.packages.shiftkey.dev/rpm/\nenabled=1\ngpgcheck=1\ngpgkey=https://rpm.packages.shiftkey.dev/gpg.key" > /etc/yum.repos.d/shiftkey-packages.repo'

# ==============================================================================
# 2. INSTALACIÓN DE PAQUETES DEL SISTEMA (DNF)
# ==============================================================================
echo -e "${BLUE}[*] Instalando aplicaciones y dependencias nativas vía DNF...${NC}"

sudo dnf install -y \
    zsh git curl wget unzip tar bat lsd fzf zoxide neovim ripgrep fd-find \
    util-linux-user gcc-c++ make python3-pip pipx java-latest-openjdk-devel npm \
    code gh github-desktop gnome-tweaks ulauncher podman \
    gnome-shell-extension-user-theme

# ==============================================================================
# 3. INSTALACIÓN DE APLICACIONES EN RÁFAGA (FLATPAK VIA FLATHUB)
# ==============================================================================
echo -e "${BLUE}[*] Configurando Flathub e instalando aplicaciones gráficas...${NC}"
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Instalación masiva de Flatpaks (Incluye Opera y herramientas de contenido con códecs)
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
    com.github.alainm23.beaver \
    com.parsecgaming.parsec

# ==============================================================================
# 4. FUENTES (FiraMono Nerd Font)
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
# 5. CONFIGURACIÓN DE NVCHAD (NEOVIM)
# ==============================================================================
NVIM_CONFIG="$HOME/.config/nvim"
if [ -d "$NVIM_CONFIG" ]; then
    if [ -d "$NVIM_CONFIG/.git" ]; then
        echo -e "${GREEN}[OK] Neovim ya tiene una configuración activa.${NC}"
    else
        echo -e "${YELLOW}[!] Resguardando configuración previa de Neovim...${NC}"
        mv "$NVIM_CONFIG" "${NVIM_CONFIG}.bak.$(date +%s)"
        git clone https://github.com/NvChad/starter "$NVIM_CONFIG"
    fi
else
    echo -e "${BLUE}[*] Clonando NvChad...${NC}"
    git clone https://github.com/NvChad/starter "$NVIM_CONFIG"
fi
rm -rf "$HOME/.local/share/nvim"

# ==============================================================================
# 6. OH MY POSH
# ==============================================================================
if ! command -v oh-my-posh &> /dev/null; then
    echo -e "${BLUE}[*] Instalando Oh My Posh...${NC}"
    curl -s https://ohmyposh.dev/install.sh | bash -s -- -d ~/.local/bin
else
    echo -e "${GREEN}[OK] Oh My Posh ya está presente.${NC}"
fi

# ==============================================================================
# 7. PLUGINS DE ZSH
# ==============================================================================
echo -e "${BLUE}[*] Descargando plugins globales de Zsh...${NC}"
PLUGIN_DIR="$HOME/.zsh_plugins"
mkdir -p "$PLUGIN_DIR"

install_plugin() {
    REPO=$1
    DIR_NAME=$(basename $REPO)
    TARGET="$PLUGIN_DIR/$DIR_NAME"
    if [ ! -d "$TARGET" ]; then
        git clone --depth 1 "https://github.com/$REPO.git" "$TARGET"
    fi
}

install_plugin "zsh-users/zsh-autosuggestions"
install_plugin "zsh-users/zsh-syntax-highlighting"
install_plugin "zsh-users/zsh-completions"

# ==============================================================================
# 8. GESTIÓN DE LENGUAJES (NVM, NODE, PNPM, GEMINI-CLI)
# ==============================================================================
export NVM_DIR="$HOME/.nvm"
if [ ! -d "$NVM_DIR" ]; then
    echo -e "${BLUE}[*] Configurando entorno Node con NVM...${NC}"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    
    # Cargar NVM en la sesión actual de instalación
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    nvm install --lts
    nvm use --lts
    npm install -g pnpm gemini-cli
else
    echo -e "${GREEN}[OK] NVM y Node ya se encuentran instalados.${NC}"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    npm install -g gemini-cli
fi

# ==============================================================================
# 9. INSTALACIÓN AUTOMÁTICA DE EXTENSIONES DE GNOME
# ==============================================================================
echo -e "${BLUE}[*] Configurando inyector automatizado de GNOME Extensions...${NC}"
pipx install gnome-extensions-cli --force
export PATH="$PATH:$HOME/.local/bin"

# Instalar tus extensiones directamente desde el repositorio de GNOME
~/.local/bin/gext install Vitals@CoreCoding.com
~/.local/bin/gext install logomenu@aryan_k
~/.local/bin/gext install space-bar@luchrioh

# ==============================================================================
# 10. DESCARGA E INYECCIÓN DE TEMAS (GRAPHITE, REVERSAL, BIBATA)
# ==============================================================================
echo -e "${BLUE}[*] Descargando y compilando temas visuales...${NC}"
mkdir -p "$HOME/.themes" "$HOME/.icons"
TEMP_THEMES="/tmp/fedora_themes"
mkdir -p "$TEMP_THEMES"

# Tema GTK Graphite (Teal, Dark, Nord)
git clone https://github.com/vinceliuice/Graphite-gtk-theme.git "$TEMP_THEMES/graphite"
"$TEMP_THEMES/graphite/install.sh" -t teal -c dark --tweaks nord -d "$HOME/.themes"

# Iconos Reversal Dark
git clone https://github.com/yeyushengfan258/Reversal-icon-theme.git "$TEMP_THEMES/reversal"
"$TEMP_THEMES/reversal/install.sh" -a -d "$HOME/.icons"

# Cursor Bibata Modern Ice
wget -O /tmp/Bibata.tar.gz https://github.com/ful1e5/Bibata_Cursor/releases/latest/download/Bibata-Modern-Ice.tar.gz
tar -xzvf /tmp/Bibata.tar.gz -C "$HOME/.icons/"

rm -rf "$TEMP_THEMES" /tmp/Bibata.tar.gz

# Forzar a Flatpak a heredar y reconocer los temas visuales locales del sistema
sudo flatpak override --env=GTK_THEME=Graphite-teal-Dark-nord
sudo flatpak override --env=ICON_THEME=Reversal-dark
sudo flatpak override --filesystem=$HOME/.themes
sudo flatpak override --filesystem=$HOME/.icons

# ==============================================================================
# 11. ENLACES SIMBÓLICOS (Alineación con tu Repositorio)
# ==============================================================================
echo -e "${BLUE}[*] Enlazando simbólicamente tus dotfiles...${NC}"

mkdir -p "$HOME/.config/kitty"
mkdir -p "$HOME/.config/ohmyposh"

# Crear enlaces persistentes hacia los archivos del repositorio clonado
ln -sf "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
ln -sf "$DOTFILES_DIR/config/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf"
ln -sf "$DOTFILES_DIR/config/ohmyposh/dev_mocha.toml" "$HOME/.config/ohmyposh/dev_mocha.toml"

# ==============================================================================
# 12. APLICACIÓN DE PREFERENCIAS, IDIOMAS Y KEYBINDINGS DE GNOME
# ==============================================================================
echo -e "${BLUE}[*] Inyectando tus configuraciones de dconf/gsettings...${NC}"

# Distribución y mapeo de idiomas (US y Latam)
gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'us'), ('xkb', 'latam')]"

# Activación física de extensiones instaladas
gsettings set org.gnome.shell enabled-extensions "['background-logo@fedorahosted.org', 'user-theme@gnome-shell-extensions.gcampax.github.com', 'Vitals@CoreCoding.com', 'logomenu@aryan_k', 'space-bar@luchrioh']"

# Aplicación de temas en el entorno GNOME
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface gtk-theme 'Graphite-teal-Dark-nord'
gsettings set org.gnome.shell.extensions.user-theme name 'Graphite-teal-Dark-nord'
gsettings set org.gnome.desktop.interface icon-theme 'Reversal-dark'
gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Ice'

# Mapeos de atajos de teclado esenciales (Window Management)
gsettings set org.gnome.desktop.wm.keybindings close "['<Super>q']"
gsettings set org.gnome.desktop.wm.keybindings switch-input-source "['<Control>space']"
gsettings set org.gnome.desktop.wm.keybindings switch-input-source-backward "['<Shift><Control>space']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-1 "['<Super>1']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-2 "['<Super>2']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-3 "['<Super>3']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-4 "['<Super>4']"

# Desvincular comportamiento nativo para evitar colisiones con Super+Número
gsettings set org.gnome.shell.keybindings switch-to-application-1 "@as []"
gsettings set org.gnome.shell.keybindings switch-to-application-2 "@as []"
gsettings set org.gnome.shell.keybindings switch-to-application-3 "@as []"
gsettings set org.gnome.shell.keybindings switch-to-application-4 "@as []"
gsettings set org.gnome.desktop.wm.keybindings panel-main-menu "@as []"

# Explorador de archivos nativo
gsettings set org.gnome.settings-daemon.plugins.media-keys home "['<Super>e']"

# Inyección de lanzadores personalizados (Custom Keybindings)
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/']"

# Custom 0: Lanzar Kitty Terminal via Super + Enter
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ name 'terminal'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command 'kitty'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ binding '<Super>Return'

# Custom 1: Lanzar Ulauncher via Super + Espacio
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ name 'launcher'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ command 'ulauncher'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ binding '<Super>space'

# ==============================================================================
# 13. CONFIGURACIONES ADICIONALES DE INTEGRACIÓN
# ==============================================================================
echo -e "${BLUE}[*] Configurando el socket de usuario para Podman...${NC}"
systemctl --user enable --now podman.socket

# Configurar Git de forma global
git config --global init.defaultBranch main
git config --global core.editor "nvim"

# ==============================================================================
# 14. CAMBIO DE SHELL POR DEFECTO
# ==============================================================================
if [ "$SHELL" != "$(which zsh)" ]; then
    echo -e "${BLUE}[*] Cambiando shell por defecto a Zsh...${NC}"
    chsh -s "$(which zsh)"
fi

echo -e "${GREEN}=========================================================${NC}"
echo -e "${GREEN}  ¡ENTORNO INSTALADO Y CONFIGURADO CON ÉXITO!            ${NC}"
echo -e "${GREEN}  1. Cierra sesión de GNOME y vuelve a entrar para ver    ${NC}"
echo -e "${GREEN}     reflejados todos los cambios estéticos.             ${NC}"
echo -e "${GREEN}  2. Abre 'nvim' para permitir la autodescarga de plugins.${NC}"
echo -e "${GREEN}=========================================================${NC}"
