#!/bin/bash

# Bind the session-switching "s" command to run fzf-tmux and enable fuzzy search of the session

LIST_DATA="#{session_name} #{pane_current_path}"
FZF_COMMAND="fzf-tmux -p --delimiter=: --with-nth 4 --color=hl:2"

TARGET_SPEC="#{session_name}:#{window_id}:#{pane_id}:"

LINE=$(tmux list-panes -a -F "$TARGET_SPEC $LIST_DATA" | $FZF_COMMAND) || exit 0
args=(${LINE//:/ })
tmux select-pane -t ${args[2]} && tmux select-window -t ${args[1]} && tmux switch-client -t ${args[0]}
