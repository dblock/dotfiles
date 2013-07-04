#!/bin/bash

sudo apt-get install xvfb libgl1-mesa-dri xfonts-100dpi xfonts-75dpi xfonts-scalable xfonts-cyrillic
sudo cp xvfb/init.d/xvfb /etc/init.d
sudo chmod 755 /etc/init.d/xvfb
sudo service xvfb start
sudo update-rc.d xvfb defaults
