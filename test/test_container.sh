#!/bin/bash

set -eo pipefail

echo '*' "Started at $(date)"

echo '*' "Current user: $(whoami)"
echo '*' "Current directory: $(pwd)"
echo '*' "Shell: $SHELL"
echo '*' "Path: $PATH"

echo '****************'
echo '*' "Testing alias:"
which okectl
which ohelm

echo '****************'
echo '*' "Testing oci performance:"
OCI_START_NS=$(date +%s%N)
oci --version
OCI_END_NS=$(date +%s%N)
OCI_ELAPSED_MS=$(( (OCI_END_NS - OCI_START_NS) / 1000000 ))
echo '*' "oci --version took ${OCI_ELAPSED_MS}ms"
if [ "${OCI_ELAPSED_MS}" -ge 1000 ]; then
  echo '*' "Failed: oci --version response time ${OCI_ELAPSED_MS}ms >= 1000ms"
  exit 1
else
  echo '*' "Passed: oci --version response time ${OCI_ELAPSED_MS}ms < 1000ms"
fi

# echo '****************'
# echo '*' "Testing oci autocomplete:"
# ls -l /usr/local/bin/oci_autocomplete.sh
# cat ~/.bash_profile | grep 'oci_autocomplete.sh'
# complete -p oci

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
echo '*' "Downloading dummy key:"
curl -o dummy_private_key.pem https://raw.githubusercontent.com/cameritelabs/oci-emulator/refs/heads/main/assets/keys/private_key.pem
echo '*' "Starting init-local-oci.sh:"
init-local-oci.sh<<EOF


ocid1.user.oc1..testuser
ocid1.tenancy.oc1..testtenancy
sa-saopaulo-1
N
./dummy_private_key.pem
EOF

init-local-oci.sh<<EOF

N
ocid1.bastion.oc1..testbastion
0.0.0.0
EOF

echo '*' "Testing oci setup:"
oci --debug iam user get --user-id 'ocid1.user.oc1..testuser'
exit_code=$?
echo '*' "$exit_code"
if [ "$exit_code" -eq 0 ]; then
  echo '*' "Passed"
else
  echo '*' "Failed"
  exit "$exit_code"
fi

# TODO: test for create-kubeconfig, connect to bastion and k8s (as not supported by oci-emulator yet)
# init-local-oci.sh<<EOF
#
# Y
# ocid1.cluster.oc1..testcluster
# ocid1.bastion.oc1..testbastion
# 0.0.0.0
# EOF

echo '*' "Completed at $(date)"
