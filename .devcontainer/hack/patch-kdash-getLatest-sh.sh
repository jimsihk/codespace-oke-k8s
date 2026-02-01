#!/bin/bash

if [ -n "$1" ]
then
  INSTALL_SCRIPT="$1"
else
  INSTALL_SCRIPT="./getLatest.sh"
fi

if [ -f "$INSTALL_SCRIPT" ]
then
  echo "Patching ${INSTALL_SCRIPT} for kdash installation"
  sed -i "s/SUFFIX='linux.tar.gz'/SUFFIX='linux-musl.tar.gz'/" "$INSTALL_SCRIPT"
  sed -i "s/-gnu.tar.gz/-musl.tar.gz/g" "$INSTALL_SCRIPT"

  if [ -n "$2" ]
  then
    echo "Set target kdash version to $2"
    sed -i "s|/releases/latest|/releases/tags/$2|g" "$INSTALL_SCRIPT"
  fi
else
  echo "Error! getLatest.sh not found!"
  exit 2
fi