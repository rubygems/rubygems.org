require "test_helper"

class FactoriesTest < ActiveSupport::TestCase
  test "can create factories including traits" do
    FactoryBot.lint(traits: true)
  end
end
