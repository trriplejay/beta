#!/bin/bash -e

export VERSION=""
export RES_RELEASE=rel-alpha-server
export ALPHA_INTEGRATION=aws-alpha-pem
export ALPHA_SWARM=aws-alpha-swarm

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
  echo "=========================="
  find IN/ -follow
  echo "=========================="
  cat IN/$ALPHA_SWARM/params
  cat IN/$ALPHA_SWARM/version.json
  #local node_info_path="IN/$ALPHA_SWARM/release/release.json"

}

configure_node_creds() {
  local creds_path="IN/$ALPHA_INTEGRATION/integration.env"
  if [ ! -f $creds_path ]; then
    echo "No credentials file found at location: $creds_path"
    return 1
  fi

  echo "Extracting node credentials"
  . $creds_path
  echo "configuring node credentials"
  local write_key=$(echo $key | tee IN/$ALPHA_INTEGRATION/key.pem)
  local update_mode=$(chmod -cR 600 IN/$ALPHA_INTEGRATION/key.pem)
  ssh-add IN/$ALPHA_INTEGRATION/key.pem
}

main() {
  eval $(ssh-agent)
  manifest_path="IN/$RES_RELEASE/release/manifests.json"
  if [ ! -e $manifest_path ]; then
    echo "No manifests.json file found at location: $manifest_path"
    return 1
  fi

  parse_version
  load_node_info
  echo "------------------"
  env
  configure_node_creds
  ##############
  #TODO: 
  # - get the alpha bastion node ip from env
  # - get the alpha bastion node user from env
  # - get the alpha bastion node key from IN
  # - get the alpha swarm node ip from env
  # - get the alpha swarm node user from env
  # - get the alpha swarm node key from IN
  # - run command `ssh-add <path_to_key>`
  # - run command `ssh <user>@<bastion> ssh <user>@<swarm_node> \
  #     cd base && sudo ./base.sh --release $VERSION
  #############
}

main
