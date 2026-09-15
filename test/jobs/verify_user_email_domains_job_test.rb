# frozen_string_literal: true

require "test_helper"

class VerifyUserEmailDomainsJobTest < ActiveJob::TestCase
  include StatsD::Instrument::Assertions

  API = VerifyUserEmailDomainsJob::FASTLY_DOMAIN_RESEARCH_API

  setup do
    ENV["FASTLY_API_KEY"] = "test-fastly-key"
    # Default: no MX records, so domains look unowned unless a test overrides it.
    Resolv::DNS.any_instance.stubs(:getresources).returns([])
  end

  teardown do
    ENV["FASTLY_API_KEY"] = nil
  end

  # Runs the block and returns the raw source of the first Datadog event (_e{...}) datagram emitted, if any.
  def captured_event(&)
    capture_statsd_datagrams(&).map(&:source).find { |s| s.start_with?("_e{") }
  end

  # Returns the WebMock stub so tests can assert_requested it.
  def stub_fastly(domain:, status: 200, body: nil)
    body ||= { domain: domain, zone: "com", status: "undelegated inactive", tags: "generic" }.to_json
    stub_request(:get, API).with(query: { domain: domain }).to_return(status: status, body: body)
  end

  context "#perform" do
    should "block a user whose email domain is available and has no MX record" do
      user = create(:user, email: "user@expired-domain.com")
      request = stub_fastly(domain: "expired-domain.com")

      VerifyUserEmailDomainsJob.perform_now

      assert_requested request
      assert_predicate user.reload, :blocked?
    end

    should "query Fastly with the registrable root domain for a subdomain email" do
      user = create(:user, email: "user@mail.corp.expired-domain.com")
      request = stub_fastly(domain: "expired-domain.com")

      VerifyUserEmailDomainsJob.perform_now

      assert_requested request
      assert_predicate user.reload, :blocked?
    end

    should "send the Fastly-Key header on requests" do
      create(:user, email: "user@expired-domain.com")
      request = stub_request(:get, API)
        .with(query: { domain: "expired-domain.com" }, headers: { "Fastly-Key" => "test-fastly-key" })
        .to_return(status: 200, body: { domain: "expired-domain.com", status: "undelegated inactive" }.to_json)

      VerifyUserEmailDomainsJob.perform_now

      assert_requested request
    end

    should "not block a user when the domain status is not available" do
      user = create(:user, email: "user@active-domain.com")
      request = stub_fastly(domain: "active-domain.com",
                            body: { domain: "active-domain.com", zone: "com", status: "active", tags: "generic" }.to_json)

      VerifyUserEmailDomainsJob.perform_now

      assert_requested request
      refute_predicate user.reload, :blocked?
    end

    should "not block a user when the domain still has MX records" do
      user = create(:user, email: "user@has-mail.com")
      Resolv::DNS.any_instance.stubs(:getresources).returns([stub(exchange: "mail.has-mail.com")])
      request = stub_fastly(domain: "has-mail.com")

      VerifyUserEmailDomainsJob.perform_now

      assert_requested request
      refute_predicate user.reload, :blocked?
    end

    should "not block a user when MX resolution raises (defer to manual review)" do
      user = create(:user, email: "user@dns-error.com")
      Resolv::DNS.any_instance.stubs(:getresources).raises(Resolv::ResolvError)
      stub_fastly(domain: "dns-error.com")

      VerifyUserEmailDomainsJob.perform_now

      refute_predicate user.reload, :blocked?
    end

    should "not block a user when Fastly returns an in-body errors key" do
      user = create(:user, email: "user@error-domain.com")
      request = stub_fastly(domain: "error-domain.com", body: { errors: [title: "bad request"] }.to_json)

      VerifyUserEmailDomainsJob.perform_now

      assert_requested request
      refute_predicate user.reload, :blocked?
    end

    should "not block a user when Fastly returns a non-success status code" do
      user = create(:user, email: "user@api-error-domain.com")
      request = stub_fastly(domain: "api-error-domain.com", status: 500, body: "internal server error")

      VerifyUserEmailDomainsJob.perform_now

      assert_requested request
      refute_predicate user.reload, :blocked?
    end

    should "skip a domain PublicSuffix cannot parse rather than blocking or aborting the run" do
      ok_user = create(:user, email: "user@expired-domain.com")
      bad_user = create(:user, email: "placeholder@expired-domain.com")
      # No Fastly stub for "localhost"; if it weren't skipped the run would error on an unstubbed request.
      bad_user.update_column(:email, "user@localhost")
      stub_fastly(domain: "expired-domain.com")

      VerifyUserEmailDomainsJob.perform_now

      assert_predicate ok_user.reload, :blocked?
      refute_predicate bad_user.reload, :blocked?
    end

    should "process multiple domains in one run, blocking only the available ones" do
      available = create(:user, email: "user@expired-domain.com")
      active = create(:user, email: "user@active-domain.com")
      stub_fastly(domain: "expired-domain.com")
      stub_fastly(domain: "active-domain.com",
                  body: { domain: "active-domain.com", status: "active" }.to_json)

      VerifyUserEmailDomainsJob.perform_now

      assert_predicate available.reload, :blocked?
      refute_predicate active.reload, :blocked?
    end

    should "block all users without double-blocking when subdomains collapse to one root" do
      mail_user = create(:user, email: "user@mail.expired-domain.com")
      smtp_user = create(:user, email: "user@smtp.expired-domain.com")
      stub_fastly(domain: "expired-domain.com")

      # Both subdomains reduce to expired-domain.com; each user must be blocked
      # exactly once, not once per collapsed subdomain.
      assert_statsd_increment("user_email_domains.verify.blocked", times: 2) do
        VerifyUserEmailDomainsJob.perform_now
      end

      assert_predicate mail_user.reload, :blocked?
      assert_predicate smtp_user.reload, :blocked?
    end

    should "block every user at the MAX_AUTO_BLOCK boundary" do
      # The :user factory's email sequence puts every user on the same domain (rubygems-test.org).
      users = create_list(:user, VerifyUserEmailDomainsJob::MAX_AUTO_BLOCK)
      stub_fastly(domain: "rubygems-test.org")

      VerifyUserEmailDomainsJob.perform_now

      assert users.all? { |u| u.reload.blocked? }, "expected all users at the boundary to be blocked"
    end

    should "block no one and defer to manual review above MAX_AUTO_BLOCK" do
      users = create_list(:user, VerifyUserEmailDomainsJob::MAX_AUTO_BLOCK + 1)
      stub_fastly(domain: "rubygems-test.org")

      VerifyUserEmailDomainsJob.perform_now

      assert users.none? { |u| u.reload.blocked? }, "expected the safety valve to block no one above the threshold"
    end

    should "emit a Datadog event summarising the accounts blocked" do
      create(:user, email: "user@expired-domain.com")
      stub_fastly(domain: "expired-domain.com")

      event = captured_event { VerifyUserEmailDomainsJob.perform_now }

      assert event, "expected a Datadog event datagram to be emitted"
      assert_includes event, "Blocked 1 account(s) across 1 expired domain(s)"
      assert_includes event, "t:warning"
      assert_includes event, "blocked:1"
      assert_includes event, "domains:1"
    end

    should "emit an event noting deferral when over the auto-block limit" do
      create_list(:user, VerifyUserEmailDomainsJob::MAX_AUTO_BLOCK + 1)
      stub_fastly(domain: "rubygems-test.org")

      event = captured_event { VerifyUserEmailDomainsJob.perform_now }

      assert_includes event, "deferred for manual review"
      assert_includes event, "blocked:0"
      assert_includes event, "deferred:#{VerifyUserEmailDomainsJob::MAX_AUTO_BLOCK + 1}"
    end

    should "emit an info event when nothing is blocked" do
      create(:user, email: "user@active-domain.com")
      stub_fastly(domain: "active-domain.com",
                  body: { domain: "active-domain.com", status: "active" }.to_json)

      event = captured_event { VerifyUserEmailDomainsJob.perform_now }

      assert_includes event, "Blocked 0 account(s)"
      assert_includes event, "t:info"
    end

    should "raise when FASTLY_API_KEY is not configured" do
      ENV["FASTLY_API_KEY"] = nil
      create(:user, email: "user@expired-domain.com")

      assert_raises(RuntimeError) { VerifyUserEmailDomainsJob.new.perform }
    end

    should "raise when every domain check fails so a total outage is not a silent no-op" do
      user = create(:user, email: "user@expired-domain.com")
      stub_request(:get, API).with(query: { domain: "expired-domain.com" }).to_timeout

      assert_raises(RuntimeError) { VerifyUserEmailDomainsJob.new.perform }
      refute_predicate user.reload, :blocked?
    end
  end
end
