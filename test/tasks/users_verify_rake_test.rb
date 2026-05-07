# frozen_string_literal: true

require "test_helper"
require "helpers/rake_task_helper"

class UsersVerifyRakeTest < ActiveSupport::TestCase
  include RakeTaskHelper

  setup do
    ENV["FASTLY_API_KEY"] = "test-fastly-key"
    setup_rake_tasks("users_verify.rake")
    stub_request(:get, ZONEDB_URL).to_return(status: 200, body: "com\n")
    Resolv::DNS.any_instance.stubs(:getresources).returns([])
  end

  teardown do
    ENV["FASTLY_API_KEY"] = nil
  end

  context "domain_available_fastly?" do
    should "return true when status is in AVAILABLE_STATUS and there is no MX record" do
      body = { domain: "example.com", zone: "com", status: "undelegated inactive", tags: "generic" }.to_json

      assert domain_available_fastly?(body, "example.com")
    end

    should "return false when response contains an errors key" do
      body = { errors: [{}] }.to_json

      refute domain_available_fastly?(body, "example.com")
    end

    should "return false when status is not in AVAILABLE_STATUS" do
      body = { domain: "example.com", zone: "com", status: "active", tags: "generic" }.to_json

      refute domain_available_fastly?(body, "example.com")
    end

    should "return false when domain has MX records even if status is available" do
      mx_record = stub(exchange: "mail.example.com")
      Resolv::DNS.any_instance.stubs(:getresources).returns([mx_record])
      body = { domain: "example.com", zone: "com", status: "undelegated inactive", tags: "generic" }.to_json

      refute domain_available_fastly?(body, "example.com")
    end
  end

  context "users:verify_fastly" do
    should "block users whose email domain is available per Fastly" do
      user = create(:user, email: "user@expired-domain.com")

      stub_request(:get, FASTLY_DOMAIN_RESEARCH_API)
        .with(query: { domain: "expired-domain.com" }, headers: { "Fastly-Key" => "test-fastly-key" })
        .to_return(
          status: 200,
          body: {
            domain: "expired-domain.com",
            zone: "com",
            status: "undelegated inactive",
            tags: "generic"
          }.to_json
        )

      capture_io { Rake::Task["users:verify_fastly"].invoke }

      assert_predicate user.reload, :blocked?
    end

    should "not block users when Fastly returns a non-success status code" do
      user = create(:user, email: "user@api-error-domain.com")

      stub_request(:get, FASTLY_DOMAIN_RESEARCH_API)
        .with(query: { domain: "api-error-domain.com" })
        .to_return(status: 500, body: "internal server error")

      capture_io { Rake::Task["users:verify_fastly"].invoke }

      refute_predicate user.reload, :blocked?
    end
  end
end
