# frozen_string_literal: true

require "test_helper"
require "helpers/fake_dns_helpers"

class OrganizationDomainVerificationJobTest < ActiveJob::TestCase
  include FakeDnsHelpers

  TXT = Resolv::DNS::Resource::IN::TXT

  setup do
    @domain = create(:organization_domain, domain: "example.com", check_queued_at: Time.current)
    @name = "_rubygems-challenge.example.com."
  end

  def run_job(answers = {})
    @resolver = stub_dns(FakeDnsResolver.new(answers))
    OrganizationDomainVerificationJob.perform_now(@domain.id)
  end

  def check
    @domain.checks.sole
  end

  def queued_at
    @domain.reload.check_queued_at
  end

  test "matched: records a success, verifies the domain and clears check_queued_at" do
    run_job({ [@name, TXT] => [TXT.new(@domain.txt_record_value)] })

    assert_equal %w[success matched], [check.result, check.outcome]
    assert_predicate @domain.reload, :verified?
    assert_nil queued_at
  end

  test "matches multi-string, whitespace-padded and one-of-several values" do
    value = @domain.txt_record_value
    run_job({ [@name, TXT] => [TXT.new("junk"), TXT.new(" #{value[0, 8]}", "#{value[8..]} ")] })

    assert_equal "matched", check.outcome
  end

  test "record_not_found" do
    run_job

    assert_equal %w[failure record_not_found], [check.result, check.outcome]
    assert_nil queued_at
    refute_predicate @domain, :verified?
  end

  test "record_mismatch" do
    run_job({ [@name, TXT] => [TXT.new("wrong")] })

    assert_equal %w[failure record_mismatch], [check.result, check.outcome]
    refute_includes check.message, "wrong"
    assert_nil queued_at
  end

  test "timeout records other_error without waiting" do
    run_job({ [@name, TXT] => Timeout::Error })

    assert_equal %w[failure other_error], [check.result, check.outcome]
    assert_equal "DNS lookup timed out after 30 seconds.", check.message
    assert_nil queued_at
  end

  test "any other exception records other_error and is reported" do
    Rails.error.expects(:report).with { |e, opts| e.is_a?(SocketError) && opts == { handled: true } }
    run_job({ [@name, TXT] => SocketError.new("boom") })

    assert_equal %w[failure other_error], [check.result, check.outcome]
    assert_equal "SocketError: boom", check.message
    assert_nil queued_at
  end

  test "already verified by another organization is a failure" do
    create(:organization_domain, :verified, domain: "example.com")
    run_job({ [@name, TXT] => [TXT.new(@domain.txt_record_value)] })

    assert_equal %w[failure other_error], [check.result, check.outcome]
    assert_equal "Another organization has already verified this domain.", check.message
    refute_predicate @domain.reload, :verified?
    assert_nil queued_at
  end

  test "a domain removed before the job runs is a silent no-op" do
    @domain.remove!(actor: create(:user))
    resolver = stub_dns(FakeDnsResolver.new)

    assert_no_difference "OrganizationDomainCheck.count" do
      Rails.error.expects(:report).never
      OrganizationDomainVerificationJob.perform_now(@domain.id)
    end
    assert_empty resolver.queries
  end

  test "a domain removed during the lookup records nothing and does not raise" do
    id = @domain.id
    actor = create(:user)
    resolver = stub_dns(FakeDnsResolver.new)
    resolver.define_singleton_method(:getresources) do |*|
      OrganizationDomain.find(id).remove!(actor:)
      []
    end

    assert_no_difference "OrganizationDomainCheck.count" do
      OrganizationDomainVerificationJob.perform_now(id)
    end
  end

  test "an unexpected error is caught: the job succeeds and records the failure" do
    OrganizationDomain.any_instance.stubs(:verify!).raises(ActiveRecord::StatementInvalid, "boom")
    Rails.error.expects(:report).with { |e, opts| e.is_a?(ActiveRecord::StatementInvalid) && opts == { handled: true } }

    assert_no_enqueued_jobs only: OrganizationDomainVerificationJob do
      assert_nothing_raised { OrganizationDomainVerificationJob.perform_now(@domain.id) }
    end

    assert_equal %w[failure other_error], [check.result, check.outcome]
    assert_equal "ActiveRecord::StatementInvalid: boom", check.message
    assert_nil queued_at
  end

  test "if recording the failure also fails, the job still succeeds and clears check_queued_at" do
    OrganizationDomain.any_instance.stubs(:verify!).raises(RuntimeError, "boom")
    OrganizationDomain.any_instance.stubs(:record_check!).raises(ActiveRecord::StatementInvalid, "db down")
    Rails.error.expects(:report).twice

    assert_no_enqueued_jobs only: OrganizationDomainVerificationJob do
      assert_nothing_raised { OrganizationDomainVerificationJob.perform_now(@domain.id) }
    end

    assert_empty @domain.checks
    assert_nil queued_at
  end

  test "adds no error handlers of its own beyond GoodJob's concurrency retry" do
    own = OrganizationDomainVerificationJob.rescue_handlers.map(&:first) - ApplicationJob.rescue_handlers.map(&:first)

    assert_equal ["GoodJob::ActiveJobExtensions::Concurrency::ConcurrencyExceededError"], own.uniq
  end

  test "an error from the DNS work is not retried: one run records one check" do
    resolver = stub_dns(FakeDnsResolver.new({ [@name, TXT] => RuntimeError.new("flaky") }))

    assert_difference -> { @domain.checks.count }, 1 do
      perform_enqueued_jobs { OrganizationDomainVerificationJob.perform_later(@domain.id) }
    end
    assert_equal 1, resolver.queries.size
    assert_no_enqueued_jobs
  end

  test "concurrency key is per domain and limits queued and running jobs to one" do
    job = OrganizationDomainVerificationJob.new(@domain.id)
    other = OrganizationDomainVerificationJob.new(@domain.id + 1)

    assert_equal "OrganizationDomainVerificationJob-#{@domain.id}", job.good_job_concurrency_key
    refute_equal job.good_job_concurrency_key, other.good_job_concurrency_key
    config = OrganizationDomainVerificationJob.good_job_concurrency_config

    assert_equal 1, config[:enqueue_limit]
    assert_equal 1, config[:perform_limit]
  end

  test "a second enqueue for the same domain while one is queued does not duplicate" do
    adapter = GoodJob::Adapter.new(execution_mode: :external)
    OrganizationDomainVerificationJob.stubs(:queue_adapter).returns(adapter)

    assert_difference -> { GoodJob::Job.where(job_class: "OrganizationDomainVerificationJob").count }, 1 do
      OrganizationDomainVerificationJob.perform_later(@domain.id)
      OrganizationDomainVerificationJob.perform_later(@domain.id)
    end
    assert_difference -> { GoodJob::Job.where(job_class: "OrganizationDomainVerificationJob").count }, 1 do
      OrganizationDomainVerificationJob.perform_later(@domain.id + 1)
    end
  end

  test "a ConcurrencyExceededError raised before perform (as GoodJob does) is retried, not recorded" do
    job = OrganizationDomainVerificationJob.new(@domain.id)
    job.stubs(:perform).raises(GoodJob::ActiveJobExtensions::Concurrency::ConcurrencyExceededError)
    Rails.error.expects(:report).never

    assert_enqueued_jobs 1, only: OrganizationDomainVerificationJob do
      job.perform_now
    end
    assert_empty @domain.checks
    refute_nil queued_at
  end
end
