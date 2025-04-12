#!/bin/bash

set -eo pipefail

ls -l ~/.local/bin/
ls -l ~/.local/opt/
cat ~/.bashrc

env

echo "Installed versions:"
echo "- oci: $(oci --version)"
echo "- kubectl:" && kubectl version --client
echo "- helm: $(helm version)"
echo "- git: $(git --version)"
echo "- k9s:" && k9s version
echo "- kdash: $(kdash --version)"
