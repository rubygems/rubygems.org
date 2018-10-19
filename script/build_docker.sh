#!/usr/bin/env bash

set -ex

if [ -z "$RUBYGEMS_VERSION" ] || [ $RUBYGEMS_VERSION == 'latest' ]
then
  exit 0
fi

if [ -z "$TRAVIS_RUBY_VERSION" ] || [ $TRAVIS_RUBY_VERSION == 'ruby-head' ]
then
  exit 0
fi

echo "$TRAVIS_COMMIT" > REVISION

docker build -t quay.io/$TRAVIS_REPO_SLUG:$TRAVIS_COMMIT .

if [ -z "$DOCKER_USERNAME" ] || [ -z "$DOCKER_PASSWORD" ]
then
  exit 0
fi

echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin quay.io

docker push quay.io/$TRAVIS_REPO_SLUG:$TRAVIS_COMMIT
