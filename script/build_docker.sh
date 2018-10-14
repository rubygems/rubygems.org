#!/usr/bin/env bash

set -ex

if [ $RUBYGEMS_VERSION == 'latest' ]
then
  exit 0
fi

if [ $TRAVIS_RUBY_VERSION == 'ruby-head' ]
then
  exit 0
fi

echo "$TRAVIS_COMMIT" > REVISION

docker build -t quay.io/$TRAVIS_REPO_SLUG:$TRAVIS_COMMIT .

echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin quay.io

docker push quay.io/$TRAVIS_REPO_SLUG:$TRAVIS_COMMIT
