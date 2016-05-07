#!/bin/bash

if [ ! -e /etc/sd-agent/config.cfg ]; then
  cd /tmp
  ./agent-install.sh -a $ACCOUNT_NAME -t $API_KEY -g $GROUPNAME || true
fi

if [ -e /var/run/sd-agent/sd-agent.pid ]; then
  rm /var/run/sd-agent/sd-agent.pid
fi 
