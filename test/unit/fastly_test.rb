require 'test_helper'

class FastlyTest < ActiveSupport::TestCase
  setup do
    ENV['FASTLY_DOMAINS'] = "domain1.example.com,domain2.example.com"
  end

  teardown do
    ENV['FASTLY_DOMAINS'] = nil
  end

  context ".purge" do
    should "purge for each domain" do
      RestClient::Request.expects(:execute).times(2).returns("{}")
      Fastly.purge("some-url")
    end
  end
end
