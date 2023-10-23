eval "$(starship init zsh)"

# Bind Ctrl+Y to t. t is a script defined in /usr/local/bin/t.
bindkey -s "^Y" 't\n'

source /opt/homebrew/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

export PATH="/opt/homebrew/bin:$PATH"
export PATH=/Users/milan/.cargo/bin:$PATH

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
eval "$(zoxide init zsh)"

# neovim config switcher
alias nvim-lazy="NVIM_APPNAME=LazyVim nvim"
alias nvim-chad="NVIM_APPNAME=NvChad nvim"
alias nvim-latex="NVIM_APPNAME=LatexVim nvim"

function nvims() {
  items=("default" "LazyVim" "NvChad" "LatexVim")
  config=$(printf "%s\n" "${items[@]}" | fzf --prompt=" Neovim Config  " --height=~50% --layout=reverse --border --exit-0)
  if [[ -z $config ]]; then
    echo "Nothing selected"
    return 0
  elif [[ $config == "default" ]]; then
    config=""
  fi
  NVIM_APPNAME=$config nvim $@
}

alias lg="lazygit"
alias gc="git checkout"

setopt HIST_FIND_NO_DUPS
export HISTFILESIZE=10000
export HISTSIZE=10000
