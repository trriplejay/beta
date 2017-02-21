#!/bin/bash -e

export HUB_ORG="374168611083.dkr.ecr.us-east-1.amazonaws.com"
export DOC_HUB_ORG="shipimg"

export CURR_JOB="push_rc"
export RES_REPO="config_repo"
export RES_RELEASE="rel-rc"
export RES_LAST_STG_PUSH="push_alpha"
export RES_BASE_REPO="base_repo"

export RES_REPO_UP=$(echo $RES_REPO | awk '{print toupper($0)}')
export RES_REPO_STATE=$(eval echo "$"$RES_REPO_UP"_STATE")

export RES_RELEASE_UP=$(echo ${RES_RELEASE//-/} | awk '{print toupper($0)}')
export RES_RELEASE_VER_NAME=$(eval echo "$"$RES_RELEASE_UP"_VERSIONNAME")

export RES_LAST_STG_PUSH_UP=$(echo $RES_LAST_STG_PUSH | awk '{print toupper($0)}')
export RES_LAST_STG_PUSH_VER_NAME=$(eval echo "$"$RES_LAST_STG_PUSH_UP"_VERSIONNAME")
export RES_LAST_STG_PUSH_META=$(eval echo "$"$RES_LAST_STG_PUSH_UP"_META")

export RES_BASE_REPO_UP=$(echo $RES_BASE_REPO | awk '{print toupper($0)}')
export RES_BASE_REPO_STATE=$(eval echo "$"$RES_BASE_REPO_UP"_STATE")

set_context() {
  export LAST_STG_LATEST_TAG=$RES_LAST_STG_PUSH_VER_NAME

  echo "CURR_JOB=$CURR_JOB"
  echo "RES_REPO=$RES_REPO"
  echo "RES_RELEASE=$RES_RELEASE"
  echo "RES_LAST_STG_PUSH=$RES_LAST_STG_PUSH"
  echo "RES_BASE_REPO=$RES_BASE_REPO"
  echo "HUB_ORG=$HUB_ORG"
  echo "DOC_HUB_ORG=$DOC_HUB_ORG"
  echo "LAST_STG_LATEST_TAG=$LAST_STG_LATEST_TAG"

  echo "RES_REPO_UP=$RES_REPO_UP"
  echo "RES_REPO_STATE=$RES_REPO_STATE"
  echo "RES_RELEASE_UP=$RES_RELEASE_UP"
  echo "RES_RELEASE_VER_NAME=$RES_RELEASE_VER_NAME"
  echo "RES_LAST_STG_PUSH_UP=$RES_LAST_STG_PUSH_UP"
  echo "RES_LAST_STG_PUSH_VER_NAME=$RES_LAST_STG_PUSH_VER_NAME"
  echo "RES_LAST_STG_PUSH_META=$RES_LAST_STG_PUSH_META"
  echo "RES_BASE_REPO_UP=$RES_BASE_REPO_UP"
  echo "RES_BASE_REPO_STATE=$RES_BASE_REPO_STATE"
}

get_image_list() {
  pushd $RES_LAST_STG_PUSH_META
  # This is set in the alpha job so that the same image list is maintained
  export IMAGE_NAMES=$(jq -r '.version.propertyBag.IMAGE_NAMES' version.json)
  echo "IMAGE_NAMES=$IMAGE_NAMES"
  popd
}

pull_images() {
  for IMAGE in $IMAGE_NAMES; do
    echo "Pulling image $HUB_ORG/$IMAGE:$LAST_STG_LATEST_TAG"
    sudo docker pull "$HUB_ORG/$IMAGE:$LAST_STG_LATEST_TAG"
  done
}

tag_and_push_images_ecr() {
  echo "Pushing images to ECR"
  echo "----------------------------------------------"

  for IMAGE in $IMAGE_NAMES; do
    echo "Tag and push image $HUB_ORG/$IMAGE:$LAST_STG_LATEST_TAG as $HUB_ORG/$IMAGE:$RES_RELEASE_VER_NAME"
    sudo docker tag -f $HUB_ORG/$IMAGE:$LAST_STG_LATEST_TAG $HUB_ORG/$IMAGE:$RES_RELEASE_VER_NAME
    sudo docker push $HUB_ORG/$IMAGE:$RES_RELEASE_VER_NAME
  done
}

tag_and_push_images_dockerhub() {
  echo "Pushing images to Dockerhub"
  echo "----------------------------------------------"
  for IMAGE in $IMAGE_NAMES; do
    if [[ $IMAGE == *"genexec"* ]]; then
      sudo docker tag -f $HUB_ORG/$IMAGE:$LAST_STG_LATEST_TAG $DOC_HUB_ORG/$IMAGE:$RES_RELEASE_VER_NAME
      sudo docker push $DOC_HUB_ORG/$IMAGE:$RES_RELEASE_VER_NAME
    else
      echo "Not pushing to DockerHub : $image"
    fi
  done
}

tag_push_base(){
  pushd $RES_BASE_REPO_STATE
  echo "pushing git tag $RES_RELEASE_VER_NAME to $RES_BASE_REPO at $LAST_STG_LATEST_TAG"
  git checkout $LAST_STG_LATEST_TAG
  git tag $RES_RELEASE_VER_NAME
  git push origin $RES_RELEASE_VER_NAME
  echo "completed pushing git tag $RES_RELEASE_VER_NAME to $RES_BASE_REPO"
  popd
}

create_version() {
  echo "Creating a state file for" $CURR_JOB
  # create a state file so that next job can pick it up
  echo "versionName=$RES_RELEASE_VER_NAME" > "$JOB_STATE/$CURR_JOB.env" #adding version state
  echo "IMAGE_NAMES=$IMAGE_NAMES" >> "$JOB_STATE/$CURR_JOB.env"
  echo "Completed creating a state file for" $CURR_JOB
}

main() {
  set_context
  get_image_list
  pull_images
  tag_and_push_images_ecr
  tag_and_push_images_dockerhub
  #tag_push_base
  create_version
}

main
