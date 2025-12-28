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
alias vim="nvim"
alias epath="tr ':' '\n' <<< "$PATH""
alias lg="lazygit"
alias l="yazi"

setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_ALL_DUPS
export HISTSIZE=10000
export SAVEHIST=10000

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

eval "$(starship init zsh)"
