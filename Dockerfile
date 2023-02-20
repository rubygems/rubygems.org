# syntax = docker/dockerfile:1.4

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version and Gemfile
ARG RUBY_VERSION=3.2.1
ARG ALPINE_VERSION=3.17
ARG NODE_VERSION=18.14.1

FROM ruby:$RUBY_VERSION-alpine${ALPINE_VERSION} as base

# Install packages
RUN --mount=type=cache,id=dev-apk-cache,sharing=locked,target=/var/cache/apk \
  --mount=type=cache,id=dev-apk-lib,sharing=locked,target=/var/lib/apk \
  apk add \
  ca-certificates \
  bash \
  tzdata \
  xz-libs \
  gcompat

# Rails app lives here
RUN mkdir -p /app /app/config /app/log/

# Set production environment
ENV BUNDLE_APP_CONFIG=".bundle_app_config"

# Update rubygems
ARG RUBYGEMS_VERSION
RUN gem update --system ${RUBYGEMS_VERSION} --no-document


# yarn install in its own image
FROM node:${NODE_VERSION}-alpine${ALPINE_VERSION} as build-yarn

# Install JavaScript dependencies
ARG YARN_VERSION=1.22.1
RUN npm install -g --force yarn@$YARN_VERSION
RUN corepack enable && \
  corepack prepare yarn@$YARN_VERSION --activate
WORKDIR /app
COPY yarn.lock .
RUN --mount=type=cache,id=bld-yarn-cache,sharing=locked,target=/root/.yarn \
  YARN_CACHE_FOLDER=/root/.yarn yarn install --prod

# Throw-away build stage to reduce size of final image
FROM base as build-bundler

# Install build packages
RUN \
  --mount=type=cache,id=dev-apk-cache,sharing=locked,target=/var/cache/apk \
  --mount=type=cache,id=dev-apk-lib,sharing=locked,target=/var/lib/apk \
  apk add \
  nodejs \
  postgresql-dev \
  ca-certificates \
  build-base \
  bash \
  linux-headers \
  zlib-dev \
  tzdata 

WORKDIR /app

ENV RAILS_ENV="production"


# Install application gems
COPY Gemfile* /app/
RUN --mount=type=cache,id=bld-gem-cache,sharing=locked,target=/srv/vendor \
  bundle config set --local without 'development test' && \
  bundle config set --local path /srv/vendor && \
  bundle install --jobs 20 --retry 5 && \
  bundle exec bootsnap precompile --gemfile && \
  bundle clean && \
  mkdir -p vendor && \
  bundle config set --local path vendor && \
  cp -ar /srv/vendor . && \
  rm -fr /app/vendor/ruby/*/cache


# Copy application code
COPY . /app/

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/
RUN mv /app/config/database.yml.sample /app/config/database.yml

FROM build-bundler as build

COPY --link --from=build-yarn /usr/lib /usr/lib
COPY --link --from=build-yarn /usr/local/share /usr/local/share
COPY --link --from=build-yarn /usr/local/lib /usr/local/lib
COPY --link --from=build-yarn /usr/local/include /usr/local/include
COPY --link --from=build-yarn /usr/local/bin /usr/local/bin
COPY --link --from=build-yarn /opt /opt
COPY --link --from=build-yarn /app/node_modules/ /app/node_modules/

# Precompiling assets for production without requiring secret RAILS_MASTER_KEY
RUN RAILS_GROUPS=assets SECRET_KEY_BASE=1234 bin/rails assets:precompile && \
  bundle config set --local without 'development test assets' && \
  bundle clean --force


# Final stage for app image
FROM base

RUN --mount=type=cache,id=dev-apk-cache,sharing=locked,target=/var/cache/apk \
  --mount=type=cache,id=dev-apk-lib,sharing=locked,target=/var/lib/apk \
  apk add \
  libpq \
  ca-certificates \
  bash \
  tzdata \
  xz-libs

RUN mkdir -p /app
WORKDIR /app


# Copy built application from previous stage
COPY --link --from=build /app/ /app/

ADD https://s3-us-west-2.amazonaws.com/oregon.production.s3.rubygems.org/versions/versions.list /app/config/versions.list
ADD https://s3-us-west-2.amazonaws.com/oregon.production.s3.rubygems.org/stopforumspam/toxic_domains_whole.txt /app/vendor/toxic_domains_whole.txt

ARG REVISION
RUN echo "${REVISION}" > REVISION

EXPOSE 3000

# Ensures ruby commands are run with bundler
ENTRYPOINT ["bundle", "exec"]

# Start the server by default, this can be overwritten at runtime
CMD ["rails", "server", "-b", "0.0.0.0"]
