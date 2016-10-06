#!/bin/bash -e

export VERSION=""
export HUB_REGION=us-east-1
export HUB_TARGET=374168611083.dkr.ecr.$HUB_REGION.amazonaws.com
export RES_RELEASE=rel-alpha-server
export RES_ECR_INTEGRATION=shipbits-ecr

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

configure_aws() {
  creds_path="IN/$RES_ECR_INTEGRATION/integration.env"
  if [ ! -e $creds_path ]; then
    echo "No credentials file found at location: $creds_path"
    return 1
  fi
  echo "Extracting ECR credentials"
  . $creds_path
  echo "Configuring aws cli with ECR credentials"
  aws configure set aws_access_key_id $aws_access_key_id
  aws configure set aws_secret_access_key $aws_secret_access_key
  aws configure set region $HUB_REGION
  echo "Successfully configured aws cli credentials"
}

ecr_login() {
  echo "logging in to Amazon ECR"
  docker_login_cmd=$(aws ecr get-login --region $HUB_REGION)
  $docker_login_cmd > /dev/null 2>&1
  echo "Amazon ECR login complete"
}

pull_images() {
  if [[ -z "$1" ]]; then
    echo "no manifest path provided"
    return 1
  fi

  manifest_path="$1"
  echo "pulling release manifest images"
  jq -r '.[] | .images | .[] | .image + ":" + .tag' $manifest_path |\
  while read image
  do
    __pull_image $image
  done
}

__pull_image() {
  if [[ -z "$1" ]]; then
    return 0
  fi

  image=$1
  echo "pulling image $image"
  sudo docker pull $image
}

tag_and_push_images() {
  if [[ -z "$1" ]]; then
    echo "no manifest path provided"
    return 1
  fi

  manifest_path="$1"
  echo "executing aws setup"

  echo "pushing release manifest images"
  jq -r '.[] | .images | .[] | .image + ":" + .tag' $manifest_path |\
  while read image
  do
    __tag_and_push $image
  done
}

__tag_and_push() {
  if [[ -z "$1" ]]; then
    return 0
  fi

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

  echo "tagging image $full_name as $HUB_TARGET/$name:$new_tag"
  sudo docker tag -f $full_name:$tag $HUB_TARGET/$name:$new_tag
  echo "pushing image $HUB_TARGET/$name:$new_tag"
  sudo docker push $HUB_TARGET/$name:$new_tag
}

main() {
  manifest_path="IN/$RES_RELEASE/release/manifests.json"
  if [ ! -e $manifest_path ]; then
    echo "No manifests.json file found at location: $manifest_path"
    return 1
  fi

  parse_version
  configure_aws
  ecr_login
  pull_images $manifest_path
  tag_and_push_images $manifest_path
}

main
