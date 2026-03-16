#!/bin/bash

################################
# Restore OCI, kubeconfig and bastion configurations
# from GitHub Codespace secrets (base64-encoded environment variables).
#
# Expected secrets (set in GitHub -> Settings -> Secrets and variables -> Codespaces):
#   OCI_CLI_CONFIG       - base64 encoded ~/.oci/config
#   OCI_CLI_PRIVATE_KEY  - base64 encoded OCI API private key (.pem)
#   OCI_KUBECONFIG       - base64 encoded ~/.kube/config
#   OCI_BASTION_CONFIG   - base64 encoded ~/.oci/custom-bastion-config
#   OCI_SSH_PRIVATE_KEY  - base64 encoded ~/.ssh/id_rsa_oci
#   OCI_SSH_PUBLIC_KEY   - base64 encoded ~/.ssh/id_rsa_oci.pub
#
# Run export-config.sh to generate the base64 values for the above secrets.
################################

RESTORED=0

# Ensure required directories exist
mkdir -p ~/.oci ~/.kube ~/.ssh

# Restore OCI CLI config
if [ -n "$OCI_CLI_CONFIG" ]
then
  echo '* Restoring OCI CLI config (~/.oci/config)...'
  echo "$OCI_CLI_CONFIG" | base64 -d > ~/.oci/config
  oci setup repair-file-permissions --file ~/.oci/config 2>/dev/null || chmod 600 ~/.oci/config
  RESTORED=$((RESTORED + 1))
fi

# Restore OCI API private key
if [ -n "$OCI_CLI_PRIVATE_KEY" ]
then
  # Determine key path from config, or use default
  KEY_PATH=""
  if [ -f ~/.oci/config ]
  then
    KEY_PATH_RAW=$(grep ^key_file ~/.oci/config | cut -d'=' -f2 | tr -d ' ')
    # Expand ~ to $HOME in case the path uses tilde notation
    KEY_PATH="${KEY_PATH_RAW/#\~/$HOME}"
  fi
  if [ -z "$KEY_PATH" ]
  then
    KEY_PATH="$HOME/.oci/oci_api_key.pem"
  fi
  echo '* Restoring OCI API private key ('"$KEY_PATH"')...'
  mkdir -p "$(dirname "$KEY_PATH")"
  echo "$OCI_CLI_PRIVATE_KEY" | base64 -d > "$KEY_PATH"
  oci setup repair-file-permissions --file "$KEY_PATH" 2>/dev/null || chmod 600 "$KEY_PATH"
  RESTORED=$((RESTORED + 1))
fi

# Restore kubeconfig
if [ -n "$OCI_KUBECONFIG" ]
then
  echo '* Restoring kubeconfig (~/.kube/config)...'
  echo "$OCI_KUBECONFIG" | base64 -d > ~/.kube/config
  chmod 600 ~/.kube/config
  RESTORED=$((RESTORED + 1))
fi

# Restore custom bastion configuration
if [ -n "$OCI_BASTION_CONFIG" ]
then
  echo '* Restoring bastion config (~/.oci/custom-bastion-config)...'
  echo "$OCI_BASTION_CONFIG" | base64 -d > ~/.oci/custom-bastion-config
  chmod 600 ~/.oci/custom-bastion-config
  RESTORED=$((RESTORED + 1))
fi

# Restore SSH private key used for bastion tunnel
if [ -n "$OCI_SSH_PRIVATE_KEY" ]
then
  echo '* Restoring SSH private key (~/.ssh/id_rsa_oci)...'
  echo "$OCI_SSH_PRIVATE_KEY" | base64 -d > ~/.ssh/id_rsa_oci
  chmod 600 ~/.ssh/id_rsa_oci
  RESTORED=$((RESTORED + 1))
fi

# Restore SSH public key used for bastion tunnel
if [ -n "$OCI_SSH_PUBLIC_KEY" ]
then
  echo '* Restoring SSH public key (~/.ssh/id_rsa_oci.pub)...'
  echo "$OCI_SSH_PUBLIC_KEY" | base64 -d > ~/.ssh/id_rsa_oci.pub
  chmod 644 ~/.ssh/id_rsa_oci.pub
  RESTORED=$((RESTORED + 1))
fi

if [ "$RESTORED" -gt 0 ]
then
  echo "* Restored $RESTORED configuration(s) from secrets"
fi
