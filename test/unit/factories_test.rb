# frozen_string_literal: true

require "test_helper"

class FactoriesTest < ActiveSupport::TestCase
  BUILD_ONLY_FACTORIES = %i[transparency_log_event].freeze

  test "can create factories including traits" do
    FactoryBot.lint(
      FactoryBot.factories.reject { |factory| BUILD_ONLY_FACTORIES.include?(factory.name) },
      traits: true
    )
  end

  test "can build build-only factories including traits" do
    factories = FactoryBot.factories.select { |factory| BUILD_ONLY_FACTORIES.include?(factory.name) }

    FactoryBot.lint(factories, traits: true, strategy: :build)
  end
end
