#!/bin/bash

set -eo pipefail

echo "Current user: $(whoami)"
echo "Current directory: $(pwd)"

echo '****************'
echo '~/.bashrc:'
cat ~/.bashrc

echo '****************'
echo 'env:'
env

echo '****************'
echo 'alias:'
alias

echo '****************'
echo "Installed versions:"
echo "- oci: $(oci --version)"
echo "- kubectl:" && kubectl version --client
echo "- helm: $(helm version)"
echo "- git: $(git --version)"
echo "- k9s:" && k9s version
echo "- kdash: $(kdash --version)"

echo '****************'
echo "Testing oke-tunnel.sh:"
if ! oke-tunnel.sh; then
  exit_code=$?
else
  exit_code=0
fi
if [ "$exit_code" -eq 4 ]; then
  echo "Passed"
else
  echo "Failed"
  exit "$exit_code"
fi
