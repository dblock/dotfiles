#!/bin/bash

set -e

ruby -e "$(curl -fsSL https://raw.github.com/mxcl/homebrew/go)"

brew -v
mkdir -p /usr/local/Cellar
sudo chown -R $USER /usr/local/Cellar
brew update

echo "Install command-line tools from https://developer.apple.com/downloads."
