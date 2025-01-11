# syntax = docker/dockerfile:1.10

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version and Gemfile
ARG RUBY_VERSION=3.4.1
ARG ALPINE_VERSION=3.20
FROM ruby:$RUBY_VERSION-alpine${ALPINE_VERSION} as base

# Install packages
RUN --mount=type=cache,id=dev-apk-cache,sharing=locked,target=/var/cache/apk \
  --mount=type=cache,id=dev-apk-lib,sharing=locked,target=/var/lib/apk \
  apk add \
  ca-certificates \
  bash \
  tzdata \
  xz-libs \
  gcompat \
  zstd-libs \
  libpq

# Rails app lives here
RUN mkdir -p /app /app/config /app/log/

# Set production environment
ENV BUNDLE_APP_CONFIG=".bundle_app_config"

# Update rubygems
ARG RUBYGEMS_VERSION
RUN gem update --system ${RUBYGEMS_VERSION} --no-document

# Throw-away build stage to reduce size of final image
FROM base as build

# Install packages
RUN \
  --mount=type=cache,id=dev-apk-cache,sharing=locked,target=/var/cache/apk \
  --mount=type=cache,id=dev-apk-lib,sharing=locked,target=/var/lib/apk \
  apk add \
  nodejs \
  postgresql-dev \
  build-base \
  linux-headers \
  zlib-dev \
  tzdata \
  git

WORKDIR /app

ENV RAILS_ENV="production"
ARG BUNDLE_WITH=""

# Install application gems
COPY Gemfile* .ruby-version /app/
RUN --mount=type=cache,id=bld-gem-cache,sharing=locked,target=/srv/vendor \
  --mount=type=secret,id=BUNDLE_PACKAGER__DEV,env=BUNDLE_PACKAGER__DEV \
  <<BASH
  set -ex

  bundle config set --local without 'development test'
  [ -z ${BUNDLE_WITH:-} ] || bundle config set --local with ${BUNDLE_WITH}
  bundle config set --local path /srv/vendor
  bundle install --jobs 20 --retry 5
  bundle clean
  mkdir -p vendor
  bundle config set --local path vendor
  cp -ar /srv/vendor .

  # Remove .gem files
  rm -r /app/vendor/ruby/*/cache

  # Remove gem extension build logs
  rm /app/vendor/ruby/*/extensions/*/*/*/gem_make.out

  # Remove avo source maps (8+ MB!)
  find /app/vendor/ruby -type f -name '*.js.map' -exec rm {} \;

  # Remove ruby 2.x source code
  find /app/vendor/ruby/*/gems/datadog-ruby_core_source-*/lib/datadog/ruby_core_source -maxdepth 1 -type d -name 'ruby-2.*' -exec rm -r {} \;

  # Remove datadog precompiled binaries for other platforms
  find /app/vendor/ruby/*/gems/libdatadog-*/vendor/libdatadog-*/ -mindepth 1 -maxdepth 1 -not -name "$(ruby -e 'puts RbConfig::CONFIG["arch"]')" -exec rm -r {} \;
BASH


# Copy application code
COPY . /app/


COPY --link config/database.yml.sample /app/config/database.yml


# Precompiling assets for production without requiring secret RAILS_MASTER_KEY
RUN <<BASH
  set -ex
  RAILS_GROUPS=assets SECRET_KEY_BASE_DUMMY=1 bin/rails assets:precompile
  rm -fr /app/tmp/cache/assets/
BASH

RUN <<BASH
  set -ex
  bundle config set --local without 'development test assets'
  bundle clean --force
  rm -r /app/tmp/cache/bootsnap/
  # Precompile bootsnap code for faster boot times, but do it after we've
  # removed the assets group for minimal precompilation size
  bundle exec bootsnap precompile --gemfile app/ lib/
BASH


# Final stage for app image
FROM base

RUN mkdir -p /app
WORKDIR /app

RUN mkdir -p tmp/pids

# Copy built application from previous stage
COPY --link --from=build /app/ /app/

ADD --link https://s3-us-west-2.amazonaws.com/oregon.production.s3.rubygems.org/versions/versions.list /app/config/versions.list
ADD --link https://s3-us-west-2.amazonaws.com/oregon.production.s3.rubygems.org/stopforumspam/toxic_domains_whole.txt /app/vendor/toxic_domains_whole.txt

ARG REVISION
RUN echo "${REVISION}" > REVISION

# Stop bootsnap from writing to the filesystem, we precompiled it in the build stage
ENV BOOTSNAP_READONLY=true

EXPOSE 3000

# Ensures ruby commands are run with bundler
ENTRYPOINT ["bundle", "exec"]

# Start the server by default, this can be overwritten at runtime
CMD ["rails", "server", "-b", "0.0.0.0"]
