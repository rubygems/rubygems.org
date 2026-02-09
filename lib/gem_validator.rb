# frozen_string_literal: true

module GemValidator
  # Base exception class for all GemValidator errors
  class Error < StandardError; end

  def self.spec_validator
    @spec_validator ||= YAMLSchema::Validator.new(NodeInfo).freeze
  end
end
