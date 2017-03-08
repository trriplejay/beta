#!/bin/bash -e

export CONTEXT=$1
export GH_ORG=$2

export CURR_JOB="tag_push_"$CONTEXT
export RES_IMAGE=$CONTEXT"_img"
export RES_VER="rel_prod"
export RES_REPO=$CONTEXT"_repo"
export RES_GH_SSH="avi_gh_ssh"
export SSH_PATH="git@github.com:$GH_ORG/$CONTEXT.git"

export RES_IMAGE_UP=$(echo $RES_IMAGE | awk '{print toupper($0)}')
export RES_IMAGE_META=$(eval echo "$"$RES_IMAGE_UP"_META")

export RES_VER_UP=$(echo $RES_VER | awk '{print toupper($0)}')
export RES_VER_NAME=$(eval echo "$"$RES_VER_UP"_VERSIONNAME")

export RES_REPO_UP=$(echo $RES_REPO | awk '{print toupper($0)}')
export RES_REPO_STATE=$(eval echo "$"$RES_REPO_UP"_STATE")

export RES_GH_SSH_UP=$(echo $RES_GH_SSH | awk '{print toupper($0)}')
export RES_GH_SSH_META=$(eval echo "$"$RES_GH_SSH_UP"_META")

set_context() {

  pushd $RES_IMAGE_META
  export IMG_REPO_COMMIT_SHA=$(jq -r '.version.propertyBag.IMG_REPO_COMMIT_SHA' version.json)
  popd

  echo "CONTEXT=$CONTEXT"
  echo "CURR_JOB=$CURR_JOB"
  echo "RES_IMAGE=$RES_IMAGE"
  echo "RES_VER=$RES_VER"
  echo "RES_REPO=$RES_REPO"
  echo "RES_GH_SSH=$RES_GH_SSH"
  echo "GH_ORG=$GH_ORG"
  echo "SSH_PATH=$SSH_PATH"

  echo "RES_IMAGE_META=$RES_IMAGE_META"
  echo "RES_VER_UP=$RES_VER_UP"
  echo "RES_VER_NAME=$RES_VER_NAME"
  echo "RES_REPO_UP=$RES_REPO_UP"
  echo "RES_REPO_STATE=$RES_REPO_STATE"
  echo "RES_GH_SSH_UP=$RES_GH_SSH_UP"
  echo "RES_GH_SSH_META=$RES_GH_SSH_META"

  echo "IMG_REPO_COMMIT_SHA=$IMG_REPO_COMMIT_SHA"
}

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

tag_push_repo(){
  pushd $RES_REPO_STATE

  git remote add up $SSH_PATH
  git remote -v
  git checkout master

  git pull --tags
  git checkout $IMG_REPO_COMMIT_SHA

  if git tag -d $RES_VER_NAME; then
    git push --delete origin $RES_VER_NAME
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

  set_context
  add_ssh_key
  tag_push_repo
  create_out_state
}

main
