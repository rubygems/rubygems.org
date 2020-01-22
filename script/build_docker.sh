#!/usr/bin/env bash

set -ex

if [ -z "$RUBYGEMS_VERSION" ] || [ $RUBYGEMS_VERSION == 'latest' ]
then
  exit 0
fi

echo "$GITHUB_SHA" > REVISION

docker build -t quay.io/rubygems/rubygems.org:$GITHUB_SHA .

docker run -e RAILS_ENV=production -e SECRET_KEY_BASE=1234 -e DATABASE_URL=postgresql://localhost \
  --net host quay.io/rubygems/rubygems.org:$GITHUB_SHA \
  -- rake db:create db:migrate
docker run -d -e RAILS_ENV=production -e SECRET_KEY_BASE=1234 -e DATABASE_URL=postgresql://localhost \
  --net host quay.io/rubygems/rubygems.org:$GITHUB_SHA \
  -- unicorn_rails -E production -c /app/config/unicorn.conf

sleep 5
curl -m 5 http://localhost:3000/internal/ping | grep PONG

if [ $? -eq 1 ]; then
  echo "Internal ping api test didn't pass."
  docker ps -aqf "ancestor=quay.io/rubygems/rubygems.org:$GITHUB_SHA" | xargs -Iid docker logs id
  exit 1
fi

if [ -z "$DOCKER_USERNAME" ] || [ -z "$DOCKER_PASSWORD" ]
then
  exit 0
fi

echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin quay.io

docker push quay.io/rubygems/rubygems.org:$GITHUB_SHA
