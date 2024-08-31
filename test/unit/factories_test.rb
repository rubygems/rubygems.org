require "test_helper"

class FactoriesTest < ActiveSupport::TestCase
  test "can create factories including traits" do
    assert_nothing_raised { FactoryBot.lint(traits: true) }
  end
end
