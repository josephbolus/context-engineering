# tmux KV for LLM CLI agents/subagents

Practical patterns to coordinate CLI-based agents/subagents using tmux **user options** (`@keys`), tmux **environment**, and **wait-for** signaling. Copy‑pasteable snippets included.

---

## Why tmux here?

* **Lightweight state** per server/session/window/pane via `@user` options (a simple key–value store).
* **Broadcastable config** via `set-environment` to child processes.
* **Signaling/synchronization** via `wait-for` (notify/listen) — perfect for agent readiness and handoffs.
* **Namespacing** by session → isolate one run per session.

> tmux options are strings only; not a DB. Use them for small state, flags, endpoints, and run IDs. Pair with `wait-for` when you need coordination.

---

## Naming & scoping conventions

Use **one session per orchestration run**, and namespace keys with **dot notation** that’s shell‑friendly.

* Session name: `llm.run.<RUN_ID>` (e.g., `llm.run.2025-10-29T23-40-00`)
* Keys (examples):

  * `@llm.run.id` → global run identifier
  * `@llm.bus.socket` → path to Unix socket/message bus
  * `@router.status`, `@worker.<n>.status` → status text/enum
  * `@cfg.model`, `@cfg.temp`, `@cfg.ctx` → config
  * `@roles` → comma list of active roles

**Scope rule**: set on the **session** unless you need a narrower override (window/pane). Readers inherit per tmux precedence: pane → window → session → server.

---

## Bootstrap: create a run, seed KV & env

```bash
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
  "run:#S  model:#{@cfg.model}  temp:#{@cfg.temp}  bus:#{@llm.bus.socket}  router:#{@router.status}"

echo "Bootstrapped session: $SESSION"
```

Run: `./bootstrap.sh run-42`

---

## Tiny KV helpers (bash)

```bash
# tkv.sh — minimal wrappers around tmux show/set for @user options

# Scope: -t <session> (or window/pane) is passed through from TMUX_TARGET
: "${TMUX_TARGET:=}"

_t() { tmux ${TMUX_TARGET:+-t "$TMUX_TARGET"} "$@"; }

tkv_set() { # key value
  local k="$1"; shift; local v="$*"; _t set-option "@$k" "$v"; }

tkv_get() { # key -> prints value or empty
  local k="$1"; _t show-options -qv "@$k"; }

tkv_unset() { local k="$1"; _t set-option -u "@$k"; }

# Slightly safer set with a lock using wait-for (best-effort)
# Usage: tkv_lock_set cfg.temp 0.4
_tkv_lock() { _t wait-for -L "$1"; }
_tkv_unlock() { _t wait-for -U "$1"; }

tkv_lock_set() {
  local k="$1"; shift; local v="$*"; local lk="lock.@$k"
  _tkv_lock "$lk"; _t set-option "@$k" "$v"; _tkv_unlock "$lk";
}
```

Use:

```bash
TMUX_TARGET="-t llm.run.run-42" source ./tkv.sh

# set
 tkv_set cfg.ctx 8192
# get
 echo "CTX=$(tkv_get cfg.ctx)"
# lock+set (best-effort)
 tkv_lock_set cfg.temp 0.35
```

---

## Process‑visible config vs tmux‑only state

* **Child process needs it?** Use `set-environment` (tmux env) so the spawned shell sees `$VAR`.
* **Only tmux needs it (status line, conditions, orchestration logic)?** Use `@user` options.

Example both:

```bash
# tmux env for processes
 tmux set-environment -t llm.run.run-42 -g OPENAI_BASE_URL http://127.0.0.1:11434
# tmux-side formatting/state
 tmux set-option -t llm.run.run-42 @router.status online
```

---

## Signaling with wait-for (pub/sub‑ish)

* **Signal**: `tmux wait-for -S <topic>`
* **Wait**: `tmux wait-for <topic>` (blocks until signaled once)

Patterns:

```bash
# Router declares readiness
 tmux wait-for -S run-42.router.ready

# Worker panes block until router is ready
 tmux wait-for run-42.router.ready
```

Multi-producer coordination:

```bash
# Router waits until N workers signal up
for i in 1 2 3; do tmux wait-for "run-42.worker.$i.ready"; done
# then broadcast go
 tmux wait-for -S run-42.all.ready
```

---

## End‑to‑end example: router + 2 workers

Create panes that read tmux env/KV and coordinate via wait‑for.

