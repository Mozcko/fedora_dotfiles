#!/bin/bash

# ==============================================================================
# SCRIPT DE INSTALACIÓN AUTOMATIZADA PARA FEDORA (DEV ENVIRONMENT)
# Incluye: Zsh + OhMyPosh + Kitty + Lenguajes + NvChad
# ==============================================================================

# Colores para logs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}[*] Iniciando configuración de entorno en Fedora...${NC}"

# ==============================================================================
# 1. ACTUALIZACIÓN Y DEPENDENCIAS DEL SISTEMA
# ==============================================================================
echo -e "${BLUE}[*] Actualizando sistema e instalando paquetes base...${NC}"

# Nota: Se instala 'ripgrep' y 'fd-find' (útiles para NvChad/Telescope)
sudo dnf upgrade --refresh -y
sudo dnf install -y \
    zsh \
    git \
    curl \
    wget \
    unzip \
    tar \
    bat \
    lsd \
    fzf \
    zoxide \
    neovim \
    ripgrep \
    fd-find \
    util-linux-user \
    gcc-c++ \
    make \
    python3-pip \
    java-latest-openjdk-devel \
    npm # Necesario para algunos LSPs antes de instalar NVM

# ==============================================================================
# 2. INSTALAR FUENTE (FiraMono Nerd Font)
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
    echo -e "${GREEN}[OK] Las fuentes parecen estar ya configuradas.${NC}"
fi

# ==============================================================================
# 3. INSTALAR NVCHAD (NEOVIM)
# ==============================================================================
NVIM_CONFIG="$HOME/.config/nvim"

if [ -d "$NVIM_CONFIG" ]; then
    # Comprobar si ya es un repo de git (posiblemente NvChad)
    if [ -d "$NVIM_CONFIG/.git" ]; then
        echo -e "${GREEN}[OK] Neovim ya tiene una configuración git (Probablemente NvChad).${NC}"
    else
        echo -e "${YELLOW}[!] Se detectó una configuración previa de Neovim. Respaldando...${NC}"
        mv "$NVIM_CONFIG" "${NVIM_CONFIG}.bak.$(date +%s)"
        
        echo -e "${BLUE}[*] Clonando NvChad Starter...${NC}"
        git clone https://github.com/NvChad/starter "$NVIM_CONFIG"
    fi
else
    echo -e "${BLUE}[*] Clonando NvChad Starter...${NC}"
    git clone https://github.com/NvChad/starter "$NVIM_CONFIG"
fi

# Eliminar cache de nvim para asegurar instalación limpia de plugins la primera vez
rm -rf "$HOME/.local/share/nvim"

# ==============================================================================
# 4. INSTALAR OH MY POSH
# ==============================================================================
if ! command -v oh-my-posh &> /dev/null; then
    echo -e "${BLUE}[*] Instalando Oh My Posh...${NC}"
    curl -s https://ohmyposh.dev/install.sh | bash -s -- -d ~/.local/bin
else
    echo -e "${GREEN}[OK] Oh My Posh ya está instalado.${NC}"
fi

# ==============================================================================
# 5. CONFIGURAR ZSH Y PLUGINS
# ==============================================================================
echo -e "${BLUE}[*] Configurando ZSH y descargando plugins...${NC}"
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
# 6. INSTALAR LENGUAJES (NODE, PNPM)
# ==============================================================================

# Instalación de NVM (Node Version Manager)
export NVM_DIR="$HOME/.nvm"
if [ ! -d "$NVM_DIR" ]; then
    echo -e "${BLUE}[*] Instalando NVM...${NC}"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    
    # Cargar NVM inmediatamente para usarlo en este script
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    echo -e "${BLUE}[*] Instalando Node LTS y PNPM...${NC}"
    nvm install --lts
    nvm use --lts
    npm install -g pnpm
else
    echo -e "${GREEN}[OK] NVM ya está instalado.${NC}"
fi

# ==============================================================================
# 7. COPIAR DOTFILES (Kitty, Zsh, OhMyPosh)
# ==============================================================================
echo -e "${BLUE}[*] Aplicando configuraciones locales...${NC}"

# Directorio desde donde se ejecuta el script
DOTFILES_DIR=$(pwd)

# Configuración de Oh My Posh
mkdir -p "$HOME/.config/ohmyposh"
cp -f "$DOTFILES_DIR/config/ohmyposh/dev_mocha.toml" "$HOME/.config/ohmyposh/"

# Configuración de Kitty
mkdir -p "$HOME/.config/kitty"
cp -f "$DOTFILES_DIR/config/kitty/kitty.conf" "$HOME/.config/kitty/"

# Configuración de Zsh
cp -f "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"

echo -e "${GREEN}[OK] Archivos de configuración copiados.${NC}"

# ==============================================================================
# 8. CAMBIAR SHELL A ZSH
# ==============================================================================
if [ "$SHELL" != "$(which zsh)" ]; then
    echo -e "${BLUE}[*] Cambiando shell por defecto a Zsh...${NC}"
    chsh -s "$(which zsh)"
fi

echo -e "${GREEN}=========================================================${NC}"
echo -e "${GREEN}  ¡INSTALACIÓN COMPLETADA!  ${NC}"
echo -e "${GREEN}  1. Reinicia tu terminal o cierra sesión.${NC}"
echo -e "${GREEN}  2. Ejecuta 'nvim'. NvChad instalará los plugins.${NC}"
echo -e "${GREEN}     (Espera a que termine el Lazy manager).${NC}"
echo -e "${GREEN}=========================================================${NC}"
