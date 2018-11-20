FROM ruby:2.3.5-alpine

# Product version
ARG DOCKER_IMAGE_VERSION
ENV DOCKER_IMAGE_VERSION ${DOCKER_IMAGE_VERSION:-0.0.0}
# Link to the product repository
ARG VCS_URL
# Hash of the commit
ARG VCS_REF
# Repository branch
ARG VCS_BRANCH
# Date of the build
ARG BUILD_DATE
# Include metadata, additionally use label-schema namespace
LABEL org.label-schema.schema-version="1.0" \
    org.label-schema.vendor="Cossack Labs" \
    org.label-schema.url="https://cossacklabs.com" \
    org.label-schema.name="AcraEngineeringDemo - rails - rubygems" \
    org.label-schema.description="AcraEngineeringDemo demonstrates features of main components of Acra Suite" \
    org.label-schema.version=$DOCKER_IMAGE_VERSION \
    org.label-schema.vcs-url=$VCS_URL \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.build-date=$BUILD_DATE \
    com.cossacklabs.product.name="acra-engdemo" \
    com.cossacklabs.product.version=$DOCKER_IMAGE_VERSION \
    com.cossacklabs.product.vcs-ref=$VCS_REF \
    com.cossacklabs.product.vcs-branch=$VCS_BRANCH \
    com.cossacklabs.product.component="acra-engdemo-rails-rubygems" \
    com.cossacklabs.docker.container.build-date=$BUILD_DATE \
    com.cossacklabs.docker.container.type="product"

EXPOSE 3000

VOLUME /app.acrakeys

RUN apk add --no-cache \
  bash \
  build-base \
  ca-certificates \
  git \
  libxml2-dev \
  libxslt-dev \
  linux-headers \
  nodejs \
  postgresql-client \
  postgresql-dev \
  ruby \
  ruby-dev \
  tzdata \
  zlib-dev \
  && rm -rf /var/cache/apk/*

# TODO : remove when themis will fully support alpine
RUN echo -e '#!/bin/sh\n\nexit 0\n' > /usr/sbin/ldconfig
RUN chmod +x /usr/sbin/ldconfig

RUN cd /root && git clone https://github.com/cossacklabs/themis.git
RUN cd /root/themis && make && make install

RUN mkdir -p /app
WORKDIR /app

RUN gem update --system 2.6.10

COPY . /app

RUN gem install bundler io-console --no-ri --no-rdoc && bundle install --jobs 20 --retry 5 --without deploy

RUN chmod +x /app/docker/entry.sh

WORKDIR /app
ENTRYPOINT ["/app/docker/entry.sh"]
