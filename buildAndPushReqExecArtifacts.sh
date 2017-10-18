#!/bin/bash -e

# Input parameters
export ARCHITECTURE="$1"
export OS="$2"
export ARTIFACTS_BUCKET="$3"
export VERSION=master

# reqExec
export REQ_EXEC_PATH="$REQEXEC_REPO_STATE"

# Reports
export REPORTS_SRC_DIR="$MICRO_REPO_STATE/gol/src/github.com/Shippable/reports"
export REPORTS_BIN_DIR="$MICRO_REPO_STATE/gol/bin"

# Binaries
export REQ_EXEC_BINARY_DIR="/tmp/reqExec"
export REQ_EXEC_BINARY_TAR="/tmp/reqExec-$VERSION-$ARCHITECTURE-$OS.tar.gz"
export S3_BUCKET_BINARY_DIR="$ARTIFACTS_BUCKET/reqExec/$VERSION/"

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

build_reqExec() {
  pushd $REQ_EXEC_PATH
    echo "Packaging reqExec..."
    make package

    echo "Copying build.sh..."
    cp build.sh $REQ_EXEC_BINARY_DIR

    echo "Copying dist..."
    cp -r dist $REQ_EXEC_BINARY_DIR
  popd
}

build_reports() {
  pushd $REPORTS_SRC_DIR
    echo "Packaging reports..."
    make build
    cp -r $REPORTS_BIN_DIR $REQ_EXEC_BINARY_DIR
  popd
}

push_to_s3() {
  echo "Pushing to S3..."
  tar -zcvf "$REQ_EXEC_BINARY_TAR" -C "$REQ_EXEC_BINARY_DIR" .
  aws s3 cp --acl public-read "$REQ_EXEC_BINARY_TAR" "$S3_BUCKET_BINARY_DIR"
}

main() {
  check_input
  create_binaries_dir
  build_reqExec
  build_reports
  push_to_s3
}

main
