FROM ruby:2.6-alpine as build

ARG RUBYGEMS_VERSION

RUN apk add --no-cache \
  nodejs \
  postgresql-dev \
  ca-certificates \
  build-base \
  bash \
  linux-headers \
  zlib-dev \
  tzdata \
  && rm -rf /var/cache/apk/*

RUN mkdir -p /app /app/config /app/log/
WORKDIR /app

COPY .rubygems-version .

RUN [[ -z "$RUBYGEMS_VERSION" ]] && gem update --system $(cat .rubygems-version) || gem update --system "$RUBYGEMS_VERSION"

COPY . /app

ADD https://s3-us-west-2.amazonaws.com/oregon.production.s3.rubygems.org/versions/versions.list /app/config/versions.list

RUN mv /app/config/database.yml.example /app/config/database.yml

RUN gem install bundler io-console --no-doc && \
  bundle config set without 'development test' && \
  bundle install --jobs 20 --retry 5

RUN RAILS_ENV=production RAILS_GROUPS=js SECRET_KEY_BASE=1234 bin/rails assets:precompile


FROM ruby:2.6-alpine

RUN apk add --no-cache \
  libpq \
  ca-certificates \
  bash \
  tzdata \
  xz-libs \
  && rm -rf /var/cache/apk/*

COPY .rubygems-version .

RUN [[ -z "$RUBYGEMS_VERSION" ]] && gem update --system $(cat .rubygems-version) || gem update --system "$RUBYGEMS_VERSION"

RUN mkdir -p /app
WORKDIR /app

COPY --from=build /usr/local/bin/gem /usr/local/bin/gem
COPY --from=build /usr/local/bundle/ /usr/local/bundle/
COPY --from=build /app/ /app/

EXPOSE 3000

ENTRYPOINT ["bundle", "exec"]
CMD ["rails", "server", "-b", "0.0.0.0"]
