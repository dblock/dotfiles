#!/bin/bash

set -e

bash -s stable < <(curl -s https://raw.github.com/wayneeseguin/rvm/master/binscripts/rvm-installer)

rvm autolibs enable

rvm install 1.9.3
rvm install 2.0

rvm use 2.0 --default
