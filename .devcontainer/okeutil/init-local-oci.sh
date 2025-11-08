#!/bin/bash

clear

################################
# Setup oci config
################################

echo "Enter region (e.g. eu-zurich-1), skip to keep unchanged or when init:"
read -r REGION
echo "Received: [$REGION]"

if [ -f ~/.oci/config ]
then
  if [ -n "$REGION" ]
  then
    # check if need to change region
    grep "region=$REGION" ~/.oci/config > /dev/null
    STATUS=$?
    if [ "$STATUS" -eq 1 ]
    then
      mv ~/.oci/config ~/.oci/config.bak
      sed "s/region=.*/region=$REGION/g" ~/.oci/config.bak > ~/.oci/config
      oci setup repair-file-permissions --file ~/.oci/config
      echo '*'" Updated ~/.oci/config"
    fi
  else
    echo '*'" Skipped updating ~/.oci/config "'*'
  fi
  
  # ensure key permission is correct
  OCICLIKEY=$(grep ^key_file ~/.oci/config | cut -d'=' -f2)
  oci setup repair-file-permissions --file "$OCICLIKEY"
else
  oci setup config
  echo '*********************'
  echo '*'" Create API key at OCI portal with the public key and then rerun the script "'*'
  echo '*********************'
  exit 0
fi

################################
# Setup kubeconfig
################################
echo "Update kubeconfig (y/N)?"
read -r UPDATE_KUBECONFIG
if [ "$UPDATE_KUBECONFIG" == 'Y' ]
then
  if [ -f ~/.kube/config ]
  then
    echo '*********************'
    echo '*'" Backup and remove ~/.kube/config to continue"
    echo '*********************'
    exit 1
  else
    echo "Enter cluster OCID:"
    read -r CLUSTER_ID
    
    REGION=$(grep ^region= ~/.oci/config | cut -d'=' -f2)
    
    echo '*'" Cluster: $CLUSTER_ID "'*'
    echo '*'" REGION: $REGION "'*'
    echo '*'" Creating kubeconfig... "'*'
    oci ce cluster create-kubeconfig --cluster-id "$CLUSTER_ID" --file ~/.kube/config --region "$REGION" --token-version 2.0.0  --kube-endpoint PRIVATE_ENDPOINT
    
    if [ -f ~/.kube/config ]
    then
      mv ~/.kube/config ~/.kube/config.bak
      sed 's/server:.*/server: https:\/\/127.0.0.1:6443/g' ~/.kube/config.bak > ~/.kube/config
      chmod 700 ~/.kube/config
    else
      exit 2
    fi
  fi
else
  echo '*'" Skipped updating kubeconfig "'*'
fi

################################
# Setup tunnel script
################################
if [ -f ~/.oci/custom-bastion-config ]
then
  echo '*********************'
  echo '*'" Backup and remove ~/.oci/custom-bastion-config to continue"
  echo '*********************'
  exit 3
else
  echo "Enter bastion OCID:"
  read -r BASTION_ID
  echo "Enter OKE private IP:"
  read -r TARGET_IP
  echo "BASTION_ID=$BASTION_ID" >> ~/.oci/custom-bastion-config
  echo "TARGET_IP=$TARGET_IP" >> ~/.oci/custom-bastion-config
  echo '*'" Created ~/.oci/custom-bastion-config "'*'
fi

# Generate SSH key for tunnel
TEMP_PRIVATE_KEY=~/.ssh/id_rsa_oci
ssh-keygen -b 2048 -t rsa -N '' -f "$TEMP_PRIVATE_KEY"

# covert ~ to absolute path
# shellcheck disable=SC2001
PRIVATE_KEY=$(echo "$TEMP_PRIVATE_KEY" | sed 's,~,'"$HOME"',g')

PUBLIC_KEY="$PRIVATE_KEY.pub"
echo "PRIVATE_KEY=$PRIVATE_KEY" >> ~/.oci/custom-bastion-config
echo "PUBLIC_KEY=$PUBLIC_KEY" >> ~/.oci/custom-bastion-config
echo '*'" Updated ~/.oci/custom-bastion-config "'*'