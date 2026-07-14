require "test_helper"

class TransparencyLog::ConfigurationTest < ActiveSupport::TestCase
    setup do
        @config = TransparencyLog::Configuration.new
    end

    test "#rekor_url" do
        @config.rekor_url = "https://example.com"
        assert_equal @config.rekor_url, "https://example.com"
    end

    test "#private_key" do
        @config.private_key = "my_private_key"
        assert_equal @config.private_key, "my_private_key"
    end
end