# frozen_string_literal: true

module CompactIndex
  class GemVersionV4 < BaseGemVersion
    define_schema :number, :platform, :checksum, :info_checksum, :dependencies, :ruby_version, :rubygems_version, :created_at, :size, :rust_version
  end
end
