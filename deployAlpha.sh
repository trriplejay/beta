#!/bin/bash -e

export VERSION=""
export RES_RELEASE=rel-alpha-server

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
main() {
  manifest_path="IN/$RES_RELEASE/release/manifests.json"
  if [ ! -e $manifest_path ]; then
    echo "No manifests.json file found at location: $manifest_path"
    return 1
  fi

  parse_version
  echo "------------------"
  env
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
