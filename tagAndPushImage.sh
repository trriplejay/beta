#!/bin/bash -e

export CONTEXT=$1
export HUB_ORG=$2

export IMAGE_NAME=$CONTEXT
export CURR_JOB="tag_push_img_"$CONTEXT
export RES_IMAGE=$CONTEXT"_img"
export UP_TAG_NAME="master"
export RES_VER="rel_prod"

export RES_IMAGE_UP=$(echo $RES_IMAGE | awk '{print toupper($0)}')
export RES_IMAGE_META=$(eval echo "$"$RES_IMAGE_UP"_META")

export RES_VER_UP=$(echo $RES_VER | awk '{print toupper($0)}')
export RES_VER_NAME=$(eval echo "$"$RES_VER_UP"_VERSIONNAME")

set_context() {
  export PULL_IMG=$HUB_ORG/$IMAGE_NAME:$UP_TAG_NAME
  export PUSH_IMG=$HUB_ORG/$IMAGE_NAME:$RES_VER_NAME
  export PUSH_LAT_IMG=$HUB_ORG/$IMAGE_NAME:latest

  echo "CONTEXT=$CONTEXT"
  echo "CURR_JOB=$CURR_JOB"
  echo "IMAGE_NAME=$IMAGE_NAME"
  echo "RES_IMAGE=$RES_IMAGE"
  echo "RES_VER=$RES_VER"
  echo "HUB_ORG=$HUB_ORG"
  echo "UP_TAG_NAME=$UP_TAG_NAME"

  echo "RES_IMAGE_UP=$RES_IMAGE_UP"
  echo "RES_IMAGE_META=$RES_IMAGE_META"
  echo "RES_VER_UP=$RES_VER_UP"
  echo "RES_VER_NAME=$RES_VER_NAME"

  echo "PULL_IMG=$PULL_IMG"
  echo "PUSH_IMG=$PUSH_IMG"
}

pull_tag_image() {
  echo "Starting Docker tag and push for $IMAGE_NAME"
  sudo docker pull $PULL_IMG

  echo "Tagging $PUSH_IMG"
  sudo docker tag -f $PULL_IMG $PUSH_IMG

  echo "Tagging $PUSH_LAT_IMG"
  sudo docker tag -f $PULL_IMG $PUSH_LAT_IMG

  echo "Pushing $PUSH_IMG"
  sudo docker push $PUSH_IMG
  echo "Completed Docker tag & push for $PUSH_IMG"


  echo "Pushing $PUSH_LAT_IMG"
  sudo docker push $PUSH_LAT_IMG
  echo "Completed Docker tag & push for $PUSH_LAT_IMG"

  echo "Completed Docker tag and push for $IMAGE_NAME"
}

create_out_state() {
  echo "Creating a state file for $CURR_JOB"
  echo versionName=$RES_VER_NAME > "$JOB_STATE/$CURR_JOB.env"
}

main() {
  eval `ssh-agent -s`
  ps -eaf | grep ssh
  which ssh-agent

  set_context
  pull_tag_image
  create_out_state
}

main
