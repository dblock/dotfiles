#!/bin/bash

set -e

curl -sSL https://get.rvm.io | bash -s stable --ruby

rvm autolibs enable

rvm install 2.3.1

rvm use 2.3.1 --default
