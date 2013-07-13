#!/bin/bash
DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

echo "Setting up from $DOTFILES_DIR ..."

[[ ! -s "$HOME/.bash_aliases" ]] && ln -s "$DOTFILES_DIR/bash/.bash_aliases" "$HOME/.bash_aliases"
[[ ! -s "$HOME/.bash_profile" ]] && ln -s "$DOTFILES_DIR/bash/.bash_profile" "$HOME/.bash_profile"
[[ ! -s "$HOME/.git-prompt.sh" ]] && ln -s "$DOTFILES_DIR/bash/.git-prompt.sh" "$HOME/.git-prompt.sh"
[[ ! -s "$HOME/.bin" ]] && ln -s "$DOTFILES_DIR/bash/bin" "$HOME/.bin"

if ! grep -q "$DOTFILES_DIR/bash/.bashrc" "$HOME/.bashrc"; then
  echo "Appending to $HOME/.bashrc ..."
  echo "source \"$DOTFILES_DIR/bash/.bashrc\"" >> "$HOME/.bashrc"
fi

echo "Done."