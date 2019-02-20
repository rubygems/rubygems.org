#!/usr/bin/env bash

set -ex

if [[ $RUBYGEMS_VERSION == 'latest' ]] || [[ $TRAVIS_RUBY_VERSION == 'ruby-head' ]]
then
  exit 0
fi

if [[ -f "$HOME/docker/docker-cache.tgz" ]]
then
  docker load -i $HOME/docker/docker-cache.tgz
fi

echo "$TRAVIS_COMMIT" > REVISION

docker build --target build --cache-from rubygems-org:build -t rubygems-org:build .
docker build --cache-from rubygems-org:build -t quay.io/$TRAVIS_REPO_SLUG:$TRAVIS_COMMIT .

mkdir -p $HOME/docker
docker save -o $HOME/docker/docker-cache.tgz rubygems-org

if [ -z "$DOCKER_USERNAME" ] || [ -z "$DOCKER_PASSWORD" ]
then
  exit 0
fi

echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin quay.io

docker push quay.io/$TRAVIS_REPO_SLUG:$TRAVIS_COMMIT
