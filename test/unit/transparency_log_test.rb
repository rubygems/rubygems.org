# frozen_string_literal: true

require "test_helper"

class TransparencyLogTest < ActiveSupport::TestCase
  test "#configure" do
    TransparencyLog.configure do |config|
      assert_same TransparencyLog.configuration, config
    end
  end
end
