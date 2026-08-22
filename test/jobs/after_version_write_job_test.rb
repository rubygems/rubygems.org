# frozen_string_literal: true

require "test_helper"

class AfterVersionWriteJobTest < ActiveJob::TestCase
  setup do
    @rubygem = create(:rubygem, name: "test-gem")
    @version = create(:version, rubygem: @rubygem, indexed: false)
  end

  should "enqueue reorder versions job after indexing the version" do
    assert_enqueued_with(job: ReorderVersionsJob, args: [rubygem: @rubygem]) do
      AfterVersionWriteJob.perform_now(version: @version)
    end
  end
end
