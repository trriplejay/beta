#!/bin/bash -e

export VERSION=""
export HUB_REGION=us-east-1
export HUB_TARGET=374168611083.dkr.ecr.$HUB_REGION.amazonaws.com
export RES_RELEASE=rel-alpha-server
export RES_ECR_INTEGRATION=shipbits-ecr
export RES_DOCKERHUB_INTEGRATION=shipimg-dockerhub

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

__tag_and_push() {
  if [[ -z "$1" ]]; then
    return 0
  fi

  image=$1
  echo "processing image: $1"
  full_name=$(echo $image | cut -d':' -f 1)

  echo "tag and push image $image as $full_name:$VERSION"
  sudo docker tag -f $image $full_name:$VERSION
  sudo docker push $full_name:$VERSION
}

tag_and_push_images_ecr() {
  echo "Pushing images to ECR"
  echo "----------------------------------------------"
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
    #TODO: not push if its mexec or runsh
    if [[ $image == *"mexec"* ]] || [[ $image == *"runsh"* ]]; then
      echo "Not pushing to ECR : $image"
    else
      __tag_and_push $image
    fi
  done
}

dockerhub_login() {
  echo "Logging in to Dockerhub"
  echo "----------------------------------------------"

  local creds_path="IN/$RES_DOCKERHUB_INTEGRATION/integration.env"
  cat $creds_path

  find -L "IN/$RES_DOCKERHUB_INTEGRATION"
  local login_username=test
  local login_pass=test
  local login_email=test
  echo "######### LOGIN: $login_username"
  echo "######### EMAIL: $login_email"
  #sudo docker login -u $login_username -p $login_pass -e $login_email
}

tag_and_push_images_dockerhub() {
  echo "Pushing images to Dockerhub"
  echo "----------------------------------------------"

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
    #TODO: push only if its runshsh or mexec
    __tag_and_push $image
    if [[ $image == *"mexec"* ]] || [[ $image == *"runsh"* ]]; then
      __tag_and_push $image
    else
      echo "Not pushing to DockerHub : $image"
    fi
  done

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
  tag_and_push_images_ecr $manifest_path
  dockerhub_login
  tag_and_push_images_dockerhub $manifest_path
}

main
