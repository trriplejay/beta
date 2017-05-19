#!/bin/bash -e

export CURR_JOB="deploy_rc"

export RES_SWARM="aws_rc_swarm"
export RES_PEM="aws_rc_pem"
export DEPLOY_VERSION="master"

export RES_SWARM_UP=$(echo $RES_SWARM | awk '{print toupper($0)}')
export RES_SWARM_PARAMS_STR=$RES_SWARM_UP"_PARAMS_RC"

export RES_PEM_UP=$(echo $RES_PEM | awk '{print toupper($0)}')
export RES_PEM_META=$(eval echo "$"$RES_PEM_UP"_META")
export RES_PEM_INT_STR=$RES_PEM_UP"_INTEGRATION_KEY"

set_context() {
  export BASTION_USER=$(eval echo "$"$RES_SWARM_PARAMS_STR"_BASTION_USER")
  export BASTION_IP=$(eval echo "$"$RES_SWARM_PARAMS_STR"_BASTION_IP")
  export SWARM_USER=$(eval echo "$"$RES_SWARM_PARAMS_STR"_SWARM_USER")
  export SWARM_IP=$(eval echo "$"$RES_SWARM_PARAMS_STR"_SWARM_IP")
  #export $PEM_KEY=$(RES_PEM_INT_STR)

  echo "CURR_JOB=$CURR_JOB"
  echo "RES_SWARM=$RES_SWARM"
  echo "DEPLOY_VERSION=$DEPLOY_VERSION"

  echo "RES_SWARM_UP=$RES_SWARM_UP"
  echo "RES_SWARM_PARAMS=$RES_SWARM_PARAMS"
  echo "RES_PEM_UP=$RES_PEM_UP"
  echo "RES_PEM_META=$RES_PEM_META"

  echo "BASTION_USER=$BASTION_USER"
  echo "BASTION_IP=$BASTION_IP"
  echo "SWARM_USER=$SWARM_USER"
  echo "SWARM_IP=$SWARM_IP"
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
  pushd $RES_PEM_META
  if [ ! -f "integration.json" ]; then
    echo "No credentials file found at location: $RES_PEM_META"
    return 1
  fi

  cat integration.json | jq -r '.key' > key.pem
  chmod 600 key.pem

  echo "Completed Extracting AWS PEM"
  echo "-----------------------------------"

  ssh-add key.pem
  echo "SSH key added successfully"
  echo "--------------------------------------"
  popd
}

pull_base_repo() {
  echo "Pull base-repo started"
  local PULL_CMD="git -C /home/ubuntu/base pull origin master"
  ssh -A $BASTION_USER@$BASTION_IP ssh $SWARM_USER@$SWARM_IP "$PULL_CMD"
  echo "Successfully pulled base-repo"
}

pull_admiral_repo() {
  echo "Pull admiral-repo started"
  local PULL_CMD="git -C /home/ubuntu/admiral pull origin master"
  ssh -A $BASTION_USER@$BASTION_IP ssh $SWARM_USER@$SWARM_IP "$PULL_CMD"
  echo "Successfully pulled admiral-repo"
}

deploy() {
  echo "Deploying the release $DEPLOY_VERSION to rc"
  echo "--------------------------------------"

  echo "SSH key file list"
  ssh-add -L

  local inspect_command="ip addr"
  echo "Executing inspect command: $inspect_command"
  ssh -A $BASTION_USER@$BASTION_IP ssh $SWARM_USER@$SWARM_IP "$inspect_command"
  echo "-------------------------------------="

  #local deploy_command="sudo /home/ubuntu/base/base.sh upgrade --version $DEPLOY_VERSION"
  local deploy_command="cd /home/ubuntu/admiral && sudo /home/ubuntu/admiral/admiral.sh upgrade"
  echo "Executing deploy command: $deploy_command"
  ssh -A $BASTION_USER@$BASTION_IP ssh $SWARM_USER@$SWARM_IP "$deploy_command"
  echo "-------------------------------------="

  echo "Successfully deployed release $DEPLOY_VERSION to rc env"
}

create_version() {
  echo "Creating a state file for" $CURR_JOB
  # create a state file so that next job can pick it up
  echo "versionName=$DEPLOY_VERSION" > "$JOB_STATE/$CURR_JOB.env" #adding version state
  echo "Completed creating a state file for" $CURR_JOB
}

main() {
  eval $(ssh-agent -s)
  set_context
  configure_node_creds
  #pull_base_repo
  pull_admiral_repo
  deploy
  create_version
}

main
