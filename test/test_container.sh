#!/bin/bash

set -eo pipefail

echo '*' "Started at $(date)"

echo '*' "Current user: $(whoami)"
echo '*' "Current directory: $(pwd)"

echo '****************'
echo '*' "Testing oke-tunnel.sh:"
oke-tunnel.sh && exit_code=0 || exit_code=$?
echo '*' "$exit_code"
if [ "$exit_code" -eq 4 ]; then
  echo '*' "Passed"
else
  echo '*' "Failed"
  exit "$exit_code"
fi

echo '****************'
echo '*' "Testing init-local-oci.sh:"
echo '*' "Downloading dummy key"
curl -o dummy_private_key.pem https://raw.githubusercontent.com/cameritelabs/oci-emulator/refs/heads/main/assets/keys/private_key.pem
export OCI_CLI_ENDPOINT=http://oci-emulator:12000
echo '*' "Starting init-local-oci.sh:"
init-local-oci.sh<<EOF


ocid1.user.oc1..testuser
ocid1.tenancy.oc1..testtenancy
sa-saopaulo-1
N
./dummy_private_key.pem
EOF

echo '*' "Testing oci setup:"
oci oci iam user get --user-id 'ocid1.user.oc1..testuser'

init-local-oci.sh<<EOF

Y
ocid1.cluster.oc1..aaaaaaaabbbbbbbbcccccccddddddddeeeeeeeefffffffggggggg
ocid1.bastion.oc1..aaaaaaaabbbbbbbbcccccccddddddddeeeeeeeefffffffggggggg
0.0.0.0
EOF

echo '* ~/.oci/config:'
cat ~/.oci/config

echo '* ~/.kube/config:'
cat ~/.kube/config

echo '* ~/.oci/custom-bastion-config:'
cat ~/.oci/custom-bastion-config

echo '*' "Completed at $(date)"