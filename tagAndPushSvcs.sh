#!/bin/bash -e

add_ssh_key() {
 pushd "$RES_GH_SSH_META"
 echo "Extracting AWS PEM"
 echo "-----------------------------------"
 cat "integration.json"  | jq -r '.privateKey' > gh_ssh.key
 chmod 600 gh_ssh.key
 ssh-add gh_ssh.key
 echo "Completed Extracting AWS PEM"
 echo "-----------------------------------"
 popd
}

pull_tag_image() {
  echo "Starting Docker tag and push for $IMAGE_NAME"
  sudo docker pull $PULL_IMG

  echo "Tagging $PUSH_IMG"
  sudo docker tag $PULL_IMG $PUSH_IMG

  echo "Tagging $PUSH_LAT_IMG"
  sudo docker tag $PULL_IMG $PUSH_LAT_IMG

  echo "Pushing $PUSH_IMG"
  sudo docker push $PUSH_IMG
  echo "Completed Docker tag & push for $PUSH_IMG"

  echo "Pushing $PUSH_LAT_IMG"
  sudo docker push $PUSH_LAT_IMG
  echo "Completed Docker tag & push for $PUSH_LAT_IMG"

  echo "Completed Docker tag and push for $IMAGE_NAME"
}

tag_push_repo(){
  pushd $RES_REPO_STATE

  git remote add up $SSH_PATH
  git remote -v
  git checkout master

  git pull --tags
  git checkout $IMG_REPO_COMMIT_SHA

  if git tag -d $RES_VER_NAME; then
    git push --delete up $RES_VER_NAME
  fi

  git tag $RES_VER_NAME
  git push up $RES_VER_NAME

  popd
}

create_out_state() {
  echo "Creating a state file for $CURR_JOB"
  echo versionName=$RES_VER_NAME > "$JOB_STATE/$CURR_JOB.env"
  echo IMG_REPO_COMMIT_SHA=$IMG_REPO_COMMIT_SHA >> "$JOB_STATE/$CURR_JOB.env"
}

main() {
  eval `ssh-agent -s`
  ps -eaf | grep ssh
  which ssh-agent

  export CURR_JOB="tag_push_services"
  export UP_TAG_NAME="master"
  export RES_VER="rel_prod"
  export RES_VER_NAME=$(shipctl get_resource_version_name $RES_VER)
  export RES_GH_SSH="avi_gh_ssh"
  export RES_GH_SSH_META=$(shipctl get_resource_meta $RES_GH_SSH)

  export RES_CONF_REPO="config_repo"
  export RES_CONF_REPO_STATE=$(shipctl get_resource_state $RES_CONF_REPO)

  pushd $RES_CONF_REPO_STATE

  echo ""
  echo "============= Begin State for $CURR_JOB======================"
  echo "CURR_JOB=$CURR_JOB"
  echo "RES_VER=$RES_VER"
  echo "UP_TAG_NAME=$UP_TAG_NAME"
  echo "RES_GH_SSH_META=$RES_GH_SSH_META"
  echo "============= End State for $CONTEXT======================"
  echo ""

  add_ssh_key

  echo "Creating a state file for $CURR_JOB"
  shipctl post_resource_state $CURR_JOB versionName $RES_VER_NAME

  for c in `cat coreServices.txt`; do
    export CONTEXT=$c
    export HUB_ORG=drydock
    export GH_ORG=dry-dock

    export SSH_PATH="git@github.com:$GH_ORG/$CONTEXT.git"

    export IMAGE_NAME=$CONTEXT
    export RES_IMAGE=$CONTEXT"_img"
    export PULL_IMG=$HUB_ORG/$IMAGE_NAME:$UP_TAG_NAME
    export PUSH_IMG=$HUB_ORG/$IMAGE_NAME:$RES_VER_NAME
    export PUSH_LAT_IMG=$HUB_ORG/$IMAGE_NAME:latest

    export RES_REPO=$CONTEXT"_repo"
    export RES_REPO_META=$(shipctl get_resource_meta $RES_REPO)
    export RES_REPO_STATE=$(shipctl get_resource_state $RES_REPO)

    pushd $RES_REPO_META
      export IMG_REPO_COMMIT_SHA=$(shipctl get_json_value version.json 'version.propertyBag.shaData.commitSha')
    popd

    echo ""
    echo "============= Begin State for $CONTEXT======================"

    echo "IMAGE_NAME=$IMAGE_NAME"
    echo "RES_IMAGE=$RES_IMAGE"

    echo "RES_REPO=$RES_REPO"
    echo "RES_GH_SSH=$RES_GH_SSH"
    echo "GH_ORG=$GH_ORG"
    echo "SSH_PATH=$SSH_PATH"
    echo "HUB_ORG=$HUB_ORG"

    echo "RES_VER_NAME=$RES_VER_NAME"
    echo "RES_REPO_STATE=$RES_REPO_STATE"

    echo "IMG_REPO_COMMIT_SHA=$IMG_REPO_COMMIT_SHA"
    echo "PULL_IMG=$PULL_IMG"
    echo "PUSH_IMG=$PUSH_IMG"
    echo "============= End State for $CONTEXT======================"
    echo ""

    shipctl put_resource_state $CURR_JOB $CONTEXT"_COMMIT_SHA" $IMG_REPO_COMMIT_SHA

  done

  popd

#  pull_tag_image
#  tag_push_repo
}

main
