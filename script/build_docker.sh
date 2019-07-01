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

docker run -e RAILS_ENV=production -e SECRET_KEY_BASE=1234 -e DATABASE_URL=postgresql://localhost \
  --net host quay.io/$TRAVIS_REPO_SLUG:$TRAVIS_COMMIT \
  -- rake db:create db:migrate
docker run -d -e RAILS_ENV=production -e SECRET_KEY_BASE=1234 -e DATABASE_URL=postgresql://localhost \
  --net host quay.io/$TRAVIS_REPO_SLUG:$TRAVIS_COMMIT \
  -- unicorn_rails -E production -c /app/config/unicorn.conf

sleep 5
curl http://localhost:3000/internal/ping | grep PONG

if [ $? -eq 1 ]; then
  echo "Internal ping api test didn't pass."
  exit 1
fi

if [ -z "$DOCKER_USERNAME" ] || [ -z "$DOCKER_PASSWORD" ]
then
  exit 0
fi

echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin quay.io

docker push quay.io/$TRAVIS_REPO_SLUG:$TRAVIS_COMMIT
