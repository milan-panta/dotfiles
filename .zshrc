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

eval "$(starship init zsh)"
