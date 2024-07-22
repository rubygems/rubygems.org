# syntax = docker/dockerfile:1.4

ARG RUBY_VERSION=3.3

FROM ruby:${RUBY_VERSION}-alpine

ENV USERNAME=vscode \
    UID=1000 \
    GID=1000

# Install the git-credential-manager package via the dotnet tooling to 
RUN apk update && apk add --no-cache \
    github-cli \
    git \
    build-base \
    bash \
    mandoc \
    man-pages \
    tzdata \
    libpq-dev \
    libmagic \
    nodejs \
    sudo

# create non-root group and user
RUN addgroup -g $GID $USERNAME \
    && adduser -s /bin/bash -u $UID -G $USERNAME $USERNAME --disabled-password --gecos ""

# set sudo permissions for vscode user
RUN echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME
RUN chmod 0440 /etc/sudoers.d/$USERNAME

USER $USERNAME
