# frozen_string_literal: true

require "test_helper"

class SyncDisposableEmailDomainsJobTest < ActiveJob::TestCase
  include StatsD::Instrument::Assertions

  # Build a blocklist that comfortably clears MIN_EXPECTED_DOMAINS so the
  # poisoned-upstream tripwire doesn't fire for the happy-path tests.
  def realistic_blocklist(extra: [])
    base = Array.new(SyncDisposableEmailDomainsJob::MIN_EXPECTED_DOMAINS + 50) { |i| "disposable-#{i}.example.test-domain.io" }
    "#{(base + extra).join("\n")}\n"
  end

  def stub_upstream(blocklist:)
    stub_request(:get, SyncDisposableEmailDomainsJob::BLOCKLIST_URL)
      .to_return(status: 200, body: blocklist)
  end

  context "#perform" do
    should "insert upstream domains" do
      stub_upstream(blocklist: realistic_blocklist(extra: %w[mailinator.com guerrillamail.com]))
      SyncDisposableEmailDomainsJob.perform_now

      assert BlockedEmailDomain.exists?(domain: "mailinator.com", source: BlockedEmailDomain.sources[:upstream])
      assert BlockedEmailDomain.exists?(domain: "guerrillamail.com")
    end

    should "skip blank lines" do
      blocklist = "\nmailinator.com\n\nguerrillamail.com\n#{realistic_blocklist}"
      stub_upstream(blocklist: blocklist)
      SyncDisposableEmailDomainsJob.perform_now

      assert BlockedEmailDomain.exists?(domain: "mailinator.com")
      assert BlockedEmailDomain.exists?(domain: "guerrillamail.com")
    end

    should "drop domains that fail the format regex" do
      stub_upstream(blocklist: realistic_blocklist(extra: %w[mailinator.com not_a_domain trailing-dot. .leading-dot]))
      SyncDisposableEmailDomainsJob.perform_now

      assert BlockedEmailDomain.exists?(domain: "mailinator.com")
      refute BlockedEmailDomain.exists?(domain: "not_a_domain")
      refute BlockedEmailDomain.exists?(domain: "trailing-dot.")
      refute BlockedEmailDomain.exists?(domain: ".leading-dot")
    end

    should "drop public-suffix entries so a poisoned upstream cannot lock out a whole ccTLD" do
      stub_upstream(blocklist: realistic_blocklist(extra: %w[mailinator.com co.uk com.br]))
      SyncDisposableEmailDomainsJob.perform_now

      assert BlockedEmailDomain.exists?(domain: "mailinator.com")
      refute BlockedEmailDomain.exists?(domain: "co.uk")
      refute BlockedEmailDomain.exists?(domain: "com.br")
    end

    should "be idempotent across runs" do
      stub_upstream(blocklist: realistic_blocklist(extra: %w[mailinator.com]))
      SyncDisposableEmailDomainsJob.perform_now
      SyncDisposableEmailDomainsJob.perform_now

      assert_equal 1, BlockedEmailDomain.upstream.where(domain: "mailinator.com").count
    end

    should "delete upstream rows that disappear from upstream" do
      create(:blocked_email_domain, :upstream, domain: "old.example.test-domain.io")
      stub_upstream(blocklist: realistic_blocklist(extra: %w[mailinator.com]))

      SyncDisposableEmailDomainsJob.perform_now

      refute BlockedEmailDomain.exists?(domain: "old.example.test-domain.io")
      assert BlockedEmailDomain.exists?(domain: "mailinator.com", source: BlockedEmailDomain.sources[:upstream])
    end

    should "never touch manual rows" do
      manual = create(:blocked_email_domain, domain: "ops-discovered.example.test-domain.io")
      stub_upstream(blocklist: realistic_blocklist(extra: %w[mailinator.com]))

      SyncDisposableEmailDomainsJob.perform_now

      assert BlockedEmailDomain.exists?(id: manual.id, source: BlockedEmailDomain.sources[:manual])
    end

    should "preserve source on rows admins have promoted to manual" do
      # An admin promotes an upstream-listed row to :manual to annotate it.
      # The sync should refresh updated_at but NOT reset source back to :upstream.
      create(:blocked_email_domain, domain: "mailinator.com", source: :manual, notes: "ops note")
      stub_upstream(blocklist: realistic_blocklist(extra: %w[mailinator.com]))

      SyncDisposableEmailDomainsJob.perform_now

      row = BlockedEmailDomain.find_by!(domain: "mailinator.com")

      assert_predicate row, :manual?
      assert_equal "ops note", row.notes
    end

    should "emit success metric and counts" do
      stub_upstream(blocklist: realistic_blocklist(extra: %w[mailinator.com]))

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
        # does not re-raise on the first failure. We only care that the error
        # metric was emitted.
        SyncDisposableEmailDomainsJob.perform_now
      end

      assert(metrics.any? { |m| m.name == "disposable_email_domains.sync.error" })
    end

    should "abort and leave DB untouched when blocklist is suspiciously small" do
      create(:blocked_email_domain, :upstream, domain: "existing.example.test-domain.io")
      stub_upstream(blocklist: "mailinator.com\nguerrillamail.com\n")

      SyncDisposableEmailDomainsJob.perform_now

      assert BlockedEmailDomain.exists?(domain: "existing.example.test-domain.io"),
        "existing upstream rows should not be deleted when sync aborts"
    end

    should "abort and leave DB untouched when blocklist is suspiciously large" do
      create(:blocked_email_domain, :upstream, domain: "existing.example.test-domain.io")
      oversized = Array.new(SyncDisposableEmailDomainsJob::MAX_EXPECTED_DOMAINS + 1) { |i| "oversized-#{i}.example.test-domain.io" }
      stub_upstream(blocklist: "#{oversized.join("\n")}\n")

      metrics = capture_statsd_calls(client: StatsD.singleton_client) do
        SyncDisposableEmailDomainsJob.perform_now
      end

      assert(metrics.any? { |m| m.name == "disposable_email_domains.sync.error" })
      assert BlockedEmailDomain.exists?(domain: "existing.example.test-domain.io"),
        "existing upstream rows should not be deleted when sync aborts"
      refute BlockedEmailDomain.exists?(domain: "oversized-0.example.test-domain.io")
    end

    should "abort when blocklist contains a protected provider" do
      stub_upstream(blocklist: realistic_blocklist(extra: %w[mailinator.com gmail.com]))

      metrics = capture_statsd_calls(client: StatsD.singleton_client) do
        SyncDisposableEmailDomainsJob.perform_now
      end

      assert(metrics.any? { |m| m.name == "disposable_email_domains.sync.error" })
      refute BlockedEmailDomain.exists?(domain: "gmail.com")
      refute BlockedEmailDomain.exists?(domain: "mailinator.com")
    end

    should "refuse to follow any redirect" do
      create(:blocked_email_domain, :upstream, domain: "existing.example.test-domain.io")
      stub_request(:get, SyncDisposableEmailDomainsJob::BLOCKLIST_URL)
        .to_return(status: 302, headers: { "Location" => "https://attacker.example/poisoned_blocklist.conf" })

      metrics = capture_statsd_calls(client: StatsD.singleton_client) do
        SyncDisposableEmailDomainsJob.perform_now
      end

      assert(metrics.any? { |m| m.name == "disposable_email_domains.sync.error" })
      assert BlockedEmailDomain.exists?(domain: "existing.example.test-domain.io"),
        "existing upstream rows should not be deleted when sync aborts on a redirect"
    end
  end
end
