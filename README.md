# claude-status-line

Custom status line script for [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

Shows model, effort level, working directory, git branch, a context window usage bar, and estimated free space (accounting for the ~33k token autocompact buffer, calculated dynamically from the context window size).

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

## Tab title (iTerm2)

`status-line-with-tab-title.sh` is a wrapper that renders the status line *and* sets the iTerm2 tab title to `<repo>/<subpath> – <session name>`, where the session name is whatever you set with `/rename` (unnamed sessions show just `<repo>/<subpath>`). It delegates rendering to `status-line.sh` in the same directory, so keep the two files together.

Why a wrapper: Claude Code runs the statusLine command detached from the terminal, so it can't set the title via `/dev/tty`. The wrapper finds the terminal device of the ancestor `claude` process by walking the process tree and writes the title escape straight to it.

Setup, in addition to `jq`:

1. Point `statusLine` at the wrapper instead of `status-line.sh`:

   ```json
   {
     "statusLine": {
       "type": "command",
       "command": "/path/to/status-line-with-tab-title.sh"
     }
   }
   ```

2. Stop Claude Code writing its own title over the wrapper's – add to your shell rc:

   ```sh
   export CLAUDE_CODE_DISABLE_TERMINAL_TITLE=1
   ```

3. Enable iTerm2's **Session Name** title component: Settings → Profiles → *your profile* → General → Title → tick **Session Name**. Without it the tab ignores the title the wrapper sets.

Then `/rename <name>` sets the summary and the tab updates within a refresh.
