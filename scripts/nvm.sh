#!/bin/bash

set -e

curl https://raw.github.com/creationix/nvm/master/install.sh | sh
source ~/.bash_profile

nvm install 0.10
nvm use 0.10

npm install -g coffee-script@1.0.1
