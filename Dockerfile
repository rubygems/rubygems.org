FROM ruby:2.7-alpine as build

ARG BUNDLE_DEPLOYMENT=true
ARG BUNDLE_JOBS=4
ARG BUNDLE_RETRY=5
ARG BUNDLE_WITHOUT="development:test"

RUN apk add --no-cache \
  ruby \
  nodejs \
  postgresql-dev \
  ca-certificates \
  build-base \
  bash \
  linux-headers \
  zlib-dev \
  tzdata \
  && rm -rf /var/cache/apk/*

WORKDIR /app

COPY Gemfile* ./

RUN bundle install

COPY . ./

ADD https://s3-us-west-2.amazonaws.com/oregon.production.s3.rubygems.org/versions/versions.list config/versions.list

RUN mv config/database.yml.example config/database.yml

RUN RAILS_ENV=production SECRET_KEY_BASE=1234 bin/rails assets:precompile




FROM ruby:2.6-alpine

RUN apk add --no-cache \
  ruby \
  nodejs \
  libpq \
  ca-certificates \
  bash \
  tzdata \
  xz-libs \
  && rm -rf /var/cache/apk/*

WORKDIR /app

COPY --from=build /app/ /app/

EXPOSE 3000

ENTRYPOINT ["bundle", "exec"]
CMD ["rails", "server", "-b", "0.0.0.0"]
