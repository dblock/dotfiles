#!/bin/bash

set -e

ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

brew -v
mkdir -p /usr/local/Cellar
sudo chown -R $USER /usr/local/Cellar
brew update

echo "Install command-line tools from https://developer.apple.com/downloads."
