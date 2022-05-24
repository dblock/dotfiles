#!/bin/bash

set -e

git config --global user.name "Daniel (dB.) Doubrovkine"
git config --global user.email "dblock@dblock.org"
git config --global push.default simple

# https://hackernoon.com/lesser-known-git-commands-151a1918a60#.qm8moxzcy
git config --global alias.please 'push --force-with-lease'
git config --global alias.commend 'commit --amend --no-edit'
git config --global alias.it '!git init && git commit -m "Initial commit." --allow-empty'
git config --global alias.s 'status --short --branch'
git config --global alias.grog 'log --graph --abbrev-commit --decorate --all --format=format:"%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(dim white) - %an%C(reset) %C(bold green)(%ar)%C(reset)%C(bold yellow)%d%C(reset)%n %C(white)%s%C(reset)"'

git config --global core.editor 'vi'