# ==============================================================================
# 1. VARIABLES DE ENTORNO Y CONFIGURACIÓN BÁSICA
# ==============================================================================
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Colores para LS y herramientas estándar
export CLICOLOR=1
export LSCOLORS=Gxfxcxdxbxegedabagacad

# Configuración del Historial
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt INC_APPEND_HISTORY

# ==============================================================================
# 2. INICIALIZACIÓN DE HERRAMIENTAS (PROMPT & NAVIGATION)
# ==============================================================================

# Oh My Posh
eval "$(oh-my-posh init zsh --config ~/.config/ohmyposh/dev_mocha.toml)"

# Zoxide (Smart Directory Jumper)
# Esto inicializa zoxide y habilita el comando 'z' y 'zi'
eval "$(zoxide init zsh)"

# ==============================================================================
# 3. AUTOCOMPLETADO AVANZADO (ZSTYLE)
# ==============================================================================
# AVISO: El fpath debe definirse ANTES de iniciar compinit
fpath=(~/.zsh_plugins/zsh-completions/src $fpath)

# Iniciar el sistema de autocompletado
autoload -Uz compinit && compinit

# --- Configuración Visual y de Comportamiento ---
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*:*:*:*:descriptions' format '%F{green}-- %d --%f'
zstyle ':completion:*:messages' format ' %F{purple} -- %d --%f'
zstyle ':completion:*:warnings' format ' %F{red}-- no matches found --%f'
zstyle ':completion:*' completer _expand _complete _ignored _approximate

# ==============================================================================
# 4. PLUGINS ADICIONALES
# ==============================================================================

# Zsh Autosuggestions
export ZSH_AUTOSUGGEST_USE_ASYNC="true"
export ZSH_AUTOSUGGEST_STRATEGY=(history completion)
source ~/.zsh_plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

# FZF Integration (Necesario para que 'zi' funcione en Zoxide)
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# ==============================================================================
# 5. FUNCIONES PERSONALIZADAS
# ==============================================================================

# --- Auto-Listado al cambiar de directorio ---
# Esta función se ejecuta automáticamente cada vez que cambias de carpeta (con cd o z)
# Muestra el contenido inmediatamente usando lsd.
function chpwd() {
    lsd --group-dirs=first
}

# --- Función SUDO (Doble ESC) ---
sudo-command-line() {
    [[ -z $BUFFER ]] && LBUFFER="$(fc -n -l -1)"
    if [[ $BUFFER == sudo\ * ]]; then
        LBUFFER="${LBUFFER#sudo }"
    else
        LBUFFER="sudo $LBUFFER"
    fi
}
zle -N sudo-command-line
bindkey "\e\e" sudo-command-line

# --- Utilidades ---
function mkt(){
    mkdir -p "$1"
    cd "$1"
}

extract () {
  if [ -f $1 ] ; then
    case $1 in
      *.tar.bz2)   tar xjf $1   ;;
      *.tar.gz)    tar xzf $1   ;;
      *.bz2)       bunzip2 $1   ;;
      *.rar)       unrar x $1   ;;
      *.gz)        gunzip $1    ;;
      *.tar)       tar xf $1    ;;
      *.tbz2)      tar xjf $1   ;;
      *.tgz)       tar xzf $1   ;;
      *.zip)       unzip $1     ;;
      *.Z)         uncompress $1;;
      *.7z)        7z x $1      ;;
      *)           echo "'$1' cannot be extracted via extract()" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

function settarget(){
    if [ $# -eq 1 ]; then
        echo "$1" > ~/.target
        echo "Target definido: $1"
    elif [ $# -eq 2 ]; then
        echo "$1 $2" > ~/.target
        echo "Target definido: $1 ($2)"
    else
        echo "Uso: settarget <IP> [Nombre]"
    fi
}

function cleartarget(){
    echo "" > ~/.target
    echo "Target eliminado"
}

# ==============================================================================
# 6. ALIASES
# ==============================================================================

# Reemplazo de CD por Zoxide
# 'z' es el comando nativo, pero aliaseamos 'cd' para que sea transparente
alias cd='z' 
alias cdi='zi' # 'cdi' abrirá el buscador interactivo de carpetas

# LSD y BAT
alias cat='bat'
alias catn='bat --style=plain'
alias catnp='bat --style=plain --paging=never'
alias ll='lsd -lh --group-dirs=first'
alias la='lsd -a --group-dirs=first'
alias l='lsd --group-dirs=first'
alias lla='lsd -lha --group-dirs=first'
alias ls='lsd --group-dirs=first'
alias tree='lsd --tree'

# Alias de Desarrollo
alias g='git'
alias gst='git status'
alias ga='git add'
alias gc='git commit -m'
alias gp='git push'
alias gd='git diff'
alias py='python3'

# Seguridad y Utilidad
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias grep='grep --color=auto'
alias c='clear'
alias ipa='ip -c a'

# ==============================================================================
# 7. ATAJOS DE TECLADO
# ==============================================================================
bindkey "^[[A" history-search-backward
bindkey "^[[B" history-search-forward

# ==============================================================================
# 8. FINALIZACIÓN
# ==============================================================================
source ~/.zsh_plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
ZLE_RPROMPT_INDENT=0
