require "test_helper"

# These tests just spot check to make sure config is loaded correctly and the file is not broken or missing
class GemcutterConfigTest < ActiveSupport::TestCase
  context "Gemcutter.config[:host_display]" do
    should "be set for test environment" do
      assert_equal "RubyGems.org", Gemcutter.config[:host_display]
    end

    should "have a setting for each regularly used environment" do
      assert_equal "RubyGems.org", Gemcutter::Application.config_for(:rubygems, env: "development").fetch(:host_display)
      assert_equal "RubyGems.org", Gemcutter::Application.config_for(:rubygems, env: "production").fetch(:host_display)
      assert_equal "RubyGems.org Staging", Gemcutter::Application.config_for(:rubygems, env: "staging").fetch(:host_display)
    end
  end

  context "Gemcutter.config[:host]" do
    should "be set for test environment" do
      assert_equal "localhost", Gemcutter.config[:host]
    end

    should "have a setting for each regularly used environment" do
      assert_equal "localhost", Gemcutter::Application.config_for(:rubygems, env: "development").fetch(:host)
      assert_equal "rubygems.org", Gemcutter::Application.config_for(:rubygems, env: "production").fetch(:host)
      assert_equal "staging.rubygems.org", Gemcutter::Application.config_for(:rubygems, env: "staging").fetch(:host)
    end
  end
end
