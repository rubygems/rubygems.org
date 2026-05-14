# frozen_string_literal: true

require "test_helper"

class SyncDisposableEmailDomainsJobTest < ActiveJob::TestCase
  include StatsD::Instrument::Assertions

  def stub_upstream(blocklist:, allowlist: "")
    stub_request(:get, SyncDisposableEmailDomainsJob::BLOCKLIST_URL)
      .to_return(status: 200, body: blocklist)
    stub_request(:get, SyncDisposableEmailDomainsJob::ALLOWLIST_URL)
      .to_return(status: 200, body: allowlist)
  end

  context "#perform" do
    should "insert upstream domains" do
      stub_upstream(blocklist: "mailinator.com\nguerrillamail.com\n")

      assert_difference -> { BlockedEmailDomain.upstream.count }, 2 do
        SyncDisposableEmailDomainsJob.perform_now
      end
    end

    should "exclude domains present on the upstream allowlist" do
      stub_upstream(
        blocklist: "mailinator.com\nlegitimate.com\n",
        allowlist: "legitimate.com\n"
      )
      SyncDisposableEmailDomainsJob.perform_now

      assert BlockedEmailDomain.exists?(domain: "mailinator.com")
      refute BlockedEmailDomain.exists?(domain: "legitimate.com")
    end

    should "strip comments and blank lines" do
      stub_upstream(blocklist: "# comment\nmailinator.com  # trailing comment\n\nguerrillamail.com\n")
      SyncDisposableEmailDomainsJob.perform_now

      assert_equal %w[guerrillamail.com mailinator.com], BlockedEmailDomain.upstream.order(:domain).pluck(:domain)
    end

    should "be idempotent across runs" do
      stub_upstream(blocklist: "mailinator.com\n")
      SyncDisposableEmailDomainsJob.perform_now
      SyncDisposableEmailDomainsJob.perform_now

      assert_equal 1, BlockedEmailDomain.upstream.where(domain: "mailinator.com").count
    end

    should "delete upstream rows that disappear from upstream" do
      create(:blocked_email_domain, :upstream, domain: "old.example.test-domain.io")
      stub_upstream(blocklist: "mailinator.com\n")

      SyncDisposableEmailDomainsJob.perform_now

      refute BlockedEmailDomain.exists?(domain: "old.example.test-domain.io")
      assert BlockedEmailDomain.exists?(domain: "mailinator.com", source: BlockedEmailDomain.sources[:upstream])
    end

    should "never touch manual rows" do
      manual = create(:blocked_email_domain, domain: "ops-discovered.example.test-domain.io")
      stub_upstream(blocklist: "mailinator.com\n")

      SyncDisposableEmailDomainsJob.perform_now

      assert BlockedEmailDomain.exists?(id: manual.id, source: BlockedEmailDomain.sources[:manual])
    end

    should "emit success metric and counts" do
      stub_upstream(blocklist: "mailinator.com\n")

      metrics = capture_statsd_calls(client: StatsD.singleton_client) do
        SyncDisposableEmailDomainsJob.perform_now
      end
      names = metrics.map(&:name)

      assert_includes names, "disposable_email_domains.sync.success"
      assert_includes names, "disposable_email_domains.count"
      assert_includes names, "disposable_email_domains.upstream.count"
    end

    should "emit error metric on upstream failure" do
      stub_request(:get, SyncDisposableEmailDomainsJob::BLOCKLIST_URL).to_return(status: 500)

      metrics = capture_statsd_calls(client: StatsD.singleton_client) do
        # retry_on in ApplicationJob converts the raise into a retry; perform_now
        # returns the exception rather than raising. We only care that the error
        # metric was emitted.
        SyncDisposableEmailDomainsJob.perform_now
      end

      assert(metrics.any? { |m| m.name == "disposable_email_domains.sync.error" })
    end
  end
end
