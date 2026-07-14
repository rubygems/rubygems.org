# frozen_string_literal: true

require_relative "./transparency_log/configuration"

module TransparencyLog
  class << self
    attr_accessor :configuration
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration)
  end
end
