# claude-status-line

Custom status line script for [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

Shows model, effort level, working directory, git branch, a context window usage bar, and estimated free space (accounting for the 16.5% autocompact buffer).

```
[Opus 4.6/high] ~/project (main) ⛁⛁⛁⛁⛁⛶⛶⛶⛶⛶⛶⛶⛶⛶⛶⛶⛶⛶⛶⛶⛶⛶⛶⛶⛶⛶⛶⛶⛶⛶⛶⛶⛶⛶⛶⛶⛶⛶⛶⛶⛶⛝⛝⛝⛝⛝⛝⛝⛝⛝ ~77% free
```

## Setup

Requires `jq`. Add to `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "/path/to/status-line.sh"
  }
}
```
