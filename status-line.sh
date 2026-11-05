#!/bin/bash

input=$(cat)

MODEL=$(echo "$input" | jq -r '.model.display_name')
DIR=$(echo "$input" | jq -r '.workspace.current_dir')
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')
SESSION_ID=$(echo "$input" | jq -r '.session_id // empty')
AUTOCOMPACT_TOKENS=33000
USED_PCT=$(echo "$input" | jq -r --argjson buf "$AUTOCOMPACT_TOKENS" '
  (.context_window.context_window_size // 200000) as $size |
  .context_window.used_percentage // empty |
  (. + $buf / $size * 100) | round')
CONTEXT_TOKENS=$(echo "$input" | jq -r '
  .context_window.current_usage // empty |
  (.input_tokens + .cache_creation_input_tokens + .cache_read_input_tokens)')
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

TOKENS_TEXT=""
if [ -n "$CONTEXT_TOKENS" ]; then
  if [ "$CONTEXT_TOKENS" -ge 1000 ]; then TOKENS_TEXT="$(( (CONTEXT_TOKENS + 500) / 1000 ))k"
  else TOKENS_TEXT="$CONTEXT_TOKENS"
  fi
fi

CONTEXT_DISPLAY=""
if [ -n "$USED_PCT" ]; then
  [ "$USED_PCT" -gt 100 ] && USED_PCT=100
  if [ "$USED_PCT" -le 50 ]; then USED_COLOUR=$GREEN
  elif [ "$USED_PCT" -le 80 ]; then USED_COLOUR=$YELLOW
  else USED_COLOUR=$RED
  fi
  CONTEXT_TEXT="~${USED_PCT}%"
  [ -n "$TOKENS_TEXT" ] && CONTEXT_TEXT="${CONTEXT_TEXT} / ${TOKENS_TEXT}"
  CONTEXT_DISPLAY=" ${USED_COLOUR}${CONTEXT_TEXT}${RESET}"
elif [ -n "$TOKENS_TEXT" ]; then
  CONTEXT_DISPLAY=" ${GRAY}${TOKENS_TEXT}${RESET}"
fi

echo -e "${CYAN}[$MODEL${RESET}${GRAY}/${EFFORT}${RESET}${CYAN}]${RESET}${COST_DISPLAY} ${DISPLAY_DIR}$BRANCH${CONTEXT_DISPLAY}${SESSION_DISPLAY}"
