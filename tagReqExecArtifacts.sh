#!/bin/bash -e

# Input parameters
export ARCHITECTURE="$1"
export OS="$2"
export ARTIFACTS_BUCKET="$3"

# Release version name
export RELEASE_RESOURCE="rel_prod"
export RELEASE_RESOURCE_UPPERCASE=$(echo $RELEASE_RESOURCE | awk '{print toupper($0)}')
export RELEASE_VERSION_NAME=$(eval echo "$"$RELEASE_RESOURCE_UPPERCASE"_VERSIONNAME")

# Source path
export FROM_VERSION=master
export S3_BUCKET_FROM_PATH="$ARTIFACTS_BUCKET/reqExec/$FROM_VERSION/reqExec-$FROM_VERSION-$ARCHITECTURE-$OS.tar.gz"

# Destination path
export TO_VERSION="$RELEASE_VERSION_NAME"
export S3_BUCKET_TO_PATH="$ARTIFACTS_BUCKET/reqExec/$TO_VERSION/reqExec-$TO_VERSION-$ARCHITECTURE-$OS.tar.gz"

check_input() {
  if [ -z "$ARCHITECTURE" ]; then
    echo "Missing input parameter ARCHITECTURE"
    exit 1
  fi

  if [ -z "$OS" ]; then
    echo "Missing input parameter OS"
    exit 1
  fi

  if [ -z "$ARTIFACTS_BUCKET" ]; then
    echo "Missing input parameter ARTIFACTS_BUCKET"
    exit 1
  fi
}

copy_artifact() {
  echo "Copying from $S3_BUCKET_FROM_PATH to $S3_BUCKET_TO_PATH"
  aws s3 cp --acl public-read "$S3_BUCKET_FROM_PATH" "$S3_BUCKET_TO_PATH"
}

main() {
  check_input
  copy_artifact
}

main
