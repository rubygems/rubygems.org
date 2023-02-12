#!/usr/bin/env bash

set -ex

if [ -z "$RUBYGEMS_VERSION" ] || [ $RUBYGEMS_VERSION == 'latest' ]
then
  exit 0
fi

if [ -z "$RUBY_VERSION" ] || [ $RUBY_VERSION == 'ruby-head' ]
then
  exit 0
fi

# make repository lower-case, since it is used in docker image tag
# and must be lowercase
GITHUB_REPOSITORY=$(echo "$GITHUB_REPOSITORY" | tr '[:upper:]' '[:lower:]')

DOCKER_TAG="quay.io/$GITHUB_REPOSITORY:$GITHUB_SHA"

docker buildx build --cache-from=type=local,src=/tmp/.buildx-cache \
  --cache-to=mode=max,type=local,dest=/tmp/.buildx-cache-new \
  --output type=docker \
  -t quay.io/$GITHUB_REPOSITORY:$GITHUB_SHA \
  --build-arg RUBYGEMS_VERSION=$RUBYGEMS_VERSION \
  --build-arg REVISION="$GITHUB_SHA" \
  .

docker run -e RAILS_ENV=production -e SECRET_KEY_BASE=1234 -e DATABASE_URL=postgresql://localhost \
  --net host $DOCKER_TAG \
  -- bin/rails db:create db:migrate
docker run -d -e RAILS_ENV=production -e SECRET_KEY_BASE=1234 -e DATABASE_URL=postgresql://localhost \
  --net host $DOCKER_TAG \
  -- unicorn_rails -E production -c /app/config/unicorn.conf

sleep 5
pong=$(curl -m 5 http://localhost:3000/internal/ping || true)

if [ "${pong}" != "PONG" ]; then
  echo "Internal ping api test didn't pass."
  docker ps -aqf "ancestor=$DOCKER_TAG" | xargs -Iid docker logs id
  exit 1
fi

revision=$(curl -m 5 http://localhost:3000/internal/revision || true)
if [ "${revision}" != "${GITHUB_SHA}" ]; then
  echo "Internal revision test didn't pass."
  docker ps -aqf "ancestor=$DOCKER_TAG" | xargs -Iid docker logs id
  exit 1
fi

rubygems_version_installed=$(docker run $DOCKER_TAG -- gem -v)

if [ $rubygems_version_installed != $RUBYGEMS_VERSION ]; then
  echo "Installed gem version doesn't match"
  echo "expected: $RUBYGEMS_VERSION, found: $rubygems_version_installed"
  exit 1
fi

if [ -z "$DOCKER_USERNAME" ] || [ -z "$DOCKER_PASSWORD" ]
then
  exit 0
fi

echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin quay.io

docker push $DOCKER_TAG
