################################
# Utility to create a SSH tunnel in Oracle Cloud Bastion to access OKE nodes
#
# Note1:
# If receiving "Unable to negotiate with xxxxx port 22: no matching host key type found. Their offer: ssh-rsa", 
#   may need to update ~/.ssh/config to allow using ssh-rsa which is generally considered as not secure.
#   reference: https://stackoverflow.com/questions/69875520/unable-to-negotiate-with-40-74-28-9-port-22-no-matching-host-key-type-found-th
#   e.g. > cat ~/.ssh/config
#         Host host.bastion.eu-zurich-1.oci.oraclecloud.com
#             HostkeyAlgorithms +ssh-rsa
#             PubkeyAcceptedAlgorithms +ssh-rsa
# Note2:
# If changing to new region, ~/.oci/config may need to be updated as well
# ref: https://www.ateam-oracle.com/post/oracle-cloud-infrastructure-cli-scripting-how-to-quickly-override-the-default-configuration
# ref: https://www.ateam-oracle.com/post/using-oci-bastion-service-to-manage-private-oke-kubernetes-clusters
#
# Note3:
# oci cannot add --debug as the json parsing at step 1 will have issue
################################

clear

################################
# Step 0a: Clean up existing connection
################################
kill $(pgrep --full bastionsession)

################################
# Step 0b: Housekeep nohup.out
################################
# always output the nohup.out at /workspace for GitHub codespace
cd /workspaces
echo > nohup.out

if [ ! -f ~/.oci/custom-bastion-config ]
then
  echo '*'" ERROR! Missing ~/.oci/custom-bastion-config, run init-local-oci.sh first! "'*'
  exit 4
fi

################################
# Step 0c: Definitions
################################

# Change below for different bastion instance, connect to the Bastion that could connect to the nodes
BASTION_ID=$(grep BASTION_ID ~/.oci/custom-bastion-config | cut -d'=' -f2)

# Change below for using different key pair
PUBLIC_KEY=$(grep PUBLIC_KEY ~/.oci/custom-bastion-config | cut -d'=' -f2)
PRIVATE_KEY=$(grep PRIVATE_KEY ~/.oci/custom-bastion-config | cut -d'=' -f2)

# Replace with values of Kubernetes API private endpoint (or the IP of the nodes)
# Beware to have the bastion in the VCN
TARGET_IP=$(grep TARGET_IP ~/.oci/custom-bastion-config | cut -d'=' -f2)
TAEGET_PORT=6443

################################
# Step 0d: Fix key permission
################################
if [ -f "$PUBLIC_KEY" ]
then
  chmod 600 "$PUBLIC_KEY"
else
  echo "Missing $PUBLIC_KEY"
  exit 1
fi
if [ -f "$PRIVATE_KEY" ]
then
  chmod 600 "$PRIVATE_KEY"
else
  echo "Missing $PRIVATE_KEY"
  exit 1
fi

################################
# Step 1: Create Bastion session
################################
# Create Bastion session and forward rule
if [ -z "$1" ]
then
	echo '* '"Creating Bastion session with $BASTION_ID..."
	GETSESSIONCOMMAND="oci bastion session create-port-forwarding --bastion-id $BASTION_ID --display-name sdw-to-oke-tunnel --ssh-public-key-file $PUBLIC_KEY --key-type PUB --target-private-ip $TARGET_IP --target-port $TAEGET_PORT"
	RESULT1=$($GETSESSIONCOMMAND)
	echo "$RESULT1"

	SESSIONID=$(echo "$RESULT1" | python3 -c 'import json,sys;print(json.load(sys.stdin)["data"]["id"])')
else
	echo '* Skip creating Bastion session...'
	SESSIONID=$1
fi
echo '* '"Session ID: $SESSIONID"

# Checking for session readiness
echo "* Waiting for the session to be ready..."
sleep 10
while true
do
	RESULT2=$(oci bastion session get --session-id "$SESSIONID")

	SSHTEMPLATE=$(echo "$RESULT2" | python3 -c 'import json,sys;print(json.load(sys.stdin)["data"]["ssh-metadata"]["command"])')
	STATUS=$?

	if [ $STATUS -eq 0 ]
	then
	  echo '* Session is ready at '"$(echo "$RESULT2" | python3 -c 'import json,sys;print(json.load(sys.stdin)["data"]["time-created"])')"
	  break;
	else
	  echo '* Retrying in 5s...'
	  sleep 5
	fi
done

################################
# Step 2: Connect to tunnel
################################
# Wait before really connecting
sleep 5
SSHCOMMAND=$(echo "$SSHTEMPLATE" | sed 's/ssh/ssh -v/g' | sed "s/<privateKey>/$PRIVATE_KEY/g" | sed 's/<localPort>/6443/g')

echo '* Running: '"$SSHCOMMAND"

$SSHCOMMAND
