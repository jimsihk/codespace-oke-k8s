#!/bin/bash

set -eo pipefail

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

echo '****************'
echo "Testing oke-tunnel.sh:"
oke-tunnel.sh && exit_code=0 || exit_code=$?
echo "$exit_code"
if [ "$exit_code" -eq 4 ]; then
  echo "Passed"
else
  echo "Failed"
  exit "$exit_code"
fi

echo '****************'
echo "Testing init-local-oci.sh:"
init-local-oci.sh<<EOF

dummyuser
EOF
