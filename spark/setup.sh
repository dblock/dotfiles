#!/bin/bash

DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

echo "Setting up from $DOTFILES_DIR ..."

export SPARK_VERSION=2.1.0

[ ! -d /usr/local/Cellar/apache-spark/$SPARK_VERSION/ ] && brew install spark
[ ! -d /usr/local/Cellar/apache-spark/$SPARK_VERSION/ ] && { echo "Can't find Spark installation in /usr/local/Cellar/apache-spark/$SPARK_VERSION, run 'brew install spark' first." ; exit 1; }

cd /usr/local/Cellar/apache-spark/$SPARK_VERSION/
export SPARK_HOME=$(pwd)

# connect Hive to Spark
ln -f -s $DOTFILES_DIR/hive/conf/hive-site.xml $SPARK_HOME/libexec/conf/hive-site.xml

echo "Done."
