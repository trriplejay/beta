#!/bin/bash

export VERSION=""
export PUSH_TARGET="shipprod"
export RES_RELEASE="shippable-server-rel"
export RES_DOCKER_CREDS=docker-creds

docker_login() {
  creds_path="IN/$RES_DOCKER_CREDS/integration.env"
  if [ ! -e $creds_path ]; then
    echo "No credentials file found at location: $creds_path"
    return 1
  else
    echo "Extracting docker creds"
    . $creds_path
    echo "logging into Docker with username" $username
    docker login -u $username -p $password -e $email
    echo "Completed Docker login"
  fi
}

parse_version() {
  version_path="IN/$RES_RELEASE/release/release.json"
  if [ ! -e $version_path ]; then
    echo "No release.json file found at location: $version_path"
    return 1
  else
    echo "extracting release versionName from state file"
    VERSION=$(jq -r '.versionName' $version_path)
    echo "found version: $VERSION"
  fi
}

pull_image() {
  if [[ -z "$1" ]]; then
    return 0
  else
    image=$1
    echo "pulling image $image"
    sudo docker pull $image
  fi
}

tag_and_push() {
  if [[ -z "$1" ]]; then
    return 0
  else
    image=$1
    echo "processing image: $1"
    # assumes image will be tagged
    # as branch.build_number or service.branch.build_number
    full_name=$(echo $image | cut -d':' -f 1)
    tag=$(echo $image | cut -d':' -f 2)
    repo=$(echo $full_name | cut -d'/' -f 1)
    name=$(echo $full_name | cut -d'/' -f 2)
    svc_name=$(echo $tag | cut -d'.' -f 1)
    third_column=$(echo $tag | cut -d'.' -f 3)

    if [ -n "$third_column" ]; then
      new_tag="${svc_name}.$VERSION"
    else
      new_tag=$VERSION
    fi

    echo "tagging image $full_name as $PUSH_TARGET/$name:$new_tag"
    sudo docker tag -f $full_name:$tag $PUSH_TARGET/$name:$new_tag
    echo "pushing image $PUSH_TARGET/$name:$new_tag"
    echo "blah sudo docker push $PUSH_TARGET/$name:$new_tag"
  fi
}

main() {
  manifest_path="IN/$RES_RELEASE/release/manifests.json"
  if [ ! -e $manifest_path ]; then
    echo "No manifests.json file found at location: $manifest_path"
    return 1
  fi

  parse_version
  docker_login

  jq -r '.[] | .images | .[] | .image + ":" + .tag' $manifest_path |\
  while read image
  do
    pull_image $image
    tag_and_push $image
  done
}

main
