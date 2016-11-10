#!/bin/bash -e

export VERSION=""
export HUB_REGION=us-east-1
export DOCKERHUB_TARGET=shipimg
export RES_RELEASE=rel-rc-server
export RES_ECR_INTEGRATION=shipbits-ecr
export RES_DOCKERHUB_INTEGRATION=shipimg-dockerhub
export RES_ALPHA_PUSH=push-alpha

parse_alpha_version() {
  pushd ./IN/$RES_ALPHA_PUSH/runSh
  . alpha_ver.txt #to set ALPHA_VER
  echo "Most recent alpha version is : $ALPHA_VER"
  popd
}

parse_version() {
  release_path="IN/$RES_RELEASE/release/release.json"
  if [ ! -e $release_path ]; then
    echo "No release.json file found at location: $release_path"
    return 1
  fi

  echo "extracting release versionName from state file"
  VERSION=$(jq -r '.versionName' $release_path)
  echo "found version: $VERSION"
  echo "RC_VER=$VERSION" > /build/state/rc_ver.txt #adding version state
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
  full_name=$(echo $image | cut -d':' -f 1)
  echo "pulling image $full_name:$ALPHA_VER"
  sudo docker pull $image
}

__tag_and_push_ecr() {
  if [[ -z "$1" ]]; then
    return 0
  fi

  image=$1
  echo "processing image: $1"
  full_name=$(echo $image | cut -d':' -f 1)

  echo "tag and push image $full_name:$ALPHA_VER as $full_name:$VERSION"
  sudo docker tag -f $full_name:$ALPHA_VER $full_name:$VERSION
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

  echo "pushing release manifest images to ECR"
  jq -r '.[] | .images | .[] | .image + ":" + .tag' $manifest_path |\
  while read image
  do
    __tag_and_push_ecr $image
  done
}

dockerhub_login() {
  echo "Logging in to Dockerhub"
  echo "----------------------------------------------"

  local creds_path="IN/$RES_DOCKERHUB_INTEGRATION/integration.json"

  find -L "IN/$RES_DOCKERHUB_INTEGRATION"
  local username=$(cat $creds_path \
    | jq -r '.username')
  local password=$(cat $creds_path \
    | jq -r '.password')
  local email=$(cat $creds_path \
    | jq -r '.email')
  echo "######### LOGIN: $username"
  echo "######### EMAIL: $email"
  sudo docker login -u $username -p $password -e $email
}

__tag_and_push_dockerhub() {
  if [[ -z "$1" ]]; then
    return 0
  fi

  image=$1
  echo "processing image: $1"
  full_name=$(echo $image | cut -d ':' -f 1)
  repo_name=$(echo $full_name | cut -d '/' -f 2)

  local push_name="$DOCKERHUB_TARGET/$repo_name:$VERSION"
  echo "tag and push image $full_name:$ALPHA_VER as $push_name"
  sudo docker tag -f $full_name:$ALPHA_VER $push_name
  sudo docker push $push_name
}

tag_and_push_images_dockerhub() {
  echo "Pushing images to Dockerhub"
  echo "----------------------------------------------"

  if [[ -z "$1" ]]; then
    echo "no manifest path provided"
    return 1
  fi

  manifest_path="$1"

  echo "pushing release manifest images to dockerhub"
  jq -r '.[] | .images | .[] | .image + ":" + .tag' $manifest_path |\
  while read image
  do
    if [[ $image == *"mexec"* ]] || [[ $image == *"runsh"* ]]; then
      __tag_and_push_dockerhub $image
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

  parse_alpha_version
  parse_version
  configure_aws
  ecr_login
  pull_images $manifest_path
  tag_and_push_images_ecr $manifest_path
  dockerhub_login
  tag_and_push_images_dockerhub $manifest_path
}

main
