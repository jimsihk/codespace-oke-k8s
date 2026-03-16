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
time oci --debug -version
sleep 5

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

echo '****************'
echo '*' "Testing restore-from-secrets.sh:"

# Prepare dummy config content to encode as secrets
DUMMY_OCI_CONFIG="[DEFAULT]
user=ocid1.user.oc1..testuser
fingerprint=aa:bb:cc:dd:ee:ff
key_file=$HOME/.oci/oci_api_key.pem
tenancy=ocid1.tenancy.oc1..testtenancy
region=sa-saopaulo-1"

DUMMY_PRIVATE_KEY="-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA0Z3VS5JJcds3xHn/ygWep4PAtEsHAFxLNHsrBMkUjtest==
-----END RSA PRIVATE KEY-----"

DUMMY_KUBECONFIG="apiVersion: v1
kind: Config
clusters:
- cluster:
    server: https://127.0.0.1:6443
  name: test-cluster"

DUMMY_BASTION_CONFIG="BASTION_ID=ocid1.bastion.oc1..testbastion
TARGET_IP=10.0.0.1
PRIVATE_KEY=$HOME/.ssh/id_rsa_oci
PUBLIC_KEY=$HOME/.ssh/id_rsa_oci.pub"

DUMMY_SSH_KEY="-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA0Z3VS5JJcds3xHn/ygWep4PAtEsHtest==
-----END RSA PRIVATE KEY-----"

DUMMY_SSH_PUB_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDtest oracle@test"

# Remove existing configs set by previous test steps
rm -f ~/.oci/config ~/.oci/oci_api_key.pem ~/.kube/config ~/.oci/custom-bastion-config ~/.ssh/id_rsa_oci ~/.ssh/id_rsa_oci.pub

# Set base64-encoded env vars (simulating GitHub Codespace secrets)
export OCI_CLI_CONFIG
OCI_CLI_CONFIG=$(printf '%s' "$DUMMY_OCI_CONFIG" | base64 | tr -d '\n')
export OCI_CLI_PRIVATE_KEY
OCI_CLI_PRIVATE_KEY=$(printf '%s' "$DUMMY_PRIVATE_KEY" | base64 | tr -d '\n')
export OCI_KUBECONFIG
OCI_KUBECONFIG=$(printf '%s' "$DUMMY_KUBECONFIG" | base64 | tr -d '\n')
export OCI_BASTION_CONFIG
OCI_BASTION_CONFIG=$(printf '%s' "$DUMMY_BASTION_CONFIG" | base64 | tr -d '\n')
export OCI_SSH_PRIVATE_KEY
OCI_SSH_PRIVATE_KEY=$(printf '%s' "$DUMMY_SSH_KEY" | base64 | tr -d '\n')
export OCI_SSH_PUBLIC_KEY
OCI_SSH_PUBLIC_KEY=$(printf '%s' "$DUMMY_SSH_PUB_KEY" | base64 | tr -d '\n')

restore-from-secrets.sh
exit_code=$?
if [ "$exit_code" -ne 0 ]; then
  echo '*' "Failed: restore-from-secrets.sh exited with $exit_code"
  exit "$exit_code"
fi

# Verify all files were restored
VERIFY_FAILED=0
for config_file in ~/.oci/config ~/.oci/oci_api_key.pem ~/.kube/config ~/.oci/custom-bastion-config ~/.ssh/id_rsa_oci ~/.ssh/id_rsa_oci.pub
do
  if [ -f "$config_file" ]
  then
    echo '*' "Verified: $config_file exists"
  else
    echo '*' "Failed: $config_file is missing"
    VERIFY_FAILED=1
  fi
done
if [ "$VERIFY_FAILED" -eq 1 ]; then
  exit 1
fi
echo '*' "Passed"

echo '*' "Completed at $(date)"