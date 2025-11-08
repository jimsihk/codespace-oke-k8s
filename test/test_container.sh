#!/bin/bash

set -eo pipefail

echo "Started at $(date)"

echo "Current user: $(whoami)"
echo "Current directory: $(pwd)"

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


ocid1.user.oc1..example456
ocid1.tenancy.oc1..aaaaaaaabbbbbbbbcccccccddddddddeeeeeeeefffffffggggggg
eu-zurich-1



N/A
N/A
EOF

init-local-oci.sh<<EOF

EOF

cat ~/.oci/config

echo "Completed at $(date)"