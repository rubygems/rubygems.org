# frozen_string_literal: true

module CompactIndexHelpers
  def build_version(version: 1, **args)
    name = args.fetch(:name, "test_gem")
    number = args.fetch(:number, "1.0")
    common = [
      number,
      args[:platform],
      args.fetch(:checksum, "sum+#{name}+#{number}"),
      args.fetch(:info_checksum, "info+#{name}+#{number}"),
      args[:dependencies],
      args[:ruby_version],
      args[:rubygems_version],
      args[:ruby_abi],
      args[:content_address]
    ]
    if version == 2
      CompactIndex::GemVersionV2.new(*common[0...7], args[:created_at], *common[7..])
    else
      CompactIndex::GemVersion.new(*common)
    end
  end
end
