[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
eval "$(zoxide init zsh)"

# neovim config switcher
alias lvim="NVIM_APPNAME=LazyVim nvim"
alias fvim="NVIM_APPNAME=FolkeVim nvim"

alias n="nvim"
alias vim="nvim"
alias epath="tr ':' '\n' <<< "$PATH""
alias lg="lazygit"
alias l="yazi"

setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_ALL_DUPS

export HISTSIZE=10000
export SAVEHIST=10000

[ -f "/Users/milan/.ghcup/env" ] && . "/Users/milan/.ghcup/env" # ghcup-env
export PATH="$HOME/.local/bin:$PATH"
export PATH="/opt/homebrew/sbin:$PATH"
export PATH="/opt/homebrew/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.ghcup/bin:$PATH"
export EDITOR=nvim
source /opt/homebrew/opt/zsh-fast-syntax-highlighting/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
bindkey '^Y' autosuggest-accept
