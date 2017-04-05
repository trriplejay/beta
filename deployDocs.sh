#!/bin/bash -e

export DOCS_BUCKET=$1
export DOCS_REGION=$2
export AWS_S3_LOCAL_PATH="site"

sync_docs() {
  pushd IN/docs_repo/gitRepo/

  if [ -d "$AWS_S3_LOCAL_PATH" ]; then
    cp -r sources "$AWS_S3_LOCAL_PATH"
    cp -r themes "$AWS_S3_LOCAL_PATH"
    # echo "Installing requirements with pip"
    # pip install -r requirements.txt

    # echo "Building docs"
    # mkdocs build
  else
    mkdir -p "$AWS_S3_LOCAL_PATH"
    echo "Directory created: $AWS_S3_LOCAL_PATH"
  fi

  echo "Syncing with S3"
  aws s3 sync $AWS_S3_LOCAL_PATH $DOCS_BUCKET --delete --acl public-read --region $DOCS_REGION
  popd
}

sync_docs
