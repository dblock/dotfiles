#!/bin/bash
DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

echo "Setting up from $DOTFILES_DIR ..."

pushd /tmp

export HIVE_VERSION=1.2.1

[ ! -d /usr/local/Cellar/apache-hive-$HIVE_VERSION ] && {
  wget http://mirror.nexcess.net/apache/hive/hive-$HIVE_VERSION/apache-hive-$HIVE_VERSION-bin.tar.gz
  tar vfxz apache-hive-$HIVE_VERSION-bin.tar.gz
  mv apache-hive-$HIVE_VERSION-bin /usr/local/Cellar/apache-hive-$HIVE_VERSION
}

cd /usr/local/Cellar/apache-hive-$HIVE_VERSION
export HIVE_HOME=$(pwd)

hdfs dfs -mkdir /tmp
hdfs dfs -mkdir /user/hive/warehouse
hdfs dfs -mkdir -p /user/hive/warehouse
hdfs dfs -chmod g+w /tmp
hdfs dfs -chmod g+w /user/hive/warehouse

mkdir -p hcatalog/var/log
touch hcatalog/var/log/hcat.out

ln -f -s $DOTFILES_DIR/hive/conf/hive-site.xml $HIVE_HOME/conf/hive-site.xml

if ! grep -q "$DOTFILES_DIR/hive/.profile" "$HOME/.profile"; then
  echo "Appending to $HOME/.profile ..."
  echo "source \"$DOTFILES_DIR/hive/.profile\"" >> "$HOME/.profile"
fi

echo "Run source \"$DOTFILES_DIR/hive/.profile\" now to get hive path."
echo "Done."

popd
