#!/bin/bash

set -e

# the *--disable-openmp* option is to be sure to disable OpenMP for ImageMagick
# it will segfault if ImageMagick is built with it enabled
# see https://github.com/rmagick/rmagick/issues/16

brew install -f imagemagick --disable-openmp

convert --version
