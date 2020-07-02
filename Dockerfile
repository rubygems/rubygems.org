FROM ruby:2.6-alpine as build

ARG BUNDLE_DEPLOYMENT=true
ARG BUNDLE_JOBS=4
ARG BUNDLE_RETRY=5

RUN apk add --no-cache \
  ruby \
  nodejs \
  postgresql-client \
  postgresql-dev \
  ca-certificates \
  ruby-dev \
  build-base \
  bash \
  linux-headers \
  zlib-dev \
  libxml2-dev \
  libxslt-dev \
  tzdata \
  && rm -rf /var/cache/apk/*

RUN mkdir -p /app /app/config /app/log/
WORKDIR /app

RUN gem update --system 2.6.10
RUN gem install bundler

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
  postgresql-client \
  ca-certificates \
  bash \
  tzdata \
  xz-libs \
  && rm -rf /var/cache/apk/*

RUN gem install bundler

RUN mkdir -p /app
WORKDIR /app

COPY --from=build /app/ /app/

EXPOSE 3000

ENTRYPOINT ["bundle", "exec"]
CMD ["rails", "server", "-b", "0.0.0.0"]
