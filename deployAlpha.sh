#!/bin/bash -e

export DEPLOY_ENV=ALPHA

# uppercase name of the resource in uppercase without -
export SWARM_CONN_RES="AWS"$DEPLOY_ENV"SWARM"

# uppercase type of the resource above
export SWARM_CONN_RES_TYPE=$(eval echo "$"$SWARM_CONN_RES"_TYPE" | awk '{print toupper($0)}')

# path to find the SWARM_CONN config
export SWARM_STRING=$SWARM_CONN_RES"_"$SWARM_CONN_RES_TYPE"_"$DEPLOY_ENV

# now set all other values
export BASTION_USER=$(eval echo "$"$SWARM_STRING"_BASTION_USER")
export BASTION_IP=$(eval echo "$"$SWARM_STRING"_BASTION_IP")
export SWARM_USER=$(eval echo "$"$SWARM_STRING"_SWARM_USER")
export SWARM_IP=$(eval echo "$"$SWARM_STRING"_SWARM_IP")

# uppercase name of release job without -
export RELEASE_RES="REL"$DEPLOY_ENV
export VERSION=$(eval echo "$"$RELEASE_RES"_VERSIONNAME")

# uppercase name of integration resource without -
export INTEGRATION_RES="aws-deploy-pem"

#export INTEGRATION_RES="AWS"$DEPLOY_ENV"PEM"
#
## uppercase type of the resource above
#export INTEGRATION_RES_TYPE=$(eval echo "$"$INTEGRATION_RES"_TYPE" | awk '{print toupper($0)}')
#
## path to find the INTEGRATION key
#export PEM_KEY=$(eval echo "$"$INTEGRATION_RES"_"$INTEGRATION_RES_TYPE"_KEY")

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

#  if [ "$PEM_KEY" == "" ]; then
#    echo "PEM_KEY not found"
#    return 1
#  fi

  echo "successfully loaded node information"
}

configure_node_creds() {

#  echo $PEM_KEY > /tmp/key.pem
#  chmod 600 /tmp/key.pem
#  echo "KEY file available at : /tmp/key.pem"
#  echo "Completed Extracting AWS PEM"
#  echo "-----------------------------------"
#  ssh-add /tmp/key.pem
#  echo "SSH key added successfully"
#  echo "--------------------------------------"

  echo "Extracting AWS PEM"
  echo "-----------------------------------"
  local creds_path="IN/$INTEGRATION_RES/integration.env"
  if [ ! -f $creds_path ]; then
    echo "No credentials file found at location: $creds_path"
    return 1
  fi

  export KEY_FILE_PATH="IN/$INTEGRATION_RES/key.pem"
  cat IN/$INTEGRATION_RES/integration.json  \
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
  configure_node_creds
  #pull_base_repo
  #deploy
  #save_version
}

main
