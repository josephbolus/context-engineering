# demo.sh — spin a router + 2 workers demo using tmux KV + wait-for
set -euo pipefail
RUN_ID=${1:-run-$(date +%Y%m%dT%H%M%S)}
SESSION="llm.run.$RUN_ID"
BUS="/tmp/$SESSION.sock"


# Start session
tmux new-session -d -s "$SESSION" -n router


# Seed KV and env
tmux set -t "$SESSION" @llm.run.id "$RUN_ID"
tmux set -t "$SESSION" @llm.bus.socket "$BUS"
tmux set -t "$SESSION" @cfg.model "qwen2.5-coder:7b"
tmux set -t "$SESSION" @cfg.temp "0.2"
tmux set-environment -t "$SESSION" -g RUN_ID "$RUN_ID"
tmux set-environment -t "$SESSION" -g BUS_SOCKET "$BUS"
tmux set-environment -t "$SESSION" -g MODEL "qwen2.5-coder:7b"
tmux set-environment -t "$SESSION" -g TEMP "0.2"
tmux set -t "$SESSION" status-right "#S m=#{@cfg.model} t=#{@cfg.temp} bus=#{@llm.bus.socket} rtr=#{@router.status}"


# Router code
tmux send-keys -t "$SESSION":router.0 'set -euo pipefail; tmux set -t '"$SESSION"' @router.status starting; \
echo "[router] RUN_ID=$RUN_ID BUS=$BUS"; sleep 1; \
tmux set -t '"$SESSION"' @router.status online; \
tmux wait-for -S '"$RUN_ID"'.router.ready; \
echo "[router] ONLINE"; tail -f /dev/null' C-m


# Workers window
tmux new-window -t "$SESSION" -n workers 'bash -lc "sleep infinity"'
tmux split-window -t "$SESSION":workers -h 'bash -lc "sleep infinity"'


# W1
tmux send-keys -t "$SESSION":workers.0 'set -euo pipefail; tmux wait-for '"$RUN_ID"'.router.ready; \
BUS=$(tmux show -t '"$SESSION"' -qv @llm.bus.socket); \
tmux set -t '"$SESSION"' @worker.1.status online; \
echo "[w1] bus=$BUS"; tmux wait-for -S '"$RUN_ID"'.worker.1.ready; tail -f /dev/null' C-m


# W2
tmux send-keys -t "$SESSION":workers.1 'set -euo pipefail; tmux wait-for '"$RUN_ID"'.router.ready; \
TEMP=$(tmux show-environment -t '"$SESSION"' -g | sed -n "s/^TEMP=//p"); \
tmux set -t '"$SESSION"' @worker.2.status online; \
echo "[w2] temp=$TEMP"; tmux wait-for -S '"$RUN_ID"'.worker.2.ready; tail -f /dev/null' C-m


# Open session UI
tmux attach -t "$SESSION"