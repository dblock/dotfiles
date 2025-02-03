#!/bin/bash

set -e

curl -sSL https://get.rvm.io | bash -s stable --ruby

rvm autolibs enable

rvm install 3.4.1

rvm use 3.4.1 --default

rvm rvmrc warning ignore allGemfiles
