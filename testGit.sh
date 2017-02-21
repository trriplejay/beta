#!/bin/bash -e

export CURR_JOB="test_git_push"
export RES_REPO="config_repo"
export RES_TEST_REPO="test_repo"
export RES_GH_SSH="avi_gh_ssh"

export RES_REPO_UP=$(echo $RES_REPO | awk '{print toupper($0)}')
export RES_REPO_STATE=$(eval echo "$"$RES_REPO_UP"_STATE")

export RES_TEST_REPO_UP=$(echo $RES_TEST_REPO | awk '{print toupper($0)}')
export RES_TEST_REPO_STATE=$(eval echo "$"$RES_TEST_REPO_UP"_STATE")

export RES_GH_SSH_UP=$(echo $RES_GH_SSH | awk '{print toupper($0)}')
export RES_GH_SSH_META=$(eval echo "$"$RES_GH_SSH_UP"_VERSIONNAME")

set_context() {
  echo "CURR_JOB=$CURR_JOB"
  echo "RES_REPO=$RES_REPO"
  echo "RES_TEST_REPO=$RES_TEST_REPO"
  echo "RES_GH_SSH=$RES_GH_SSH"

  echo "RES_REPO_UP=$RES_REPO_UP"
  echo "RES_REPO_STATE=$RES_REPO_STATE"
  echo "RES_TEST_REPO_UP=$RES_TEST_REPO_UP"
  echo "RES_TEST_REPO_STATE=$RES_TEST_REPO_STATE"
  echo "RES_GH_SSH_UP=$RES_GH_SSH_UP"
  echo "RES_GH_SSH_META=$RES_GH_SSH_META"
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

tag_push_base(){
  pushd $RES_TEST_REPO_STATE
  git tag $BUILD_NUMBER
  git push origin $BUILD_NUMBER
  popd
}

main() {
  eval `ssh-agent -s`
  ps -eaf | grep ssh
  which ssh-agent

  set_context
  add_ssh_key
  tag_push_base
}

main