```bash
SESSION="llm.run.run-42"

# 1) Router pane
 tmux send-keys -t "$SESSION":router.0 'set -euo pipefail; echo "Router starting for $RUN_ID"; \
  BUS=$(tmux show -t "$SESSION" -qv @llm.bus.socket); \
  tmux set -t "$SESSION" @router.status starting; \
  sleep 1; \
  tmux set -t "$SESSION" @router.status online; \
  tmux wait-for -S run-42.router.ready; \
  echo "Router ONLINE on $BUS"; \
  tail -f /dev/null' C-m

# 2) Worker window with 2 panes
 tmux new-window -t "$SESSION" -n workers 'bash -lc "sleep infinity"'
 tmux split-window -t "$SESSION":workers -h 'bash -lc "sleep infinity"'

# worker 1
 tmux send-keys -t "$SESSION":workers.0 'set -euo pipefail; \
  tmux wait-for run-42.router.ready; \
  BUS=$(tmux show -t "$SESSION" -qv @llm.bus.socket); \
  MODEL=$(tmux show-environment -t "$SESSION" -g | sed -n "s/^MODEL=//p"); \
  tmux set -t "$SESSION" @worker.1.status online; \
  tmux wait-for -S run-42.worker.1.ready; \
  echo "W1 ONLINE model=$MODEL bus=$BUS"; tail -f /dev/null' C-m

# worker 2
 tmux send-keys -t "$SESSION":workers.1 'set -euo pipefail; \
  tmux wait-for run-42.router.ready; \
  TEMP=$(tmux show-environment -t "$SESSION" -g | sed -n "s/^TEMP=//p"); \
  tmux set -t "$SESSION" @worker.2.status online; \
  tmux wait-for -S run-42.worker.2.ready; \
  echo "W2 ONLINE temp=$TEMP"; tail -f /dev/null' C-m

# Router waits for workers, then signals all-go
 tmux send-keys -t "$SESSION":router.0 'for i in 1 2; do tmux wait-for run-42.worker.$i.ready; done; echo ALL_READY; tmux wait-for -S run-42.all.ready' C-m
```

Now any agent can block on `run-42.all.ready` before starting a task.

---

## Dynamic reconfiguration during a run

Update KV on-the-fly and let agents react if they poll or subscribe via lightweight loops.

```bash
# change temperature at runtime
 tmux set -t "$SESSION" @cfg.temp 0.45

# sample watcher snippet for an agent (bash)
prev=""; while true; do v=$(tmux show -t "$SESSION" -qv @cfg.temp);
  [[ "$v" != "$prev" ]] && { echo "temp-> $v"; prev="$v"; }
  sleep 1
done
```

> For heavier change streams, prefer a real pub/sub (redis, nats) and keep tmux as local control plane.

---

## TTL/expiry pattern (soft)

Store `@key.value` + `@key.expires_at` (unix epoch). Readers check freshness.

```bash
now=$(date +%s)
exp=$(( now + 120 ))
 tmux set -t "$SESSION" @cfg.api_token "abc123"
 tmux set -t "$SESSION" @cfg.api_token.expires_at "$exp"

# reader
read_token() {
  local s="$SESSION"; local now=$(date +%s)
  local tok=$(tmux show -t "$s" -qv @cfg.api_token)
  local exp=$(tmux show -t "$s" -qv @cfg.api_token.expires_at)
  [[ -z "$tok" || -z "$exp" || $now -ge $exp ]] && return 1
  printf %s "$tok"
}
```

---

## Pane‑local overrides

Sometimes a subagent needs a local scratch var; set a **pane option** so it doesn’t pollute session.

```bash
# tmux ≥3 supports -p/–pane options
 tmux set-option -pt "$SESSION":workers.0 @task.id "ingest-001"
 echo "pane task: $(tmux show -pt "$SESSION":workers.0 -qv @task.id)"
```

---

## Guardrails & security notes

* **Do not store secrets** in `@user` options — anyone who can talk to tmux can read them.
* **Persistence**: options vanish when the tmux server exits; re‑seed on bootstrap.
* **Atomicity**: last‑writer‑wins; use `wait-for` locks for best‑effort serialization.
* **Observability**: expose salient state on `status-right` for at‑a‑glance health.

---

## Minimal make targets (optional)

```makefile
SESSION?=llm.run.$(shell date +%Y%m%dT%H%M%S)

bootstrap:
	./bootstrap.sh $(SESSION)

router-ready:
	tmux wait-for -S $(SESSION).router.ready

all-ready:
	tmux wait-for -S $(SESSION).all.ready

clean:
	-tmux kill-session -t $(SESSION) 2>/dev/null || true
```

---

## Troubleshooting quickies

* **`show-options -qv` prints nothing** → key not set at that scope; try broader scope or check session name.
* **Child process can’t see var** → you used `@user` option; export with `set-environment`.
* **Signals never unblock** → verify you’re signaling the exact same topic string.
* **Session isolation** → always qualify with `-t <session>`.

---

## Ready-to-use one‑file demo

```bash
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
```

Run: `bash demo.sh run-42` then in any shell:

```bash
# Bring the system up
 tmux wait-for run-42.router.ready
 tmux wait-for -S run-42.worker.1.ready
 tmux wait-for -S run-42.worker.2.ready
 tmux wait-for run-42.all.ready # optional if router emits after both
```

---

## When to bring an external KV/queue

* Need durability or history (restarts, metrics) → sqlite/postgres/redis
* Need pub/sub fanout with backpressure → nats/redis streams
* Need atomic CAS or distributed locks → etcd/consul/redis (SET NX)

Use tmux as a **local control plane**; promote to external infra when the orchestration’s complexity justifies it.

---

**Cheat sheet**

```
# set/get/unset
 tmux set -t <session> @key value
 tmux show -t <session> -qv @key
 tmux set -ut <session> @key

# env to child processes
 tmux set-environment -t <session> -g NAME value
 tmux show-environment -t <session> -g

# signal & wait
 tmux wait-for -S topic
 tmux wait-for topic
```
