# frozen_string_literal: true

class Advisory < ApplicationRecord
  belongs_to :rubygem, primary_key: :name, foreign_key: :rubygem_name, optional: true, inverse_of: :advisories

  attribute :payload, :jsonb
  attribute :ranges, :jsonb

  validates :type, :identifier, :rubygem_name, :summary, :url, :modified_at, presence: true
  validates :identifier, uniqueness: { scope: %i[type rubygem_name] }

  scope :current, -> { where(withdrawn_at: nil) }
  scope :visible, lambda {
    types = enabled_sources.map(&:sti_name)
    types.empty? ? none : current.where(type: types)
  }

  SOURCES = [OSV].freeze

  class << self
    def feature_flag
      raise NotImplementedError, "#{name} must define .feature_flag"
    end

    def enabled?
      FeatureFlag.enabled?(feature_flag)
    end

    def enabled_sources
      SOURCES.select(&:enabled?)
    end
  end

  def affects?(version)
    gem_version = to_gem_version(version)
    return false if gem_version.nil? || ranges.blank?

    ranges.any? { |range| range_includes?(range, gem_version) }
  end

  private

  def to_gem_version(version)
    number = version.respond_to?(:number) ? version.number : version
    Gem::Version.new(number.to_s)
  rescue ArgumentError
    nil
  end

  def range_includes?(_range, _gem_version)
    raise NotImplementedError, "#{self.class} must implement #range_includes?"
  end
end
