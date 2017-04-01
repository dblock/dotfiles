#!/bin/bash
DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

echo "Setting up from $DOTFILES_DIR ..."

export HADOOP_VERSION=2.7.3

# brew install hadoop

[ ! -d /usr/local/Cellar/hadoop/$HADOOP_VERSION/ ] && { echo "Can't find Hadoop installation in /usr/local/Cellar/hadoop/$HADOOP_VERSION" ; exit 1; }

ln -f -s $DOTFILES_DIR/hadoop/libexec/etc/hadoop/core-site.xml /usr/local/Cellar/hadoop/$HADOOP_VERSION/libexec/etc/hadoop/core-site.xml
ln -f -s $DOTFILES_DIR/hadoop/libexec/etc/hadoop/hdfs-site.xml /usr/local/Cellar/hadoop/$HADOOP_VERSION/libexec/etc/hadoop/hdfs-site.xml
ln -f -s $DOTFILES_DIR/hadoop/libexec/etc/hadoop/mapred-site.xml /usr/local/Cellar/hadoop/$HADOOP_VERSION/libexec/etc/hadoop/mapred-site.xml

hdfs namenode -format

if ! grep -q "$DOTFILES_DIR/hadoop/.bash_aliases" "$HOME/.profile"; then
  echo "Appending to $HOME/.profile ..."
  echo "source \"$DOTFILES_DIR/hadoop/.bash_aliases\"" >> "$HOME/.profile"
fi

echo "Remember to enable remote login in System Preferences, Sharing."
echo "Run source \"$DOTFILES_DIR/hadoop/.bash_aliases\" now to get aliases."
echo "Run hstart to start Hadoop."
echo "Done."
