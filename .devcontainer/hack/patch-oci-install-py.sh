#!/bin/bash

if [ -n "$1" ]
then
  INSTALL_SCRIPT="$1"
else
  INSTALL_SCRIPT="./install.py"
fi

if [ -f "$INSTALL_SCRIPT" ]
then
  echo "Patching ${INSTALL_SCRIPT} for oci-cli installation"
  sed -i 's/upgrade_pip_wheel/#upgrade_pip_wheel/g' "$INSTALL_SCRIPT"
  sed -i 's/def #upgrade_pip_wheel/def upgrade_pip_wheel/g' "$INSTALL_SCRIPT"
  sed -i "s|path_to_pip = os.path.join(install_dir, 'bin', 'pip')|path_to_pip = os.path.join('/usr/local/lib/hack', 'uv-pip')|g" "$INSTALL_SCRIPT"
else
  echo "Error! install.py not found!"
  exit 2
fi