#!/bin/bash -e

export RES_RELEASE=rel-rc
export RC_INTEGRATION=aws-rc-pem
export RC_SWARM=aws-rc-swarm

export RC_BASTION_USER=$AWSRCSWARM_PARAMS_RC_BASTION_USER
export RC_BASTION_IP=$$AWSRCSWARM_PARAMS_RC_BASTION_IP
export RC_SWARM_USER=$AWSRCSWARM_PARAMS_RC_SWARM_USER
export RC_SWARM_IP=$AWSRCSWARM_PARAMS_RC_SWARM_IP
export KEY_FILE_PATH=""
export $VERSION=$RELRC_VERSIONNAME

parse_version() {
#  release_path="IN/$RES_RELEASE/release/release.json"
#  if [ ! -e $release_path ]; then
#    echo "No release.json file found at location: $release_path"
#    return 1
#  fi
#
#  echo "extracting release versionName from state file"
#  VERSION=$(jq -r '.versionName' $release_path)
  echo "found version: $VERSION"
}

load_node_info() {
#  echo "Loading node information"
#  local node_info=$(cat IN/$RC_SWARM/params)
#  export $node_info
#  #. $node_info

  echo "########### SWARM USER: $RC_SWARM_USER"
  echo "########### SWARM IP_ADDR: $RC_SWARM_IP"
  echo "########### BASTION USER: $RC_BASTION_USER"
  echo "########### BASTION IP_ADDR: $RC_BASTION_IP"
  echo "successfully loaded node information"
}

configure_node_creds() {
  echo "Extracting AWS PEM"
  echo "-----------------------------------"
  local creds_path="IN/$RC_INTEGRATION/integration.env"
  if [ ! -f $creds_path ]; then
    echo "No credentials file found at location: $creds_path"
    return 1
  fi

  export KEY_FILE_PATH="IN/$RC_INTEGRATION/key.pem"
  cat IN/$RC_INTEGRATION/integration.json  \
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


pull_base_repo() {
  echo "Pull base-repo started"
  local pull_base_command="git -C /home/ubuntu/base pull origin master"
  ssh -A $RC_BASTION_USER@$RC_BASTION_IP ssh $RC_SWARM_USER@$RC_SWARM_IP "$pull_base_command"
  echo "Successfully pulled base-repo"
}

deploy() {
  echo "Deploying the release $VERSION to RC"
  echo "--------------------------------------"


  echo "SSH key file list"
  ssh-add -L

  local inspect_command="ip addr"
  echo "Executing inspect command: $inspect_command"
  ssh -A $RC_BASTION_USER@$RC_BASTION_IP ssh $RC_SWARM_USER@$RC_SWARM_IP "$inspect_command"
  echo "-------------------------------------="

  #local deploy_command="ls -al"
  local deploy_command="sudo /home/ubuntu/base/base.sh --release $VERSION"
  echo "Executing deploy command: $deploy_command"
  ssh -A $RC_BASTION_USER@$RC_BASTION_IP ssh $RC_SWARM_USER@$RC_SWARM_IP "$deploy_command"
  echo "-------------------------------------="

  echo "Successfully deployed release $VERSION to RC env"
}

save_version() {
  echo "Saving release version to state"
  echo "--------------------------------------"

  local state_file_path=/build/state/rcVersion.txt
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
  pull_base_repo
  deploy
  save_version
}

main
