# ---------- PATH ----------
export PATH="$HOME/.local/bin:$PATH"

# ---------- Completions (must precede autocomplete) ----------
FPATH="$HOMEBREW_PREFIX/share/zsh-completions:$FPATH"

# ---------- Plugins (ORDER MATTERS) ----------
source "$HOMEBREW_PREFIX/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh"
source "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
source "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

# ---------- Tools ----------
source <(fzf --zsh)
eval "$(zoxide init zsh)"
eval "$(starship init zsh)"

# ---------- Env ----------
export EDITOR=nvim
export EZA_CONFIG_DIR="$HOME/.config/eza"
export XDG_CONFIG_HOME="$HOME/.config"

# ---------- Keybindings ----------
bindkey '^Y' autosuggest-accept
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey ' ' magic-space
bindkey -s '^[[119;9~' '^D'

# Sessionizer (Cmd+f via Ghostty user-key)
function sesh-sessions() {
  {
    exec </dev/tty
    exec <&1
    local session
    session=$(sesh list --icons -t -c -z | fzf --ansi --height 40% --reverse --border-label ' sesh ' --border --prompt '⚡  ')
    zle reset-prompt > /dev/null 2>&1 || true
    [[ -z "$session" ]] && return
    sesh connect $session
  }
}
zle     -N             sesh-sessions
bindkey '^[[102;9~' sesh-sessions

# ---------- Completion style ----------
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

# ---------- History ----------
setopt hist_save_no_dups
setopt hist_ignore_all_dups
setopt sharehistory
export HISTSIZE=10000
export SAVEHIST=$HISTSIZE

# ---------- Edit command line ----------
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^x^e' edit-command-line

# ---------- Functions ----------
function mpv() {
  nohup /opt/homebrew/bin/mpv "$@" >/dev/null 2>&1 & disown
}

# ---------- Aliases ----------
alias n="nvim"
alias pl="NVIM_APPNAME=PureLazy nvim"
alias epath='tr ":" "\n" <<< "$PATH"'
alias lg="lazygit"
alias l="yazi"
alias ls="eza -lh --group-directories-first --icons=auto"
alias lt="eza --tree --level=2 --long --icons --git"
