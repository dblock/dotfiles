#!/bin/bash

DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

echo "Setting up from $DOTFILES_DIR ..."

export HIVE_VERSION=2.1.0

[ ! -d /usr/local/Cellar/hive/$HIVE_VERSION/ ] && brew install hive
[ ! -d /usr/local/Cellar/hive/$HIVE_VERSION/ ] && { echo "Can't find Hive installation in /usr/local/Cellar/hive/$HIVE_VERSION, run 'brew install hive' first." ; exit 1; }

cd /usr/local/Cellar/hive/$HIVE_VERSION/
export HIVE_HOME=$(pwd)

hdfs dfs -mkdir /tmp
hdfs dfs -mkdir /user/hive/warehouse
hdfs dfs -mkdir -p /user/hive/warehouse
hdfs dfs -chmod g+w /tmp
hdfs dfs -chmod g+w /user/hive/warehouse

mkdir -p hcatalog/var/log
touch hcatalog/var/log/hcat.out

ln -f -s $DOTFILES_DIR/hive/conf/hive-site.xml $HIVE_HOME/libexec/conf/hive-site.xml

schematool -initSchema -dbType derby

echo "Done."
