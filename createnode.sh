#!/bin/bash

if [ ! -e /etc/sd-agent/config.cfg ]; then
  cd /tmp
  ./agent-install.sh -a $ACCOUNT_NAME -t $API_KEY -g $GROUPNAME || true
fi

if [ ! -e /etc/sd-agent/conf.d/docker.yml ]; then
  yum install -y sd-agent-docker
  cat > /etc/sd-agent/conf.d/docker.yaml << EOF
init_config:
  docker_root: /
instances:
  - url: "unix://var/run/docker.sock"
EOF
fi

if [ -e /var/run/sd-agent/sd-agent.pid ]; then
  rm /var/run/sd-agent/sd-agent.pid
fi 
