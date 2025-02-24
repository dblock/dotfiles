#!/bin/bash

set -e

[[ ! -s "$HOME/.rvmrc" ]] && echo 'export RVM_EXTRA_FLAGS="--with-openssl-dir=$(/opt/homebrew/bin/brew --prefix openssl)' >> ~/.rvmrc
