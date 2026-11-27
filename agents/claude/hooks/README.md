# Hooks

Claude Code [hooks](https://code.claude.com/docs/en/hooks), one folder each. [scripts/setup.sh](../../../scripts/setup.sh) links this folder as `~/.claude/hooks`, and [settings.json](../settings.json) registers each hook by its path there, such as `$HOME/.claude/hooks/<name>/<name>.sh`. There are no hooks at the moment; new sessions are named by the [agent-baby-names](https://github.com/dblock/agent-baby-names) plugin.

## Adding a Hook

Create a folder named after the hook, holding an executable script of the same name, a `README.md` describing its behavior and configuration, and a `<name>.test.sh` that runs the script against fixtures. Register the script under its event in [settings.json](../settings.json), list it above, and run `npm run lint`.
