#!/bin/bash -e

export HUB_ORG="374168611083.dkr.ecr.us-east-1.amazonaws.com"
export DOC_HUB_ORG="shipimg"
export IMAGE_TAG="latest"

export CURR_JOB="push_alpha"
export RES_REPO="config_repo"
export RES_RELEASE="rel-alpha"
export RES_BASE_REPO="base_repo"

export RES_REPO_UP=$(echo $RES_REPO | awk '{print toupper($0)}')
export RES_REPO_STATE=$(eval echo "$"$RES_REPO_UP"_STATE")

export RES_RELEASE_UP=$(echo ${RES_RELEASE//-/} | awk '{print toupper($0)}')
export RES_RELEASE_VER_NAME=$(eval echo "$"$RES_RELEASE_UP"_VERSIONNAME")

export RES_BASE_REPO_UP=$(echo $RES_BASE_REPO | awk '{print toupper($0)}')
export RES_BASE_REPO_COMMIT=$(eval echo "$"$RES_BASE_REPO_UP"_COMMIT")
export RES_BASE_REPO_STATE=$(eval echo "$"$RES_BASE_REPO_UP"_STATE")

set_context() {
  echo "CURR_JOB=$CURR_JOB"
  echo "RES_RELEASE=$RES_RELEASE"
  echo "RES_BASE_REPO=$RES_BASE_REPO"
  echo "HUB_ORG=$HUB_ORG"
  echo "DOC_HUB_ORG=$DOC_HUB_ORG"
  echo "IMAGE_TAG=$IMAGE_TAG"

  echo "RES_RELEASE_UP=$RES_RELEASE_UP"
  echo "RES_RELEASE_VER_NAME=$RES_RELEASE_VER_NAME"
  echo "RES_BASE_REPO_UP=$RES_BASE_REPO_UP"
  echo "RES_BASE_REPO_COMMIT=$RES_BASE_REPO_COMMIT"
  echo "RES_BASE_REPO_STATE=$RES_BASE_REPO_STATE"
}

get_image_list() {
  pushd $RES_REPO_STATE
  export IMAGE_NAMES=$(cat shippableImages.txt)
  export IMAGE_NAMES_SPACED=$(eval echo $(tr '\n' ' ' < shippableImages.txt))

  echo "IMAGE_NAMES=$IMAGE_NAMES"
  echo "IMAGE_NAMES_SPACED=$IMAGE_NAMES_SPACED"
  popd
}

pull_images() {
  for IMAGE in $IMAGE_NAMES; do
    echo "Pulling image $HUB_ORG/$IMAGE:$IMAGE_TAG"
    sudo docker pull "$HUB_ORG/$IMAGE:$IMAGE_TAG"
  done
}

tag_and_push_images_ecr() {
  echo "Pushing images to ECR"
  echo "----------------------------------------------"

  for IMAGE in $IMAGE_NAMES; do
    echo "Tag and push image $HUB_ORG/$IMAGE:$IMAGE_TAG as $HUB_ORG/$IMAGE:$RES_RELEASE_VER_NAME"
    sudo docker tag -f $HUB_ORG/$IMAGE:$IMAGE_TAG $HUB_ORG/$IMAGE:$RES_RELEASE_VER_NAME
    sudo docker push $HUB_ORG/$IMAGE:$RES_RELEASE_VER_NAME
  done
}

tag_and_push_images_dockerhub() {
  echo "Pushing images to Dockerhub"
  echo "----------------------------------------------"
  for IMAGE in $IMAGE_NAMES; do
    if [[ $IMAGE == *"genexec"* ]]; then
      sudo docker tag -f $HUB_ORG/$IMAGE:$IMAGE_TAG $DOC_HUB_ORG/$IMAGE:$RES_RELEASE_VER_NAME
      sudo docker push $DOC_HUB_ORG/$IMAGE:$RES_RELEASE_VER_NAME
    else
      echo "Not pushing to DockerHub : $image"
    fi
  done
}

tag_push_base(){
  pushd $RES_BASE_REPO_STATE
  echo "pushing git tag $RES_RELEASE_VER_NAME to $RES_BASE_REPO at $RES_BASE_REPO_COMMIT"
  git checkout $RES_BASE_REPO_COMMIT
  git tag $RES_RELEASE_VER_NAME
  git push origin $RES_RELEASE_VER_NAME
  echo "completed pushing git tag $RES_RELEASE_VER_NAME to $RES_BASE_REPO"
  popd
}

create_version() {
  echo "Creating a state file for" $CURR_JOB
  # create a state file so that next job can pick it up
  echo "versionName=$RES_RELEASE_VER_NAME" > /build/state/$CURR_JOB.env #adding version state
  echo "IMAGE_NAMES=$IMAGE_NAMES_SPACED" >> /build/state/$CURR_JOB.env
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
