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

# Link $2 to $1. Re-point links that already point into this repository (so moved files are
# picked up); leave any other existing file or link alone.
link_agent_file() {
  local target="$1" link="$2"
  mkdir -p "$(dirname "$link")"
  if [[ -L "$link" && "$(readlink "$link")" == "$DOTFILES_DIR"/* ]]; then
    ln -sfn "$target" "$link"
  elif [[ -e "$link" || -L "$link" ]]; then
    echo "Skipping $link: it exists and does not point into $DOTFILES_DIR."
  else
    ln -s "$target" "$link"
  fi
}

# Agent instructions: shared instructions plus per-tool overrides (see agents/README.md).
link_agent_file "$DOTFILES_DIR/agents/instructions.md" "$HOME/.copilot/copilot-instructions.md"
link_agent_file "$DOTFILES_DIR/agents/copilot/copilot.instructions.md" "$HOME/.copilot/instructions/copilot.instructions.md"
link_agent_file "$DOTFILES_DIR/agents/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
link_agent_file "$DOTFILES_DIR/agents/claude/settings.json" "$HOME/.claude/settings.json"

# Shared skills, linked into both tools.
for skill_dir in "$DOTFILES_DIR"/agents/skills/*; do
  [[ -f "$skill_dir/SKILL.md" ]] || continue
  link_agent_file "$skill_dir" "$HOME/.copilot/skills/$(basename "$skill_dir")"
  link_agent_file "$skill_dir" "$HOME/.claude/skills/$(basename "$skill_dir")"
done

# Project lists for the update-dependencies skill.
link_agent_file "$DOTFILES_DIR/agents/skills/update-dependencies/projects.yml" "$HOME/.config/update-dependencies/projects.yml"

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
