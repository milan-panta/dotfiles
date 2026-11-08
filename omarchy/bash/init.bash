# Fast stand-in for Omarchy's default/bash/init, sourced from ~/.bashrc.
#
# Omarchy's init costs ~85ms per new shell and mise adds ~50ms after every cd:
#   - `mise activate` + its first `mise hook-env`: ~65ms, because mise resolves ~40 tools
#     (Omarchy's conf.d) on each run. Here the result is cached in ~/.cache/bash and only
#     rebuilt when a mise config or install changes. `hook-env` runs on cd only inside a
#     project that has its own mise config, so per-project versions still work.
#   - `starship init`: ~13ms for a prompt that prompt.bash renders in-process anyway.
#   - `zoxide init`: one process; its output is cached the same way.

[[ $- == *i* ]] || return 0

__init_cache=${XDG_CACHE_HOME:-$HOME/.cache}/bash
[[ -d $__init_cache ]] || mkdir -p "$__init_cache"

# --- mise ------------------------------------------------------------------------------

__mise_cache=$__init_cache/mise-env.bash
__mise_sources=(
  "${XDG_CONFIG_HOME:-$HOME/.config}/mise/config.toml"
  /etc/mise/conf.d/*.toml
  "${MISE_DATA_DIR:-$HOME/.local/share/mise}/installs/.mise-installs.toml"
  "${MISE_DATA_DIR:-$HOME/.local/share/mise}/installs"
)

__mise_cache_stale() {
  [[ -s $__mise_cache ]] || return 0
  local f
  for f in "${__mise_sources[@]}"; do
    [[ $f -nt $__mise_cache ]] && return 0
  done
  return 1
}

# The global tools' env (GOROOT and friends) and bin dirs, as seen from $HOME.
__mise_cache_build() {
  command -v mise >/dev/null || return 1
  local env paths
  env=$(cd ~ && command mise env -s bash 2>/dev/null | grep -v '^export PATH=') || return 1
  paths=$(cd ~ && command mise bin-paths 2>/dev/null | paste -sd:) || return 1
  printf '%s\n__mise_bin_paths=%q\n' "$env" "$paths" >"$__mise_cache.$$" && mv -f "$__mise_cache.$$" "$__mise_cache"
}

__mise_cache_load() {
  local __mise_bin_paths= dir wrappers rest=
  source "$__mise_cache"
  [[ $__mise_bin_paths ]] || return 0
  # Same order as `mise activate`: Omarchy's command wrappers (agent accounts) first, then
  # the tools, then everything else. Tool dirs a parent shell left later in PATH move up.
  wrappers=${MISE_DATA_DIR:-$HOME/.local/share/mise}/command-wrappers/bin
  local IFS=:
  for dir in $PATH; do
    [[ $dir == "$wrappers" || :$__mise_bin_paths: == *:"$dir":* ]] || rest+=${rest:+:}$dir
  done
  if [[ :$PATH: == *:"$wrappers":* ]]; then
    PATH=$wrappers:$__mise_bin_paths:$rest
  else
    PATH=$__mise_bin_paths:$rest
  fi
  export PATH
}

if command -v mise >/dev/null; then
  if __mise_cache_stale; then __mise_cache_build; fi
  [[ -s $__mise_cache ]] && __mise_cache_load

  # Per-project versions: run the real hook only where a project mise config applies, and
  # once more on the way out so it restores the global tools.
  __mise_in_project=
  __mise_project_config() {
    local dir=$PWD
    while [[ $dir && $dir != "$HOME" ]]; do
      [[ -e $dir/mise.toml || -e $dir/.mise.toml || -e $dir/mise.local.toml || -e $dir/.tool-versions ||
        -e $dir/.config/mise.toml || -e $dir/.mise/config.toml ]] && return 0
      dir=${dir%/*}
    done
    return 1
  }
  _mise_hook_prompt_command() {
    local rc=$?
    if [[ $PWD != "${__mise_hook_pwd-}" ]]; then
      __mise_hook_pwd=$PWD
      if __mise_project_config; then
        __mise_in_project=1
        eval "$(command mise hook-env -s bash 2>/dev/null)"
      elif [[ $__mise_in_project ]]; then
        __mise_in_project=
        eval "$(command mise hook-env -s bash 2>/dev/null)"
      fi
    fi
    return "$rc"
  }
  PROMPT_COMMAND+=(_mise_hook_prompt_command)

  # After a command that changes tools, rebuild the cache and apply it to this shell.
  mise() {
    command mise "$@"
    local rc=$?
    case ${1-} in
      use | u | install | i | upgrade | up | uninstall | rm | remove | unuse | prune | link)
        __mise_cache_build && __mise_cache_load
        __mise_hook_pwd=
        ;;
    esac
    return "$rc"
  }
fi

# --- zoxide ----------------------------------------------------------------------------

if __zoxide_bin=$(command -v zoxide); then
  __zoxide_cache=$__init_cache/zoxide-init.bash
  if [[ ! -s $__zoxide_cache || $__zoxide_bin -nt $__zoxide_cache ]]; then
    zoxide init bash >"$__zoxide_cache.$$" && mv -f "$__zoxide_cache.$$" "$__zoxide_cache"
  fi
  source "$__zoxide_cache"
fi
unset __zoxide_bin __zoxide_cache

# --- the rest of Omarchy's init, unchanged ---------------------------------------------

if command -v try &>/dev/null; then
  try() {
    unset -f try
    eval "$(SHELL=/bin/bash command try init ~/Work/tries)"
    try "$@"
  }
fi

# Only the key bindings (Ctrl-R, Ctrl-T, Alt-C), as Omarchy does.
[[ -f /usr/share/fzf/key-bindings.bash ]] && source /usr/share/fzf/key-bindings.bash

source "$OMARCHY_PATH/default/bash/completions"
