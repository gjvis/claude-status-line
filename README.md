# claude-status-line

Custom status line script for [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

Shows model, effort level, session cost, working directory, git branch, estimated context used and the number of tokens in context, and the session id.

```
[Opus 5.5/high] $1.23 ~/project (main) ~26% / 52k 4114a532-d6eb-49d6-b15f-646b55bda0ab
```

The percentage is how much of the context window is used, counting the ~33k token autocompact buffer as used, so it reaches 100% when autocompact triggers. It is green up to 50%, yellow from 51% to 80%, and red above 80%.

After the slash is the number of tokens in the context window as of the last response (input, cache creation and cache read tokens), rounded to the nearest thousand.

The session id is the full id, so it can be passed to `claude --resume <id>`.

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

## Tab title

`status-line-with-tab-title.sh` is a wrapper that renders the status line *and* sets the terminal tab title to `<colour> <repo>: <session name>`, where `<repo>` is the name of the repository's top-level directory (outside a repository, the working directory relative to `~`), the session name is whatever you set with `/rename` (unnamed sessions show just `<repo>`) and the colour is a heart matching the accent colour you set with `/color`. It delegates rendering to `status-line.sh` in the same directory, so keep the two files together.

The title is set with an OSC 0 escape (`\e]0;...`), which sets both the window title and the icon/session name, so it works across terminals rather than depending on one terminal's title handling.

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

3. Make your terminal display the title the wrapper sets:

   - **iTerm2**: Settings → Profiles → *your profile* → General → Title → tick **Session Name**. Without it the tab ignores the title.
   - **Ghostty**: its shell integration otherwise overwrites the tab with the running command, so turn that one feature off in `config`:

     ```
     shell-integration-features = cursor,no-sudo,no-title,no-ssh-env,no-ssh-terminfo,path
     ```

Then `/rename <name>` sets the summary and the tab updates within a refresh.

### The colour

A tab title is plain text – no terminal styles the title itself, and Ghostty's own tab colouring is a right-click menu with nothing behind it a script can drive: no escape sequence, no keybind action, no AppleScript property on its `tab` class, no Shortcuts intent. So the colour is carried by a coloured glyph in the title text, and hearts are the one emoji shape that covers all eight of Claude Code's accent colours (the coloured-circle emoji have no pink or cyan):

| `/color` | ❤️ red | 🧡 orange | 💛 yellow | 💚 green | 💙 blue | 💜 purple | 🩷 pink | 🩵 cyan |
| -------- | ------ | --------- | --------- | -------- | ------- | --------- | ------- | ------- |

`/color default`, or never running `/color`, leaves the title unprefixed.

Claude Code appends the accent colour to the session transcript as its own `{"type":"agent-color","agentColor":"<name>"}` record every time it changes, so the wrapper reads the last such record from the `transcript_path` it is handed. That means the colour survives `/resume`, and a `/clear` starts an uncoloured session because it starts a new transcript.
