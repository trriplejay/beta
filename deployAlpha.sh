#!/bin/bash -e

export VERSION=""
export RES_RELEASE=rel-alpha-server
#export ALPHA_INTEGRATION=aws-alpha-pem
export ALPHA_INTEGRATION=shippable-alpha-pem
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

  echo "########### USER: $ALPHA_SWARM_USER"
  echo "########### IP_ADDR: $ALPHA_SWARM_IP"
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
  cat $KEY_FILE_PATH

  echo "Completed Extracting AWS PEM"
  echo "-----------------------------------"

  ssh-add $KEY_FILE_PATH
}

deploy() {
  echo "Deploying the release $VERSION to alpha"
  # - run command `ssh <user>@<bastion> ssh <user>@<swarm_node> \
  #     cd base && sudo ./base.sh --release $VERSION

  echo "Successfully deployed release $VERSION to alpha env"
}

save_version() {
  echo "Saving release version to state"

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
  echo "------------------"
  env
  deploy
  save_version
}

main
