#!/bin/bash

# ==============================================================================
# SCRIPT DE INSTALACIÓN AUTOMATIZADA PARA FEDORA (DEV ENVIRONMENT)
# ==============================================================================

# Colores para logs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}[*] Iniciando configuración de entorno en Fedora...${NC}"

# 1. ACTUALIZAR SISTEMA E INSTALAR DEPENDENCIAS BASE
echo -e "${BLUE}[*] Actualizando sistema e instalando paquetes base...${NC}"
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
    util-linux-user \
    gcc-c++ \
    make \
    python3-pip \
    java-latest-openjdk-devel

# 2. INSTALAR FUENTE (FiraMono Nerd Font)
FONT_DIR="$HOME/.local/share/fonts"
if [ ! -d "$FONT_DIR" ]; then
    echo -e "${BLUE}[*] Instalando FiraMono Nerd Font...${NC}"
    mkdir -p "$FONT_DIR"
    wget -P /tmp https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/FiraMono.zip
    unzip /tmp/FiraMono.zip -d "$FONT_DIR"
    fc-cache -fv
    rm /tmp/FiraMono.zip
else
    echo -e "${GREEN}[OK] Las fuentes parecen estar ya configuradas.${NC}"
fi

# 3. INSTALAR OH MY POSH
if ! command -v oh-my-posh &> /dev/null; then
    echo -e "${BLUE}[*] Instalando Oh My Posh...${NC}"
    curl -s https://ohmyposh.dev/install.sh | bash -s -- -d ~/.local/bin
else
    echo -e "${GREEN}[OK] Oh My Posh ya está instalado.${NC}"
fi

# 4. CONFIGURAR ZSH Y PLUGINS
echo -e "${BLUE}[*] Configurando ZSH y descargando plugins...${NC}"
PLUGIN_DIR="$HOME/.zsh_plugins"
mkdir -p "$PLUGIN_DIR"

# Función para clonar o actualizar repos
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

# 5. LENGUAJES DE PROGRAMACIÓN

# Node.js & PNPM (Usando NVM para evitar problemas de permisos con dnf)
if [ ! -d "$HOME/.nvm" ]; then
    echo -e "${BLUE}[*] Instalando NVM, Node.js y PNPM...${NC}"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    
    # Cargar nvm temporalmente para instalar node
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    nvm install --lts
    nvm use --lts
    npm install -g pnpm
else
    echo -e "${GREEN}[OK] NVM ya está instalado.${NC}"
fi

# 6. COPIAR ARCHIVOS DE CONFIGURACIÓN (DOTFILES)
echo -e "${BLUE}[*] Aplicando configuraciones...${NC}"

# Directorio actual donde está el script
DOTFILES_DIR=$(pwd)

# Oh My Posh Config
mkdir -p "$HOME/.config/ohmyposh"
cp -f "$DOTFILES_DIR/config/ohmyposh/dev_mocha.toml" "$HOME/.config/ohmyposh/"

# Kitty Config
mkdir -p "$HOME/.config/kitty"
cp -f "$DOTFILES_DIR/config/kitty/kitty.conf" "$HOME/.config/kitty/"

# Zshrc
cp -f "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"

echo -e "${GREEN}[OK] Archivos de configuración copiados.${NC}"

# 7. CAMBIAR SHELL POR DEFECTO A ZSH
if [ "$SHELL" != "$(which zsh)" ]; then
    echo -e "${BLUE}[*] Cambiando shell por defecto a Zsh...${NC}"
    # Nota: Puede pedir contraseña
    chsh -s "$(which zsh)"
fi

echo -e "${GREEN}====================================================${NC}"
echo -e "${GREEN}  ¡INSTALACIÓN COMPLETADA!  ${NC}"
echo -e "${GREEN}  Cierra esta terminal y abre una nueva (o reinicia).${NC}"
echo -e "${GREEN}====================================================${NC}"
