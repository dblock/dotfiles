# Hooks

Claude Code [hooks](https://code.claude.com/docs/en/hooks), one folder each. [scripts/setup.sh](../../../scripts/setup.sh) links this folder as `~/.claude/hooks`, and [settings.json](../settings.json) registers each hook by its path there, such as `$HOME/.claude/hooks/session-title/session-title.sh`.

| Hook | Event | Purpose |
| --- | --- | --- |
| [Session Titles](session-title/README.md) | `UserPromptSubmit` | Names each new session `<emoji> <project>` from its first prompt. |

## Adding a Hook

Create a folder named after the hook, holding an executable script of the same name, a `README.md` describing its behavior and configuration, and a `<name>.test.sh` that runs the script against fixtures. Register the script under its event in [settings.json](../settings.json), add a row above, and run `npm run lint`.
