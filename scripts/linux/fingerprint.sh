#!/bin/bash

# http://www.n-view.net/Appliance/fingerprint/

sudo add-apt-repository ppa:fingerprint/fingerprint-gui
sudo apt-get update
sudo apt-get install libbsapi policykit-1-fingerprint-gui

