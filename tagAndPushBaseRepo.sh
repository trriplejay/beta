#!/bin/bash -e

export CURR_JOB="tag_push_base"
export RES_IMAGE="base_img"
export RES_VER="rel_prod"
export RES_REPO="base_repo"
export RES_GH_SSH="avi_gh_ssh"
export SSH_PATH="git@github.com:Shippable/base.git"

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

  echo "CURR_JOB=$CURR_JOB"
  echo "RES_IMAGE=$RES_IMAGE"
  echo "RES_VER=$RES_VER"
  echo "RES_REPO=$RES_REPO"
  echo "RES_GH_SSH=$RES_GH_SSH"
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

tag_push_repo() {
  pushd $RES_REPO_STATE

  git remote add up $SSH_PATH
  git remote -v
  git checkout master

  # dont checkout the sha here as we are going to edit and we might hit merge
  # conflicts. master should typically not change an also implementing lock on
  # release also will reduce this. Hence this is an acceptable risk

  git pull --tags

  if git tag -d $RES_VER_NAME; then
    git push --delete up $RES_VER_NAME
  fi

  local migrations_dir="migrations/"
  local migrations_version_file=$migrations_dir""$RES_VER_NAME".sql"
  local migrations_post_install_dir="migrations/post_install/"
  local migrations_post_install_versions_file=$migrations_post_install_dir""$RES_VER_NAME"-post_install.sql"
  local migrations_pre_install_dir="migrations/pre_install/"
  local migrations_pre_install_versions_file=$migrations_pre_install_dir""$RES_VER_NAME"-pre_install.sql"
  local versions_dir="versions/"
  local versions_file=$versions_dir""$RES_VER_NAME".json"

  # make sure the alias cp - i is overridden
  #unalias cp

  cp -rf $migrations_dir"master.sql" $migrations_version_file
  cp -rf $migrations_post_install_dir"master-post_install.sql" $migrations_post_install_versions_file
  cp -rf $migrations_pre_install_dir"master-pre_install.sql" $migrations_pre_install_versions_file
  cp -rf $versions_dir"master.json" $versions_file

  git add .
  git commit -m "creating $RES_VER_NAME version files"

  git push up master
  IMG_REPO_COMMIT_SHA=$(git rev-parse HEAD)

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
