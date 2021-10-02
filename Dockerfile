FROM bitnami/ruby:3.0-prod as build

ARG RUBYGEMS_VERSION

RUN apt update && apt install -y \
  nodejs \
  libpq-dev \
  ca-certificates \
  build-essential \
  zlib1g-dev \
  tzdata \
  && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /app /app/config /app/log/
WORKDIR /app

RUN gem update --system $RUBYGEMS_VERSION --no-document

COPY Gemfile* /app/

RUN bundle config set --local without 'development test' && \
  bundle config set --local path 'vendor/bundle' && \
  bundle install --jobs 20 --retry 5

COPY . /app/

ADD https://s3-us-west-2.amazonaws.com/oregon.production.s3.rubygems.org/versions/versions.list /app/config/versions.list
ADD https://s3-us-west-2.amazonaws.com/oregon.production.s3.rubygems.org/stopforumspam/toxic_domains_whole.txt /app/vendor/toxic_domains_whole.txt

RUN mv /app/config/database.yml.example /app/config/database.yml

RUN RAILS_ENV=production RAILS_GROUPS=assets SECRET_KEY_BASE=1234 bin/rails assets:precompile

RUN bundle config set --local without 'development test assets' && \
  bundle clean --force


FROM bitnami/ruby:3.0-prod

ARG RUBYGEMS_VERSION

RUN apt update && apt install -y \
  libpq-dev \
  ca-certificates \
  tzdata \
  xz-utils \
  && rm -rf /var/lib/apt/lists/*

RUN gem update --system $RUBYGEMS_VERSION --no-document

RUN mkdir -p /app
WORKDIR /app

COPY --from=build /app/ /app/
COPY --from=build /app/vendor/bundle/ /app/vendor/bundle/

EXPOSE 3000

ENTRYPOINT ["bundle", "exec"]
CMD ["rails", "server", "-b", "0.0.0.0"]
