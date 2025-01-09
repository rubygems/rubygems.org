# syntax = docker/dockerfile:1.4

ARG RUBY_VERSION=3.4.1
FROM ghcr.io/rails/devcontainer/images/ruby:$RUBY_VERSION

RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends pkg-config \
    && apt-get clean && rm -rf /var/lib/apt/lists/*
