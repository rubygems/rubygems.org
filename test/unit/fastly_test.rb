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
      stub_request(:purge, "https://domain1.example.com/some-url")
        .with(headers: { "Fastly-Key" => "api-key" })
        .to_return(status: 200, body: "{}")
      stub_request(:purge, "https://domain2.example.com/some-url")
        .with(headers: { "Fastly-Key" => "api-key" })
        .to_return(status: 200, body: "{}")

      assert Fastly.purge(path: "some-url")
    end

    should "soft purge for each domain" do
      stub_request(:purge, "https://domain1.example.com/some-url")
        .with(headers: { "Fastly-Key" => "api-key", "Fastly-Soft-Purge" => "1" })
        .to_return(status: 200, body: "{}")
      stub_request(:purge, "https://domain2.example.com/some-url")
        .with(headers: { "Fastly-Key" => "api-key", "Fastly-Soft-Purge" => "1" })
        .to_return(status: 200, body: "{}")

      assert Fastly.purge(path: "some-url", soft: true)
    end
  end

  context ".purge_key" do
    should "send a post request" do
      stub_request(:post, "https://api.fastly.com/service/service-id/purge/some-key")
        .with(headers: { "Fastly-Key" => "api-key" })
        .to_return(status: 200, body: "{}")

      assert Fastly.purge_key("some-key")
    end
    should "send a post request for soft purges" do
      stub_request(:post, "https://api.fastly.com/service/service-id/purge/some-key")
        .with(headers: { "Fastly-Key" => "api-key", "Fastly-Soft-Purge" => "1" })
        .to_return(status: 200, body: "{}")

      assert Fastly.purge_key("some-key", soft: true)
    end
  end
end
