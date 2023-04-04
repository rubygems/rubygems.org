# syntax = docker/dockerfile:1.4

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version and Gemfile
ARG RUBY_VERSION=3.2.1
ARG ALPINE_VERSION=3.17
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
ENV MAGIC="/usr/share/misc/magic.mgc"

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
  ca-certificates \
  build-base \
  bash \
  libmagic \
  zstd-libs \
  linux-headers \
  zlib-dev \
  git \
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


# Precompiling assets for production without requiring secret RAILS_MASTER_KEY
RUN RAILS_GROUPS=assets SECRET_KEY_BASE=1234 bin/rails assets:precompile

RUN bundle config set --local without 'development test assets' && \
  bundle clean --force


# Final stage for app image
FROM base as app

RUN --mount=type=cache,id=dev-apk-cache,sharing=locked,target=/var/cache/apk \
  --mount=type=cache,id=dev-apk-lib,sharing=locked,target=/var/lib/apk \
  apk add \
  libpq \
  libmagic \
  zstd-libs \
  ca-certificates \
  bash \
  tzdata \
  xz-libs

RUN mkdir -p /app
WORKDIR /app

RUN mkdir -p tmp/pids

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
