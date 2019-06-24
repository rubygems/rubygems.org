render(
  partial: "versions/versions_feed",
  locals: {
    builder: xml,
    versions: @versions,
    title: "Rubygems | Latest Versions for #{@rubygem.name}"
  }
)
