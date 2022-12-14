#!/bin/bash

brew install gpg

gpg --import ~/Dropbox/Personal/7C94E183.gpg
gpg --import-ownertrust < ~/Dropbox/Personal/7C94E183.trustlevel.txt

git config --global user.signingkey 75BF031B7C94E183
git config --global commit.gpgsign true
