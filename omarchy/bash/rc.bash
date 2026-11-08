# Omarchy's default/bash/rc with its init swapped for init.bash (same features, ~100ms faster
# per shell, no mise hook on every cd). Sourced from ~/.bashrc in place of Omarchy's rc.
# To go back to stock: source "$OMARCHY_PATH/default/bash/rc" from ~/.bashrc instead.
source "$OMARCHY_PATH/default/bash/envs"
source "$OMARCHY_PATH/default/bash/shell"
source "$OMARCHY_PATH/default/bash/aliases"
source "$OMARCHY_PATH/default/bash/functions"
source ~/.config/bash/init.bash
[[ $- == *i* ]] && bind -f "$OMARCHY_PATH/default/bash/inputrc"
