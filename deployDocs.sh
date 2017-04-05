#!/bin/bash -e

export DOCS_BUCKET=$1
export DOCS_REGION=$2
export AWS_S3_LOCAL_PATH="site"

sync_docs() {
  pushd IN/docs_repo/gitRepo/

  echo "Installing requirements with pip"
  pip install -r requirements.txt

  echo "Building docs"
  mkdocs build

  echo "Syncing with S3"
  aws s3 sync $AWS_S3_LOCAL_PATH $DOCS_BUCKET --delete --acl public-read --region $DOCS_REGION
  popd
}

sync_docs
