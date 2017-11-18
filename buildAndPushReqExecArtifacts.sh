#!/bin/bash -e

# Input parameters
export ARCHITECTURE="$1"
export OS="$2"
export ARTIFACTS_BUCKET="$3"
export VERSION=master

# reqExec
export REQ_EXEC_PATH="$REQEXEC_REPO_STATE"
export REQ_EXEC_PACKAGE_DIR="$REQEXEC_REPO_STATE/package/$ARCHITECTURE/$OS"

# Binaries
export S3_BUCKET_BINARY_DIR="$ARTIFACTS_BUCKET/reqExec/$VERSION/$ARCHITECTURE/$OS"

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

create_binaries_dir() {
  echo "Cleaning up $REQ_EXEC_BINARY_DIR..."
  rm -rf $REQ_EXEC_BINARY_DIR
  mkdir $REQ_EXEC_BINARY_DIR
}

build_and_push_reqExec() {
  pushd $REQ_EXEC_PATH
    echo "Packaging reqExec..."
    $REQ_EXEC_PACKAGE_DIR/package.sh

    echo "Cleaning up S3 binary path..."
    aws s3 rm --recursive $S3_BUCKET_BINARY_DIR

    echo "Pushing reqExec binary to S3..."
    aws s3 cp --recursive --acl public-read dist/main $S3_BUCKET_BINARY_DIR
  popd
}

main() {
  check_input
  create_binaries_dir
  build_and_push_reqExec
}

main
