
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

# Plugin-Manifest anlegen, falls es noch nicht existiert (Reihenfolge ist wichtig)
ZSH_PLUGINS_FILE="${ZDOTDIR:-$HOME}/.zsh_plugins.txt"
if [[ ! -f "$ZSH_PLUGINS_FILE" ]]; then
  cat > "$ZSH_PLUGINS_FILE" <<'EOF'
marlonrichert/zsh-autocomplete
mafredri/zsh-async
zsh-users/zsh-autosuggestions
Aloxaf/fzf-tab
zsh-users/zsh-syntax-highlighting
EOF
fi

# Atuin Setup (existing configuration, only present if installed via the
# official install script rather than a system package manager)
[ -f "$HOME/.atuin/bin/env" ] && . "$HOME/.atuin/bin/env"

# History
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt INC_APPEND_HISTORY SHARE_HISTORY

# "#" leitet auch bei direkt eingetippten Befehlen einen Kommentar ein
setopt INTERACTIVE_COMMENTS

# --- Completion cache
# NOTE: zsh-autocomplete runs compinit itself and stubs it out afterwards.
# Upstream requires that we do NOT call compinit here. It honours $ZSH_COMPDUMP.
export ZSH_COMPDUMP="${ZDOTDIR:-$HOME}/.cache/zsh/zcompdump"
mkdir -p "${ZDOTDIR:-$HOME}/.cache/zsh"

# --- Plugin loader
ZSH_AUTOSUGGEST_STRATEGY=( history )
ZSH_HIGHLIGHT_HIGHLIGHTERS=( main brackets )
antidote load "$ZSH_PLUGINS_FILE"

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
export PATH="$HOME/.local/bin:/usr/local/bin:$HOME/.atuin/bin:$PATH"

# Tools initialisieren
eval "$(zoxide init zsh)"
eval "$(starship init zsh)"

# FZF initialisieren
if command -v fzf &> /dev/null; then
    # fzf --zsh is the modern, distro-agnostic integration (works regardless
    # of where a package puts key-bindings.zsh/completion.zsh, e.g. Fedora's
    # /usr/share/fzf/shell/ layout differs from the Debian/macOS doc paths).
    eval "$(fzf --zsh)" 2>/dev/null || {
        # Fallback for older fzf without --zsh support
        for f in /usr/share/doc/fzf/examples/key-bindings.zsh /usr/share/fzf/shell/key-bindings.zsh; do
            [[ -f "$f" ]] && source "$f" && break
        done
        for f in /usr/share/doc/fzf/examples/completion.zsh /usr/share/fzf/shell/completion.zsh; do
            [[ -f "$f" ]] && source "$f" && break
        done
    }
    # fzf's shell integration steals Tab for `fzf-completion`; hand it back to fzf-tab.
    if (( $+widgets[fzf-tab-complete] )); then
        bindkey -M emacs '^I' fzf-tab-complete
        bindkey -M viins '^I' fzf-tab-complete
    fi
fi

# --- Nearly finished
# Atuin: opt out of its default keymap so it cannot take the Up arrow away from
# zsh-autocomplete's history menu. Atuin keeps Ctrl+R only.
export ATUIN_NOBIND=true
eval "$(atuin init zsh)"
bindkey -M emacs '^R' atuin-search
bindkey -M viins '^R' atuin-search

# --- Ende der .zshrc Konfiguration ---
