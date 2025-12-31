eval "$(/opt/homebrew/bin/brew shellenv)"

export PATH="$HOME/.local/bin:$HOME/.ghcup/bin:$PATH"
[ -f "$HOME/.ghcup/env" ] && . "$HOME/.ghcup/env"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
eval "$(zoxide init zsh)"

export EDITOR=nvim

source /opt/homebrew/opt/zsh-fast-syntax-highlighting/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh

bindkey '^Y' autosuggest-accept

# neovim config switcher
alias fvim="NVIM_APPNAME=FolkeVim nvim"
alias pl="NVIM_APPNAME=PureLazy nvim"
alias nnvim="NVIM_APPNAME=newVim nvim"
alias n="nvim"
alias epath="tr ':' '\n' <<< "$PATH""
alias lg="lazygit"
alias l="yazi"
alias ls="eza -lh --group-directories-first --icons=auto"
alias lt="eza --tree --level=2 --long --icons --git"

bindkey '^p' history-search-backward
bindkey '^n' history-search-forward

zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

setopt hist_save_no_dups
setopt hist_ignore_all_dups
setopt sharehistory
export HISTSIZE=10000
export SAVEHIST=$HISTSIZE

autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^x^e' edit-command-line
bindkey ' ' magic-space

function sesh-sessions() {
  {
    exec </dev/tty
    exec <&1
    local session
    session=$(sesh list -t -c | fzf --height 40% --reverse --border-label ' sesh ' --border --prompt '⚡  ')
    zle reset-prompt > /dev/null 2>&1 || true
    [[ -z "$session" ]] && return
    sesh connect $session
  }
}

zle     -N             sesh-sessions
bindkey -M emacs '02;9u' sesh-sessions
bindkey -M vicmd '02;9u' sesh-sessions
bindkey -M viins '02;9u' sesh-sessions

function mpv() {
  nohup /opt/homebrew/bin/mpv "$@" >/dev/null 2>&1 & disown
}

if type brew &>/dev/null; then
  FPATH=$(brew --prefix)/share/zsh-completions:$FPATH

  autoload -Uz compinit
  compinit
fi

eval "$(starship init zsh)"
export EZA_CONFIG_DIR="$HOME/.config/eza"
