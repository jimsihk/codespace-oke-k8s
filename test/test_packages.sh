#!/bin/bash

set -eo pipefail

echo "Started at $(date)"

echo "Current user: $(whoami)"
echo "Current directory: $(pwd)"

echo '****************'
echo "OS: $(uname -a)"
echo "Installed versions:"
echo "- oci: $(oci --version)"
echo "- kubectl:" && kubectl version --client
echo "- helm: $(helm version)"
echo "- git: $(git --version)"
echo "- k9s:" && k9s version
echo "- kdash: $(kdash --version)"
echo "- python: $(python3 -V)"

echo "Completed at $(date)"