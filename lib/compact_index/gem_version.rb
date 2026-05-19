# frozen_string_literal: true

module CompactIndex
  class BaseGemVersion
    include Comparable

    # Structural fields have custom rendering in to_line.
    # Any field not in this set is auto-appended as ",field:value".
    STRUCTURAL_FIELDS = %i[number platform checksum info_checksum dependencies ruby_version rubygems_version].freeze

    class << self
      attr_reader :fields, :appendable_fields

      def define_schema(*all_fields)
        @fields = all_fields.freeze
        @appendable_fields = (all_fields - STRUCTURAL_FIELDS).freeze
        attr_accessor(*all_fields)
      end
    end

    def initialize(*args)
      self.class.fields.each_with_index do |field, i|
        instance_variable_set(:"@#{field}", args[i])
      end
    end

    def number_and_platform
      if platform.nil? || platform == "ruby"
        number
      else
        "#{number}-#{platform}"
      end
    end

    def <=>(other)
      number_comp = number <=> other.number

      if number_comp.zero?
        [number, platform].compact <=> [other.number, other.platform].compact
      else
        number_comp
      end
    end

    def to_line
      line = +"#{number_and_platform} #{deps_line}|checksum:#{checksum}"
      line << ",ruby:#{ruby_version_line}" if ruby_version && ruby_version != ">= 0"
      line << ",rubygems:#{rubygems_version_line}" if rubygems_version && rubygems_version != ">= 0"
      self.class.appendable_fields.each do |field|
        value = public_send(field)
        line << ",#{field}:#{value}" if value
      end
      line
    end

    private

    def ruby_version_line
      join_multiple(ruby_version)
    end

    def rubygems_version_line
      join_multiple(rubygems_version)
    end

    def deps_line
      return "" if dependencies.nil?

      dependencies.map do |d|
        [d[:gem], join_multiple(d.version_and_platform)].join(":")
      end.join(",")
    end

    def join_multiple(requirements)
      requirements = requirements.split(", ")
      requirements.sort!
      requirements.join("&")
    end
  end

  # V1: original compact index format
  class GemVersion < BaseGemVersion
    define_schema :number, :platform, :checksum, :info_checksum,
                  :dependencies, :ruby_version, :rubygems_version
  end

  # V2: adds created_at
  class GemVersionV2 < BaseGemVersion
    define_schema :number, :platform, :checksum, :info_checksum,
                  :dependencies, :ruby_version, :rubygems_version,
                  :created_at
  end

  # V3: adds created_at + size
  class GemVersionV3 < BaseGemVersion
    define_schema :number, :platform, :checksum, :info_checksum,
                  :dependencies, :ruby_version, :rubygems_version,
                  :created_at, :size
  end
end
