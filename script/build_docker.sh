#!/usr/bin/env bash

set -ex

if [ -z "$RUBYGEMS_VERSION" ] || [ "$RUBYGEMS_VERSION" == 'latest' ]; then
  exit 0
fi

if [ -z "$RUBY_VERSION" ] || [ "$RUBY_VERSION" == 'ruby-head' ]; then
  exit 0
fi

# make repository lower-case, since it is used in docker image tag
# and must be lowercase
GITHUB_REPOSITORY=$(echo "$GITHUB_REPOSITORY" | tr '[:upper:]' '[:lower:]')

DOCKER_TAG="048268392960.dkr.ecr.us-west-2.amazonaws.com/$GITHUB_REPOSITORY:$GITHUB_SHA"

docker buildx build --cache-from=type=local,src=/tmp/.buildx-cache \
  --cache-to=mode=max,type=local,dest=/tmp/.buildx-cache-new \
  --output type=docker \
  --tag "$DOCKER_TAG" \
  --build-arg RUBYGEMS_VERSION="$RUBYGEMS_VERSION" \
  --build-arg REVISION="$GITHUB_SHA" \
  .

docker run -e RAILS_ENV=production -e SECRET_KEY_BASE=1234 -e DATABASE_URL=postgresql://localhost \
  --net host "$DOCKER_TAG" \
  -- bin/rails db:create db:migrate
docker run -d -e RAILS_ENV=production -e SECRET_KEY_BASE=1234 -e DATABASE_URL=postgresql://localhost \
  --net host "$DOCKER_TAG" \
  -- puma --environment production --config /app/config/puma.rb

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

rubygems_version_installed=$(docker run "$DOCKER_TAG" -- gem -v)

if [ "$rubygems_version_installed" != "$RUBYGEMS_VERSION" ]; then
  echo "Installed gem version doesn't match"
  echo "expected: $RUBYGEMS_VERSION, found: $rubygems_version_installed"
  exit 1
fi

pusher_arn="arn:aws:iam::048268392960:role/rubygems-ecr-pusher"
caller_arn="$(aws sts get-caller-identity --output text --query Arn || true)"

[[ "$caller_arn" == "$pusher_arn" ]] ||
  [[ "$caller_arn" == "arn:aws:sts::048268392960:assumed-role/rubygems-ecr-pusher/GitHubActions" ]] ||
  export $(printf "AWS_ACCESS_KEY_ID=%s AWS_SECRET_ACCESS_KEY=%s AWS_SESSION_TOKEN=%s" \
    $(aws sts assume-role \
      --role-arn "${pusher_arn}" \
      --role-session-name push-rubygems-docker-tag \
      --query "Credentials.[AccessKeyId,SecretAccessKey,SessionToken]" \
      --output text)) ||
  true

if [[ -z "${AWS_SESSION_TOKEN}" ]]; then
  echo "Skipping push since no AWS session token was found"
  exit 0
fi

docker push "$DOCKER_TAG"

if [ -n "$GITHUB_STEP_SUMMARY" ]; then
  echo -n "Pushed image \`$DOCKER_TAG\`\n" >>"$GITHUB_STEP_SUMMARY"
fi
