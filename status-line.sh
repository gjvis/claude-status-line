#!/bin/bash

input=$(cat)

MODEL=$(echo "$input" | jq -r '.model.display_name')
DIR=$(echo "$input" | jq -r '.workspace.current_dir')
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')
SESSION_ID=$(echo "$input" | jq -r '.session_id // empty')
AUTOCOMPACT_TOKENS=33000
read -r PCT FREE_PCT BUFFER_PCT < <(echo "$input" | jq -r --argjson buf "$AUTOCOMPACT_TOKENS" '
  (.context_window.context_window_size // 200000) as $size |
  ($buf / $size * 100) as $buffer |
  .context_window.used_percentage // empty |
  [floor, (100 - . - $buffer | round), ($buffer | round)] | @tsv')
EFFORT=$(echo "$input" | jq -r '.effort.level // empty')
[ -z "$EFFORT" ] && EFFORT=$(jq -r '.effortLevel // empty' ~/.claude/settings.json 2>/dev/null)
[ -z "$EFFORT" ] && EFFORT="default"
CYAN='\033[36m'; GRAY='\033[38;2;153;153;153m'; GREEN='\033[32m'; YELLOW='\033[33m'; RED='\033[31m'; RESET='\033[0m'

COST_DISPLAY=""
[ -n "$COST" ] && COST_DISPLAY=$(printf " ${GRAY}\$%.2f${RESET}" "$COST")

BRANCH=""
git rev-parse --git-dir > /dev/null 2>&1 && BRANCH=" ($(git branch --show-current 2>/dev/null))"
DISPLAY_DIR="${DIR/#$HOME/~}"

SESSION_DISPLAY=""
[ -n "$SESSION_ID" ] && SESSION_DISPLAY=" ${GRAY}${SESSION_ID}${RESET}"

CONTEXT_DISPLAY=""
if [ -n "$PCT" ]; then
  [ "$FREE_PCT" -lt 0 ] 2>/dev/null && FREE_PCT=0
  if [ "$FREE_PCT" -ge 50 ]; then FREE_COLOUR=$GREEN
  elif [ "$FREE_PCT" -ge 20 ]; then FREE_COLOUR=$YELLOW
  else FREE_COLOUR=$RED
  fi
  CONTEXT_DISPLAY=" ${FREE_COLOUR}~${FREE_PCT}% free${RESET}"
fi

echo -e "${CYAN}[$MODEL${RESET}${GRAY}/${EFFORT}${RESET}${CYAN}]${RESET}${COST_DISPLAY} ${DISPLAY_DIR}$BRANCH${CONTEXT_DISPLAY}${SESSION_DISPLAY}"
