#!/usr/bin/env bash

set -ex

echo "$GITHUB_SHA" > REVISION

docker build -t quay.io/$GITHUB_REPOSITORY:$GITHUB_SHA --build-arg RUBYGEMS_VERSION=$RUBYGEMS_VERSION .

echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin quay.io

docker push quay.io/$GITHUB_REPOSITORY:$GITHUB_SHA
