require "test_helper"

class Rstuf::ApplicationJobTest < ActiveJob::TestCase
  class MockJob < Rstuf::ApplicationJob
    def perform
      # no-op
    end
  end

  setup do
    setup_rstuf
  end

  test "job is not performed if Rstuf is disabled" do
    Rstuf.enabled = false
    assert_no_enqueued_jobs only: MockJob do
      MockJob.perform_later
    end
  end

  test "job is performed if Rstuf is enabled" do
    Rstuf.enabled = true
    assert_enqueued_jobs 1, only: MockJob do
      MockJob.perform_later
    end
  end

  teardown do
    teardown_rstuf
  end
end
