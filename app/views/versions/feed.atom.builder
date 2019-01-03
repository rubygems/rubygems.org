# frozen_string_literal: true

render(
  partial: 'versions/versions_feed',
  locals: {
    builder: xml,
    versions: @versions,
    title: "Rubygems | Latest Gems"
  }
)
