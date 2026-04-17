
# ------------------------------
# --- Begin of .zshrc config ---
# ------------------------------

# Antidote Plugin Manager (already installed)
ANTIDOTE_DIR="${HOME}/.antidote"
if [[ ! -d "$ANTIDOTE_DIR" ]]; then
    git clone --depth=1 https://github.com/mattmc3/antidote.git "$ANTIDOTE_DIR"
fi

# Plugin-Verzeichnis festlegen (vor dem Laden!)
export ANTIDOTE_HOME="${HOME}/.zsh/plugins"

# Antidote laden
source "$ANTIDOTE_DIR/antidote.zsh"

# Plugins laden (create ~/.zsh_plugins.txt if needed)
if [[ -f "${ZDOTDIR:-$HOME}/.zsh_plugins.txt" ]]; then
    antidote load
fi

# Atuin Setup (existing configuration)
. "$HOME/.atuin/bin/env"

# History
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt INC_APPEND_HISTORY SHARE_HISTORY

# Completion
autoload -Uz compinit && compinit
compinit -d ~/.zcompdump

# --- Alias Sektion ---
# ls
alias ls='eza --group-directories-first --icons=always'
alias ll='eza -l'
alias la='eza -a --group-directories-first --icons=always'
alias lla='eza -la'
# eza = "the BETTER ls"
alias eza='eza --group-directories-first --icons=always'
alias ezal='eza -l'
alias ezaa='eza -a --group-directories-first --icons=always'
alias ezla='eza -la'

# clear the clipboard Funktion (Linux version)
clrclp () {
    if command -v xclip &> /dev/null; then
        echo -n | xclip -selection clipboard
    elif command -v xsel &> /dev/null; then
        echo -n | xsel --clipboard
    else
        echo "No clipboard tool found (install xclip or xsel)"
    fi
}

# Pfade für Pop!_OS
export PATH="/usr/local/bin:$HOME/.atuin/bin:$PATH"

# Tools initialisieren
eval "$(atuin init zsh)"
eval "$(zoxide init zsh)"
eval "$(starship init zsh)"

# FZF initialisieren
if command -v fzf &> /dev/null; then
    # Try different FZF initialization methods
    if [[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]]; then
        source /usr/share/doc/fzf/examples/key-bindings.zsh
    fi
    if [[ -f /usr/share/doc/fzf/examples/completion.zsh ]]; then
        source /usr/share/doc/fzf/examples/completion.zsh
    fi
fi

# --- Ende der .zshrc Konfiguration ---
