#!/bin/bash

set -e

brew install mongo

# automatically start mongo on login
ln -sfv /usr/local/opt/mongodb/*.plist ~/Library/LaunchAgents
launchctl load ~/Library/LaunchAgents/homebrew.mxcl.mongodb.plist
launchctl start homebrew.mxcl.mongodb

mongo --version
