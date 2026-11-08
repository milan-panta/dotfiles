# Prompt hot path, sourced from ~/.bashrc after Omarchy's rc.
#
# Omarchy's rc spends ~25-45ms between a command finishing and the next prompt: starship
# (~13ms in a git repo: process start, gitoxide discovery, then a `git status` anyway), a
# `starship time` exec before and after every command for a cmd_duration nothing shows,
# `mise hook-env` on every prompt (init.bash now handles mise and skips starship init), systemd's OSC 3008 hooks, and `zoxide add` on
# every cd. This renders the same prompt as ~/.config/starship.toml in-process and drops
# or defers the rest, leaving a single `git status` inside repos and no processes outside.

[[ $- == *i* ]] || return 0

__prompt_return() { return "$1"; }

# Same output as starship.toml: directory (truncated to 2, relative to the repo root),
# branch, conflicted/modified/untracked markers, and ❯ or ✗ for the last exit status.
__prompt_render() {
  local rc=$1 s=$'\001' e=$'\002'
  local bold=$s$'\e[1;36m'$e italic=$s$'\e[3;36m'$e cyan=$s$'\e[36m'$e red=$s$'\e[31m'$e reset=$s$'\e[0m'$e
  local root=. git= path= branch= status= ro= i

  # Walk up the physical tree (like git) for a .git; stat calls only, no processes.
  for ((i = 0; i < 64; i++)); do
    [[ -e $root/.git ]] && break
    [[ $root -ef / || ! -d $root ]] && { root=; break; }
    root+=/..
  done
  ((i == 64)) && root=
  if [[ $root ]] && git=$(GIT_OPTIONAL_LOCKS=0 command git status --porcelain=2 --branch 2>/dev/null); then
    branch=${git#*'# branch.head '}
    branch=${branch%%$'\n'*}
    [[ $branch == '(detached)' ]] && branch=HEAD
    [[ $git == *$'\nu '* ]] && status+=$' '
    [[ $git == *$'\n'[12]' '?[MA]* ]] && status+=$' '
    [[ $git == *$'\n? '* ]] && status+='? '
  else
    git=
  fi

  # Inside a repo (not rooted at ~), show the path from the repo root, keeping the logical
  # path: find the ancestor of $PWD that is the same directory as the root found above.
  if [[ $git && ! $root -ef $HOME ]]; then
    local dir=$PWD rest= depth=0
    until [[ $dir -ef $root ]]; do
      [[ $dir == / ]] && { dir=; break; }
      rest=/${dir##*/}$rest
      dir=${dir%/*}
      dir=${dir:-/}
      ((depth++))
    done
    if [[ $dir && $dir != / ]]; then
      path=${dir##*/}$rest
      ((depth >= 2)) && path=…/${path#"${path%/*/*}/"}
    fi
  fi
  if [[ -z $path ]]; then
    case $PWD in
      "$HOME") path='~' ;;
      "$HOME"/*) path=\~${PWD#"$HOME"} ;;
      *) path=$PWD ;;
    esac
    [[ ${path#/} == */*/* ]] && path=…/${path#"${path%/*/*}/"}
  fi
  [[ -w . ]] || ro=$red🔒$reset

  __prompt=$'\n'$bold$path$reset$ro' '${branch:+$italic$branch$reset }${status:+$cyan$status$reset}
  ((rc == 0)) && __prompt+=$bold❯$reset' ' || __prompt+=$bold✗$reset' '
}

__prompt_precmd() {
  local rc=$?
  # Whatever starship init moved out of PROMPT_COMMAND (mise's hook), with $? intact.
  if [[ -n ${STARSHIP_PROMPT_COMMAND-} ]]; then
    __prompt_return "$rc"
    eval "$STARSHIP_PROMPT_COMMAND"
  fi
  __prompt_render "$rc"
}

# Expanded via promptvars, so directory names are never parsed as prompt escapes or code.
PS1='${__prompt}'

# Starship's command timer and systemd's OSC 3008 context hooks each fork on every command;
# cmd_duration isn't in the prompt, Ghostty ignores OSC 3008 and tmux drops it.
PS0=${PS0#'${STARSHIP_START_TIME:'*':0}'}
PS0=${PS0//'$(__systemd_osc_context_ps0)'/}
__prompt_cmds=(__prompt_precmd)
for __prompt_cmd in "${PROMPT_COMMAND[@]}"; do
  case $__prompt_cmd in
    __prompt_precmd | starship_precmd | __systemd_osc_context_precmdline | '') ;;
    *) __prompt_cmds+=("$__prompt_cmd") ;;
  esac
done
PROMPT_COMMAND=("${__prompt_cmds[@]}")
unset __prompt_cmds __prompt_cmd

# mise's hook is gated in init.bash (cached env, hook-env only inside mise projects).

# zoxide's hook runs `zoxide add` (~5ms) before the prompt on every cd; nothing reads the
# database until the next `z`, so record the visit in the background.
if declare -F __zoxide_hook >/dev/null; then
  __zoxide_hook() {
    local rc=$?
    if [[ ${__zoxide_oldpwd-} != "$PWD" ]]; then
      __zoxide_oldpwd=$PWD
      [[ -o history ]] && (command zoxide add -- "$PWD" >/dev/null 2>&1 &)
    fi
    return "$rc"
  }
fi
