#!/bin/bash
DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

[[ ! -e "$DOTFILES_DIR/backup" ]] && mkdir "$DOTFILES_DIR/backup"
sudo cp /etc/hosts "$DOTFILES_DIR/backup/hosts.backup"

sudo curl --silent http://someonewhocares.org/hosts/hosts > /etc/hosts

