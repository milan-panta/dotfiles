# Bind Ctrl+Y to t. t is a script defined in /usr/local/bin/t.
bindkey -s "^Y" 't\n'

source /opt/homebrew/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

export PATH="/opt/homebrew/bin:$PATH"
export DYLD_LIBRARY_PATH=/opt/homebrew/lib/
export PATH=/Users/milan/.cargo/bin:$PATH
export DBUS_SESSION_BUS_ADDRESS='unix:path='$DBUS_LAUNCHD_SESSION_BUS_SOCKET
export EDITOR=nvim

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
eval "$(zoxide init zsh)"

# neovim config switcher
alias nvim-lazy="NVIM_APPNAME=LazyVim nvim"
alias nh="NVIM_APPNAME=nh nvim"
alias nlc="nvim leetcode.nvim"

alias n="nvim"
alias epath="tr ':' '\n' <<< "$PATH""
alias lg="lazygit"
alias l="yazi"
alias gc="git checkout"

setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_ALL_DUPS

export HISTSIZE=10000
export SAVEHIST=10000
