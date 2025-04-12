#!/bin/bash

set -eo pipefail

echo "Current user: $(whoami)"
echo "Current directory: $(pwd)"

echo '****************'
echo '~/.local/bin/:'
ls -la ~/.local/bin/
echo '****************'
echo '~/.local/opt/:'
ls -la ~/.local/opt/
echo '****************'
echo '~/.bashrc:'
cat ~/.bashrc
echo '****************'
echo 'env:'
env
echo '****************'

ls -l okectl
ls -l ohelm
ls -l oapply
ls -l odelete

echo "Installed versions:"
echo "- oci: $(oci --version)"
echo "- kubectl:" && kubectl version --client
echo "- helm: $(helm version)"
echo "- git: $(git --version)"
echo "- k9s:" && k9s version
echo "- kdash: $(kdash --version)"
