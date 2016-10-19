#!/bin/bash -e

export VERSION=""
export RES_RELEASE=rel-alpha-server
#export ALPHA_INTEGRATION=aws-alpha-pem
export ALPHA_INTEGRATION=aws-alpha-pem
export ALPHA_SWARM=aws-alpha-swarm
export ALPHA_BASTION_USER=""
export ALPHA_BASTION_IP=""
export ALPHA_SWARM_USER=""
export ALPHA_SWARM_IP=""
export KEY_FILE_PATH=""

parse_version() {
  release_path="IN/$RES_RELEASE/release/release.json"
  if [ ! -e $release_path ]; then
    echo "No release.json file found at location: $release_path"
    return 1
  fi

  echo "extracting release versionName from state file"
  VERSION=$(jq -r '.versionName' $release_path)
  echo "found version: $VERSION"
}

load_node_info() {
  echo "Loading node information"
  local node_info=$(cat IN/$ALPHA_SWARM/params)
  export $node_info
  #. $node_info

  echo "########### SWARM USER: $ALPHA_SWARM_USER"
  echo "########### SWARM IP_ADDR: $ALPHA_SWARM_IP"
  echo "########### BASTION USER: $ALPHA_BASTION_USER"
  echo "########### BASTION IP_ADDR: $ALPHA_BASTION_IP"
  echo "successfully loaded node information"
}

configure_node_creds() {
  echo "Extracting AWS PEM"
  echo "-----------------------------------"
  local creds_path="IN/$ALPHA_INTEGRATION/integration.env"
  if [ ! -f $creds_path ]; then
    echo "No credentials file found at location: $creds_path"
    return 1
  fi

  export KEY_FILE_PATH="IN/$ALPHA_INTEGRATION/key.pem"
  cat IN/$ALPHA_INTEGRATION/integration.json  \
    | jq -r '.key' > $KEY_FILE_PATH
  chmod 600 $KEY_FILE_PATH

  ls -al $KEY_FILE_PATH
  echo "KEY file available at : $KEY_FILE_PATH"
  echo "Completed Extracting AWS PEM"
  echo "-----------------------------------"

  ssh-add $KEY_FILE_PATH
  echo "SSH key added successfully"
  echo "--------------------------------------"
}

deploy() {
  echo "Deploying the release $VERSION to alpha"
  echo "--------------------------------------"


  echo "SSH key file list"
  ssh-add -L

  local inspect_command="ip addr"
  echo "Executing inspect command: $inspect_command"
  ssh -A $ALPHA_BASTION_USER@$ALPHA_BASTION_IP ssh $ALPHA_SWARM_USER@$ALPHA_SWARM_IP $inspect_command
  echo "-------------------------------------="

  #local deploy_command="ls -al"
  local deploy_command="cd /home/ubuntu/base && sudo ./base.sh --release $VERSION"
  echo "Executing deploy command: $deploy_command"
  ssh -A $ALPHA_BASTION_USER@$ALPHA_BASTION_IP ssh $ALPHA_SWARM_USER@$ALPHA_SWARM_IP $deploy_command
  echo "-------------------------------------="

  echo "Successfully deployed release $VERSION to alpha env"
}

save_version() {
  echo "Saving release version to state"
  echo "--------------------------------------"

  local state_file_path=/build/state/alphaVersion.txt
  echo $VERSION > $state_file_path

  echo "Successfully dumped release version to state"
  cat $state_file_path
  echo "--------------------------------------"
}

main() {
  eval $(ssh-agent -s)
  manifest_path="IN/$RES_RELEASE/release/manifests.json"
  if [ ! -e $manifest_path ]; then
    echo "No manifests.json file found at location: $manifest_path"
    return 1
  fi

  parse_version
  load_node_info
  configure_node_creds
  deploy
  save_version
}

main
