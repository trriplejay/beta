#!/bin/bash -e

export IMAGE="$1"
export HUB_ORG="$2"
export RELEASE="$3"

export IMAGE_RESOURCE="$IMAGE"_img
export IMAGE_RESOURCE_UPPERCASE=$(echo "$IMAGE_RESOURCE" | awk '{print toupper($0)}')
export IMAGE_RESOURCE_VERSION_NUMBER=$(eval echo "$"$IMAGE_RESOURCE_UPPERCASE"_VERSIONNUMBER")

export RELEASE_UPPERCASE=$(echo $RELEASE | awk '{print toupper($0)}')
export RELEASE_VERSION_NAME=$(eval echo "$"$RELEASE_UPPERCASE"_VERSIONNAME")

export TAG_TO_PULL="master"
export TAG_TO_PUSH="$RELEASE_VERSION_NAME-patch.$IMAGE_RESOURCE_VERSION_NUMBER"
export IMAGE_TO_PULL="$HUB_ORG/$IMAGE:$TAG_TO_PULL"
export IMAGE_TO_PUSH="$HUB_ORG/$IMAGE:$TAG_TO_PUSH"

show_context() {
  echo "IMAGE=$IMAGE"
  echo "HUB_ORG=$HUB_ORG"
  echo "RELEASE=$RELEASE"

  echo "IMAGE_RESOURCE=$IMAGE_RESOURCE"
  echo "IMAGE_RESOURCE_UPPERCASE=$IMAGE_RESOURCE_UPPERCASE"
  echo "IMAGE_RESOURCE_VERSION_NUMBER=$IMAGE_RESOURCE_VERSION_NUMBER"

  echo "RELEASE_UPPERCASE=$RELEASE_UPPERCASE"
  echo "RELEASE_VERSION_NAME=$RELEASE_VERSION_NAME"

  echo "TAG_TO_PULL=$TAG_TO_PULL"
  echo "TAG_TO_PUSH=$TAG_TO_PUSH"
  echo "IMAGE_TO_PULL"="$IMAGE_TO_PULL"
  echo "IMAGE_TO_PUSH"="$IMAGE_TO_PUSH"
}

pull_image() {
  echo "Pulling $IMAGE_TO_PULL..."
  docker pull $IMAGE_TO_PULL
}

tag_image() {
  echo "Tagging $IMAGE_TO_PUSH..."
  docker tag $IMAGE_TO_PULL $IMAGE_TO_PUSH
}

push_image() {
  echo "Pushing $IMAGE_TO_PUSH..."
  docker push $IMAGE_TO_PUSH
}

main() {
  show_context
  pull_image
  tag_image
  push_image
}

main
