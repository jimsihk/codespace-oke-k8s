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

which okectl
which ohelm
which oapply
which odelete

echo "Installed versions:"
echo "- oci: $(oci --version)"
echo "- kubectl:" && kubectl version --client
echo "- helm: $(helm version)"
echo "- git: $(git --version)"
echo "- k9s:" && k9s version
echo "- kdash: $(kdash --version)"
