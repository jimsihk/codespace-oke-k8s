#!/bin/bash

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

    # Always output the nohup.out at repo checkout path for GitHub codespace
    WKDIR="$HOME"
    if [ -n "$GITHUB_REPOSITORY" ]
    then
      WKDIR=/workspaces/$(basename "$GITHUB_REPOSITORY")
    fi
    echo "nohup.out will be in $WKDIR..."
    cd "$WKDIR"
    # Clear previous log file
    echo > nohup.out

    TUNNEL_MAX_RESTARTS=3
    TUNNEL_RESTARTS=0
    nohup "$TUNNELSCRIPT" 2>&1 &
    TUNNEL_PID=$!
    while true
    do
      kubectl get nodes > /dev/null 2>&1
      STATUS=$?
      if [ $STATUS -eq 0 ]
      then
        echo '*'" Connection is ready at $(date)"
        break;
      elif ! kill -0 "$TUNNEL_PID" 2>/dev/null
      then
        TUNNEL_RESTARTS=$((TUNNEL_RESTARTS + 1))
        if [ $TUNNEL_RESTARTS -gt $TUNNEL_MAX_RESTARTS ]
        then
          echo "* ERROR! Tunnel failed after $TUNNEL_MAX_RESTARTS restart(s)"
          exit 1
        fi
        echo "* Tunnel process ended, restarting (attempt $TUNNEL_RESTARTS of $TUNNEL_MAX_RESTARTS)..."
        nohup "$TUNNELSCRIPT" 2>&1 &
        TUNNEL_PID=$!
      else
        echo '* Retrying in 5s...'
        sleep 5
      fi
    done
else
  # no news is good news
  exit 0
fi