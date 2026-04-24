#!/bin/bash

input=$(cat)

MODEL=$(echo "$input" | jq -r '.model.display_name')
DIR=$(echo "$input" | jq -r '.workspace.current_dir')
AUTOCOMPACT_TOKENS=33000
read -r PCT FREE_PCT BUFFER_PCT < <(echo "$input" | jq -r --argjson buf "$AUTOCOMPACT_TOKENS" '
  (.context_window.context_window_size // 200000) as $size |
  ($buf / $size * 100) as $buffer |
  .context_window.used_percentage // empty |
  [floor, (100 - . - $buffer | round), ($buffer | round)] | @tsv')
EFFORT=$(jq -r '.effortLevel // empty' ~/.claude/settings.json 2>/dev/null)
[ -z "$EFFORT" ] && EFFORT="default"
CYAN='\033[36m'; GRAY='\033[38;2;153;153;153m'; PURPLE='\033[38;2;178;102;255m'; RESET='\033[0m'

BRANCH=""
git rev-parse --git-dir > /dev/null 2>&1 && BRANCH=" ($(git branch --show-current 2>/dev/null))"
DISPLAY_DIR="${DIR/#$HOME/~}"

if [ -n "$PCT" ]; then
  [ "$FREE_PCT" -lt 0 ] 2>/dev/null && FREE_PCT=0

  # Build proportional bar (50 segments)
  TOTAL=50
  USED_SEGS=$(( (PCT * TOTAL + 50) / 100 ))
  AUTO_COMPACT_SEGS=$(( (BUFFER_PCT * TOTAL + 50) / 100 ))
  FREE_SEGS=$(( TOTAL - USED_SEGS - AUTO_COMPACT_SEGS ))
  [ $FREE_SEGS -lt 0 ] && FREE_SEGS=0

  BAR=""
  for ((i=0; i<USED_SEGS; i++)); do BAR="${BAR}${PURPLE}⛁${RESET}"; done
  for ((i=0; i<FREE_SEGS; i++)); do BAR="${BAR}${GRAY}⛶${RESET}"; done
  for ((i=0; i<AUTO_COMPACT_SEGS; i++)); do BAR="${BAR}${GRAY}⛝${RESET}"; done

  echo -e "${CYAN}[$MODEL${RESET}${GRAY}/${EFFORT}${RESET}${CYAN}]${RESET} ${DISPLAY_DIR}$BRANCH ${BAR} ~${FREE_PCT}% free"
else
  echo -e "${CYAN}[$MODEL${RESET}${GRAY}/${EFFORT}${RESET}${CYAN}]${RESET} ${DISPLAY_DIR}$BRANCH"
fi
