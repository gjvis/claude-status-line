#!/bin/bash
# Claude Code statusLine command that also sets the iTerm2 tab title.
#
# Two jobs from one JSON payload on stdin:
#   1. set the tab title to "<repo>/<subpath> (claude) – <session name>"
#   2. render the status line by delegating to status-line.sh next to this script
#
# Claude Code spawns the statusLine command detached from the controlling terminal, so
# /dev/tty can't be opened here. Instead we find the terminal device of the ancestor
# `claude` process by walking the process tree, and write the OSC title escape straight
# to that device. The device is fixed for the session, so it's cached per session_id.
#
# Requires jq. Also set `export CLAUDE_CODE_DISABLE_TERMINAL_TITLE=1` and enable iTerm2's
# "Session Name" title component (see README).

input=$(cat)

sid=$(printf '%s' "$input" | jq -r '.session_id // empty')
dir=$(printf '%s' "$input" | jq -r '.workspace.current_dir // .cwd // empty')
name=$(printf '%s' "$input" | jq -r '.session_name // empty')

# Terminal device: cached per session, else discovered by walking to the first ttys ancestor.
cache="/tmp/.claude-termdev-${sid:-unknown}"
if [ -r "$cache" ]; then
  dev=$(cat "$cache")
else
  dev=""; pid=$$
  for _ in 1 2 3 4 5 6 7 8; do
    t=$(ps -o tty= -p "$pid" 2>/dev/null | tr -d '[:space:]')
    case "$t" in ttys*) dev="/dev/$t"; break ;; esac
    pid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d '[:space:]')
    { [ -z "$pid" ] || [ "$pid" -le 1 ] 2>/dev/null; } && break
  done
  [ -n "$dev" ] && printf '%s' "$dev" >"$cache"
fi

# Tab title, written to the discovered device.
if [ -n "$dev" ]; then
  if root=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null); then
    prefix=$(git -C "$dir" rev-parse --show-prefix 2>/dev/null)
    path="${root##*/}${prefix:+/${prefix%/}}"
  else
    path="${dir/#$HOME/~}"
  fi
  if [ -n "$name" ]; then
    printf '\e]1;%s (claude) – %s\a' "$path" "$name" >"$dev" 2>/dev/null
  else
    printf '\e]1;%s (claude)\a' "$path" >"$dev" 2>/dev/null
  fi
fi

# Render the status line (status-line.sh sits next to this script).
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
printf '%s' "$input" | "$here/status-line.sh"
