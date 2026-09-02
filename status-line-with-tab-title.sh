#!/bin/bash
# Claude Code statusLine command that also sets the terminal tab title.
#
# Two jobs from one JSON payload on stdin:
#   1. set the tab title to "<colour> <repo>/<subpath>: <session name>"
#   2. render the status line by delegating to status-line.sh next to this script
#
# Claude Code spawns the statusLine command detached from the controlling terminal, so
# /dev/tty can't be opened here. Instead we find the terminal device of the ancestor
# `claude` process by walking the process tree and write the OSC title escape straight to
# it. The device is re-discovered each render so it stays correct if the session is resumed
# in a different terminal.
#
# Requires jq. Also set `export CLAUDE_CODE_DISABLE_TERMINAL_TITLE=1`; see the README
# for the per-terminal setup that makes the tab display the title.

input=$(cat)

dir=$(printf '%s' "$input" | jq -r '.workspace.current_dir // .cwd // empty')
name=$(printf '%s' "$input" | jq -r '.session_name // empty')
transcript=$(printf '%s' "$input" | jq -r '.transcript_path // empty')

# Terminal device: the first ttys ancestor.
dev=""; pid=$$
for _ in 1 2 3 4 5 6 7 8; do
  t=$(ps -o tty= -p "$pid" 2>/dev/null | tr -d '[:space:]')
  case "$t" in ttys*) dev="/dev/$t"; break ;; esac
  pid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d '[:space:]')
  { [ -z "$pid" ] || [ "$pid" -le 1 ] 2>/dev/null; } && break
done

# Tab title, written to the discovered device.
if [ -n "$dev" ]; then
  if root=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null); then
    prefix=$(git -C "$dir" rev-parse --show-prefix 2>/dev/null)
    path="${root##*/}${prefix:+/${prefix%/}}"
  else
    path="${dir/#$HOME/~}"
  fi

  # Session accent colour, chosen with /color. It is appended to the transcript as a
  # standalone {"type":"agent-color","agentColor":"<name>"} record each time it changes,
  # so the last such record is the current one. A tab title is plain text with no styling,
  # so the colour can only be carried by a coloured glyph: hearts are the one emoji shape
  # covering all eight names.
  colour=""
  if [ -f "$transcript" ]; then
    colour=$(LC_ALL=C grep -a '"type":"agent-color"' "$transcript" | tail -1 |
      jq -r '.agentColor // empty' 2>/dev/null)
  fi
  case "$colour" in
    red)    dot="❤️" ;;
    orange) dot="🧡" ;;
    yellow) dot="💛" ;;
    green)  dot="💚" ;;
    blue)   dot="💙" ;;
    purple) dot="💜" ;;
    pink)   dot="🩷" ;;
    cyan)   dot="🩵" ;;
    *)      dot="" ;;
  esac

  title="$path${name:+: $name}"
  printf '\e]0;%s\a' "${dot:+$dot }$title" >"$dev" 2>/dev/null
fi

# Render the status line (status-line.sh sits next to this script).
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
printf '%s' "$input" | "$here/status-line.sh"
