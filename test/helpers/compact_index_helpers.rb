# frozen_string_literal: true

module CompactIndexHelpers
  def build_version(**args)
    name = args.fetch(:name, "test_gem")
    number = args.fetch(:number, "1.0")
    CompactIndex::GemVersion.new(
      number,
      args[:platform],
      args.fetch(:checksum, "sum+#{name}+#{number}"),
      args.fetch(:info_checksum, "info+#{name}+#{number}"),
      args[:dependencies],
      args[:ruby_version],
      args[:rubygems_version]
    )
  end
end
