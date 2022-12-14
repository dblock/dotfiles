#!/bin/bash

set -e

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

brew -v
mkdir -p /usr/local/Cellar
sudo chown -R $USER /usr/local/Cellar
brew update

echo "Install command-line tools from https://developer.apple.com/downloads."
