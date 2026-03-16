#!/bin/bash

################################
# Export OCI, kubeconfig and bastion configurations as base64-encoded values
# for storage as GitHub Codespace secrets.
#
# After running this script, copy the output values and store them as secrets:
#   GitHub -> Settings -> Secrets and variables -> Codespaces -> New secret
#
# The restore-from-secrets.sh script will automatically restore these
# configurations when the codespace starts.
################################

echo "========================"
echo "Export Configurations as GitHub Codespace Secrets"
echo "========================"
echo "Copy each value below and store as a Codespace secret:"
echo "  GitHub -> Settings -> Secrets and variables -> Codespaces -> New secret"
echo ""

# Helper function: encode a file as base64 and print with instructions
export_file() {
  local SECRET_NAME="$1"
  local FILE_PATH="$2"
  if [ -f "$FILE_PATH" ]
  then
    echo "Secret name : $SECRET_NAME"
    echo "Secret value:"
    base64 "$FILE_PATH" | tr -d '\n'
    echo ""
    echo "---"
    echo ""
  else
    echo "* Skipping $SECRET_NAME (file not found: $FILE_PATH)"
    echo ""
  fi
}

# OCI CLI config
export_file "OCI_CLI_CONFIG" ~/.oci/config

# OCI API private key (path referenced in OCI config)
if [ -f ~/.oci/config ]
then
  KEY_PATH_RAW=$(grep ^key_file ~/.oci/config | cut -d'=' -f2 | tr -d ' ')
  KEY_PATH="${KEY_PATH_RAW/#\~/$HOME}"
  export_file "OCI_CLI_PRIVATE_KEY" "$KEY_PATH"
else
  echo "* Skipping OCI_CLI_PRIVATE_KEY (no ~/.oci/config to determine key path)"
  echo ""
fi

# Kubeconfig
export_file "OCI_KUBECONFIG" ~/.kube/config

# Custom bastion configuration
export_file "OCI_BASTION_CONFIG" ~/.oci/custom-bastion-config

# SSH private key for bastion tunnel
export_file "OCI_SSH_PRIVATE_KEY" ~/.ssh/id_rsa_oci

# SSH public key for bastion tunnel
export_file "OCI_SSH_PUBLIC_KEY" ~/.ssh/id_rsa_oci.pub

echo "========================"
echo "Done. Set the above secrets in GitHub Codespace settings"
echo "and restart the codespace to auto-restore all configurations."
echo "========================"
