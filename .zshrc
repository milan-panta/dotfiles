# ---------- PATH ----------
export PATH="$HOME/.local/bin:$PATH"

# ---------- Completions (must precede autocomplete) ----------
FPATH="$HOMEBREW_PREFIX/share/zsh-completions:$FPATH"

# ---------- Plugins (ORDER MATTERS) ----------
autoload -Uz compinit
compinit
zstyle ':completion:*' use-cache on
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

# ---------- C++ Workflows ----------
# Bear for compile_commands.json generation
alias bear-make="bear -- make -j\$(sysctl -n hw.ncpu 2>/dev/null || nproc)"
alias bear-ninja="bear -- ninja"
alias cmake-ninja="cmake -G Ninja -DCMAKE_EXPORT_COMPILE_COMMANDS=ON"

# LLVM (latest clang/clang++ from homebrew)
if [[ -d /opt/homebrew/opt/llvm/bin ]]; then
  export PATH="/opt/homebrew/opt/llvm/bin:$PATH"
fi

# Sanitizer builds
alias asan-build="cmake -B build -DCMAKE_CXX_FLAGS='-fsanitize=address -fno-omit-frame-pointer -g' && cmake --build build -j\$(sysctl -n hw.ncpu 2>/dev/null || nproc)"
alias tsan-build="cmake -B build -DCMAKE_CXX_FLAGS='-fsanitize=thread -g' && cmake --build build -j\$(sysctl -n hw.ncpu 2>/dev/null || nproc)"
alias ubsan-build="cmake -B build -DCMAKE_CXX_FLAGS='-fsanitize=undefined -g' && cmake --build build -j\$(sysctl -n hw.ncpu 2>/dev/null || nproc)"

# Core dumps
alias coredump-on="ulimit -c unlimited && echo 'Core dumps enabled'"
alias coredump-off="ulimit -c 0 && echo 'Core dumps disabled'"

# Binary analysis
alias objdump-intel="objdump -d -M intel -S"
alias nm-demangle="nm -C"
alias sizes="size -A"

# Compiler exploration
alias includes="clang++ -H 2>&1"
alias pp="clang++ -E -P"
alias asm="clang++ -S -masm=intel -O2"

# Perf tools
alias cg="valgrind --tool=cachegrind"
alias perf-stat="perf stat -e cycles,instructions,cache-references,cache-misses"
alias perf-record="perf record -F 99 -g --"
# Flamegraph pipeline
alias flame="perf script | stackcollapse-perf.pl | flamegraph.pl > perf.svg && echo 'Generated perf.svg'"
