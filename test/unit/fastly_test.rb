require "test_helper"

class FastlyTest < ActiveSupport::TestCase
  setup do
    ENV["FASTLY_DOMAINS"] = "domain1.example.com,domain2.example.com"
    ENV["FASTLY_SERVICE_ID"] = "service-id"
    ENV["FASTLY_API_KEY"] = "api-key"
  end

  teardown do
    ENV["FASTLY_DOMAINS"] = nil
    ENV["FASTLY_SERVICE_ID"] = nil
    ENV["FASTLY_API_KEY"] = nil
  end

  context ".purge" do
    should "purge for each domain" do
      RestClient::Request.expects(:execute).times(2).returns("{}")
      Fastly.purge(path: "some-url")
    end
  end

  context ".purge_key" do
    should "send a post request" do
      params = {
        method: :post,
        url: "https://api.fastly.com/service/service-id/purge/some-key",
        timeout: 10,
        headers: { "Fastly-Key" => "api-key" }
      }
      RestClient::Request.expects(:execute).with(params).returns("{}")
      Fastly.purge_key("some-key")
    end
  end
end
