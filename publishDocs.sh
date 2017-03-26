#!/bin/bash -e

export DOCS_CONTEXT=$1
export DOCS_BUCKET=$2
export DOCS_REGION=$3

export RES_AWS_CREDS="aws_"$DOCS_CONTEXT"_access"
export RES_AWS_CREDS_UP=$(echo $RES_AWS_CREDS | awk '{print toupper($0)}')

export AWS_ACCESS_KEY=$(eval echo "$"$RES_AWS_CREDS_UP"_INTEGRATION_AWS_ACCESS_KEY_ID")
export AWS_SECRET_KEY=$(eval echo "$"$RES_AWS_CREDS_UP"_INTEGRATION_AWS_SECRET_ACCESS_KEY")
export AWS_S3_LOCAL_PATH="site"

sync_docs() {
  pushd IN/docsv2_repo/gitRepo/

  echo "Installing requirements with pip"
  pip install -r requirements.txt

  echo "Building docs"
  mkdocs build

  echo "Syncing with S3"
  aws s3 sync $AWS_S3_LOCAL_PATH $DOCS_BUCKET --delete --acl public-read --region $DOCS_REGION

  popd
}

sync_docs