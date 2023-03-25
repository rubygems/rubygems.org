require "test_helper"

class HookRelayReportJobTest < ActiveJob::TestCase
  setup do
    @webhook = create(:web_hook)
  end

  test "discards on unknown status" do
    assert_nothing_raised do
      HookRelayReportJob.perform_now({ status: "unknown", stream: ":webhook_id-#{@webhook.id}", completed_at: "2020-01-01" })
    end
  end

  test "discards on malformed stream" do
    assert_nothing_raised do
      HookRelayReportJob.perform_now({ status: "unknown", stream: ":webhook_idZZZ-#{@webhook.id}", completed_at: "2020-01-01" })
    end
  end

  test "calls success!" do
    completed_at = 1.minute.ago

    assert_difference -> { @webhook.reload.successes_since_last_failure } do
      HookRelayReportJob.perform_now(
        { status: "success", stream: ":webhook_id-#{@webhook.id}", completed_at: completed_at.as_json }
      )
    end
  end

  test "calls failure!" do
    completed_at = 1.minute.ago

    assert_difference -> { @webhook.reload.failures_since_last_success } do
      HookRelayReportJob.perform_now(
        { status: "failure", stream: ":webhook_id-#{@webhook.id}", completed_at: completed_at.as_json }
      )
    end
  end
end
