#!/usr/bin/env sh

# check if connection to k8s API is ready
kubectl get nodes > /dev/null 2>&1
RESULT=$?
if [ $RESULT -eq 1 ]
then
    echo "Initiating connection to OKE cluster at $(date)..."
    TUNNELSCRIPT="/opt/okeutil/oke-tunnel.sh"
    if [ ! -f "$TUNNELSCRIPT" ]
    then
        echo '* ERROR! Missing '"$TUNNELSCRIPT"
        exit 3
    fi
    nohup "$TUNNELSCRIPT" 2>&1 &
    while true
    do
      kubectl get nodes > /dev/null 2>&1
      STATUS=$?
    	if [ $STATUS -eq 0 ]
    	then
    	  echo '*'" Connection is ready at $(date)"
    	  break;
    	else
    	  echo '* Retrying in 5s...'
    	  sleep 5
    	fi
    done
else
  # no news is good news
  exit 0
fi