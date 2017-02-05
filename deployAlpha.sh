#!/bin/bash -e

export DEPLOY_ENV=ALPHA
# name of the resource in uppercase without -
export SWARM_CONN_RES=AWSALPHASWARM

export ALPHA_INTEGRATION=aws-alpha-pem

# name of the resource in uppercase without - and append PARAMS_ALPHA to it
# PARAMS cos the resource is of type
# this will give you all the ENVs that were setup in aws-alpha-swarm

# type of the resource above
export SWARM_CONN_RES_TYPE=$(eval echo "$"$SWARM_CONN_RES"_TYPE") | awk '{print toupper($0)}'
export SWARM_STRING=$SWARM_CONN_RES"_"$SWARM_CONN_RES_TYPE"_"$DEPLOY_ENV

# rel-alpha in uppercase without -
export RES_RELEASE=RELALPHA

export BASTION_USER=$(eval echo "$"$SWARM_STRING"_BASTION_USER")
export BASTION_IP=$(eval echo "$"$SWARM_STRING"_BASTION_IP")
export SWARM_USER=$(eval echo "$"$SWARM_STRING"_SWARM_USER")
export SWARM_IP=$(eval echo "$"$SWARM_STRING"_SWARM_IP")
export VERSION=$(eval echo "$"$RES_RELEASE"_VERSIONNAME")

export KEY_FILE_PATH=""

test_env_info() {
  echo "Testing all environment variables that are critical"

  echo "########### VERSION: $VERSION"
  echo "########### SWARM USER: $SWARM_USER"
  echo "########### SWARM IP_ADDR: $SWARM_IP"
  echo "########### BASTION USER: $BASTION_USER"
  echo "########### BASTION IP_ADDR: $BASTION_IP"

  if [ "$VERSION" == "" ]; then
    echo "VERSION not found"
    return 1
  fi

  if [ "$SWARM_USER" == "" ]; then
    echo "SWARM_USER not found"
    return 1
  fi

  if [ "$SWARM_IP" == "" ]; then
    echo "SWARM_IP not found"
    return 1
  fi

  if [ "$BASTION_USER" == "" ]; then
    echo "BASTION_USER not found"
    return 1
  fi

  if [ "$BASTION_IP" == "" ]; then
    echo "BASTION_IP not found"
    return 1
  fi

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

pull_base_repo() {
  echo "Pull base-repo started"
  local pull_base_command="git -C /home/ubuntu/base pull origin master"
  ssh -A $BASTION_USER@$BASTION_IP ssh $SWARM_USER@$SWARM_IP "$pull_base_command"
  echo "Successfully pulled base-repo"
}

deploy() {
  echo "Deploying the release $VERSION to alpha"
  echo "--------------------------------------"

  echo "SSH key file list"
  ssh-add -L

  local inspect_command="ip addr"
  echo "Executing inspect command: $inspect_command"
  ssh -A $BASTION_USER@$BASTION_IP ssh $SWARM_USER@$SWARM_IP "$inspect_command"
  echo "-------------------------------------="

  #local deploy_command="ls -al"
  local deploy_command="sudo /home/ubuntu/base/base.sh --release $VERSION"
  echo "Executing deploy command: $deploy_command"
  ssh -A $BASTION_USER@$BASTION_IP ssh $SWARM_USER@$SWARM_IP "$deploy_command"
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

  test_env_info
  #configure_node_creds
  #pull_base_repo
  #deploy
  #save_version
}

main
