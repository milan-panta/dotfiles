export PATH="$HOME/.ghcup/bin:$PATH"
export EDITOR=nvim

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
eval "$(zoxide init zsh)"

# neovim config switcher
alias lvim="NVIM_APPNAME=LazyVim nvim"

alias n="nvim"
alias epath="tr ':' '\n' <<< "$PATH""
alias lg="lazygit"
alias l="yazi"

setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_ALL_DUPS

export HISTSIZE=10000
export SAVEHIST=10000

[ -f "/Users/milan/.ghcup/env" ] && . "/Users/milan/.ghcup/env" # ghcup-env
