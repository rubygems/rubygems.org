# frozen_string_literal: true

module CompactIndex
  class GemVersion
    include Comparable

    # Base fields that all versions share. These have special rendering in InfoFile.
    # Anything beyond these gets auto-appended as "key:value" by InfoFile.
    #
    # When rolling up (retiring the old version), move the old version's
    # extra fields into BASE_FIELDS here, then delete the old version directory.
    BASE_FIELDS = %i[number platform checksum info_checksum
                     dependencies ruby_version rubygems_version].freeze

    def self.fields
      if instance_variable_defined?(:@fields)
        @fields
      else
        BASE_FIELDS
      end
    end

    # Declares additional fields beyond BASE_FIELDS for this version.
    def self.attribute(*extra_fields)
      @fields = (BASE_FIELDS + extra_fields).freeze
      attr_reader(*extra_fields)
    end

    attr_reader(*BASE_FIELDS)

    def initialize(*args)
      self.class.fields.each_with_index do |field, i|
        instance_variable_set(:"@#{field}", args[i])
      end
    end

    def [](key)
      send(key)
    end

    def []=(key, value)
      instance_variable_set(:"@#{key}", value)
    end

    def ==(other)
      self.class == other.class && self.class.fields.all? { |f| send(f) == other.send(f) }
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
  end
end
