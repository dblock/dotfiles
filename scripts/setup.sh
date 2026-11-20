#!/bin/bash
DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

echo "Setting up from $DOTFILES_DIR ..."

[[ ! -s "$HOME/.bash_aliases" ]] && ln -s "$DOTFILES_DIR/bash/.bash_aliases" "$HOME/.bash_aliases"
[[ ! -s "$HOME/.bash_profile" ]] && ln -s "$DOTFILES_DIR/bash/.bash_profile" "$HOME/.bash_profile"
[[ ! -s "$HOME/.git-prompt.sh" ]] && ln -s "$DOTFILES_DIR/bash/.git-prompt.sh" "$HOME/.git-prompt.sh"
[[ ! -s "$HOME/.git-completion.sh" ]] && ln -s "$DOTFILES_DIR/bash/.git-completion.sh" "$HOME/.git-completion.sh"
[[ ! -s "$HOME/.bin" ]] && ln -s "$DOTFILES_DIR/bash/bin" "$HOME/.bin"
[[ ! -s "$HOME/.jsbeautifyrc" ]] && ln -s "$DOTFILES_DIR/bash/.jsbeautifyrc" "$HOME/.jsbeautifyrc"
[[ ! -s "$HOME/.inputrc" ]] && ln -s "$DOTFILES_DIR/bash/.inputrc" "$HOME/.inputrc"

mkdir -p "$HOME/.copilot"
instructions_link="$HOME/.copilot/copilot-instructions.md"
[[ -e "$instructions_link" || -L "$instructions_link" ]] || ln -s "$DOTFILES_DIR/.copilot/copilot-instructions.md" "$instructions_link"

for skill_dir in "$DOTFILES_DIR"/.copilot/skills/*; do
  [[ -f "$skill_dir/SKILL.md" ]] || continue
  mkdir -p "$HOME/.copilot/skills"
  skill_link="$HOME/.copilot/skills/$(basename "$skill_dir")"
  [[ -e "$skill_link" || -L "$skill_link" ]] || ln -s "$skill_dir" "$skill_link"
done

mkdir -p "$HOME/.claude"
claude_link="$HOME/.claude/CLAUDE.md"
[[ -e "$claude_link" || -L "$claude_link" ]] || ln -s "$DOTFILES_DIR/.claude/CLAUDE.md" "$claude_link"
claude_settings_link="$HOME/.claude/settings.json"
[[ -e "$claude_settings_link" || -L "$claude_settings_link" ]] || ln -s "$DOTFILES_DIR/.claude/settings.json" "$claude_settings_link"

for skill_dir in "$DOTFILES_DIR"/.claude/skills/*; do
  [[ -f "$skill_dir/SKILL.md" ]] || continue
  mkdir -p "$HOME/.claude/skills"
  skill_link="$HOME/.claude/skills/$(basename "$skill_dir")"
  [[ -e "$skill_link" || -L "$skill_link" ]] || ln -s "$skill_dir" "$skill_link"
done

if [[ "$(uname)" == "Darwin" ]]; then
  mkdir -p "$HOME/Library/LaunchAgents"
  for agent in "$DOTFILES_DIR"/scripts/osx/LaunchAgents/*.plist; do
    [[ -f "$agent" ]] || continue
    agent_link="$HOME/Library/LaunchAgents/$(basename "$agent")"
    [[ -e "$agent_link" || -L "$agent_link" ]] || ln -s "$agent" "$agent_link"
  done
fi

if ! grep -q "$DOTFILES_DIR/bash/.bashrc" "$HOME/.bashrc"; then
  echo "Appending to $HOME/.bashrc ..."
  echo "source \"$DOTFILES_DIR/bash/.bashrc\"" >> "$HOME/.bashrc"
fi

echo "Done."
