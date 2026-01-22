#!/usr/bin/env bash
set -euo pipefail
RUN_ID="${1:-run-$(date +%Y%m%dT%H%M%S)}"
SESSION="llm.run.${RUN_ID}"
BUS="/tmp/${SESSION}.sock"


# Create detached session
if ! tmux has-session -t "$SESSION" 2>/dev/null; then
tmux new-session -d -s "$SESSION" -n router
fi


# Seed @user options (KV)
tmux set-option -t "$SESSION" @llm.run.id "$RUN_ID"
tmux set-option -t "$SESSION" @llm.bus.socket "$BUS"
tmux set-option -t "$SESSION" @cfg.model "qwen2.5-coder:7b"
tmux set-option -t "$SESSION" @cfg.temp "0.2"


# Export to tmux env (visible to child processes in panes)
tmux set-environment -t "$SESSION" -g RUN_ID "$RUN_ID"
tmux set-environment -t "$SESSION" -g BUS_SOCKET "$BUS"
tmux set-environment -t "$SESSION" -g MODEL "qwen2.5-coder:7b"
tmux set-environment -t "$SESSION" -g TEMP "0.2"


# Status line visualization
tmux set -t "$SESSION" status-right \
"run:#S model:#{@cfg.model} temp:#{@cfg.temp} bus:#{@llm.bus.socket} router:#{@router.status}"


echo "Bootstrapped session: $SESSION"