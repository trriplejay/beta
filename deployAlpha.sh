#!/bin/bash -e

export CURR_JOB="deploy_alpha"
export RES_REPO="config_repo"
export RES_PUSH="push_alpha"
export RES_SWARM="aws_alpha_swarm"
export RES_PEM="alpha_aws_pem"
export KEY_FILE_PATH=""

export RES_REPO_UP=$(echo $RES_REPO | awk '{print toupper($0)}')
export RES_REPO_STATE=$(eval echo "$"$RES_REPO_UP"_STATE")

export RES_PUSH_UP=$(echo $RES_PUSH | awk '{print toupper($0)}')
export RES_PUSH_VER_NAME=$(eval echo "$"$RES_PUSH_UP"_VERSIONNAME")

export RES_SWARM_UP=$(echo $RES_SWARM | awk '{print toupper($0)}')
export RES_SWARM_PARAMS=$RES_SWARM_UP"_PARAMS"

export RES_PEM_UP=$(echo $RES_PEM | awk '{print toupper($0)}')
export RES_PEM_META=$(eval echo "$"$RES_PEM_UP"_META")

set_context() {
  export BASTION_USER=$(eval echo "$"$RES_SWARM_PARAMS"_BASTION_USER")
  export BASTION_IP=$(eval echo "$"$RES_SWARM_PARAMS"_BASTION_IP")
  export SWARM_USER=$(eval echo "$"$RES_SWARM_PARAMS"_SWARM_USER")
  export SWARM_IP=$(eval echo "$"$RES_SWARM_PARAMS"_SWARM_IP")

  echo "CURR_JOB=$CURR_JOB"
  echo "RES_REPO=$RES_REPO"
  echo "RES_PUSH=$RES_PUSH"
  echo "RES_SWARM=$RES_SWARM"

  echo "RES_REPO_UP=$RES_REPO_UP"
  echo "RES_REPO_STATE=$RES_REPO_STATE"
  echo "RES_PUSH_UP=$RES_PUSH_UP"
  echo "RES_PUSH_VER_NAME=$RES_PUSH_VER_NAME"
  echo "RES_SWARM_UP=$RES_SWARM_UP"
  echo "RES_SWARM_PARAMS=$RES_SWARM_PARAMS"
  echo "RES_PEM_UP=$RES_PEM_UP"
  echo "RES_PEM_META=$RES_PEM_META"

  echo "BASTION_USER=$BASTION_USER"
  echo "BASTION_IP=$BASTION_IP"
  echo "SWARM_USER=$SWARM_USER"
  echo "SWARM_IP=$SWARM_IP"

  printenv
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
  local CREDS_PATH="$RES_PEM_META/integration.env"
  if [ ! -f $CREDS_PATH ]; then
    echo "No credentials file found at location: $creds_path"
    return 1
  fi

  export KEY_FILE_PATH="$RES_PEM_META/key.pem"
  cat $CREDS_PATH | jq -r '.key' > $KEY_FILE_PATH
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
  local PULL_CMD="git -C /home/ubuntu/base pull origin master"
  ssh -A $BASTION_USER@$BASTION_IP ssh $SWARM_USER@$SWARM_IP "$PULL_CMD"
  echo "Successfully pulled base-repo"
}

deploy() {
  echo "Deploying the release $RES_PUSH_VER_NAME to alpha"
  echo "--------------------------------------"

  echo "SSH key file list"
  ssh-add -L

  local inspect_command="ip addr"
  echo "Executing inspect command: $inspect_command"
  ssh -A $BASTION_USER@$BASTION_IP ssh $SWARM_USER@$SWARM_IP "$inspect_command"
  echo "-------------------------------------="

  #local deploy_command="ls -al"
  local deploy_command="sudo /home/ubuntu/base/base.sh --release $RES_PUSH_VER_NAME"
  echo "Executing deploy command: $deploy_command"
  ssh -A $BASTION_USER@$BASTION_IP ssh $SWARM_USER@$SWARM_IP "$deploy_command"
  echo "-------------------------------------="

  echo "Successfully deployed release $RES_PUSH_VER_NAME to alpha env"
}

create_version() {
  echo "Creating a state file for" $CURR_JOB
  # create a state file so that next job can pick it up
  echo "versionName=$RES_PUSH_VER_NAME" > /build/state/$CURR_JOB.env #adding version state
  echo "Completed creating a state file for" $CURR_JOB
}

main() {
  eval $(ssh-agent -s)
  set_context
  #configure_node_creds
  #pull_base_repo
  #deploy
  #create_version
}

main
