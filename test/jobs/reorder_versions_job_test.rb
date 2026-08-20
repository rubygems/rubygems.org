# frozen_string_literal: true

require "test_helper"

class ReorderVersionsJobTest < ActiveJob::TestCase
  setup do
    @rubygem = create(:rubygem, name: "test-gem")
    @user = create(:user)
  end

  context "reordering versions" do
    should "reorder versions, set the latest flag, and record the success metric" do
      v3 = create(:version, rubygem: @rubygem, number: "3.0.0", indexed: true)
      v1 = create(:version, rubygem: @rubygem, number: "1.0.0", indexed: true)
      v2 = create(:version, rubygem: @rubygem, number: "2.0.0", indexed: true)

      StatsD.stubs(:increment)
      StatsD.stubs(:measure)
      StatsD.expects(:increment).with("reorder_versions.success")
      StatsD.expects(:measure).with("reorder_versions.duration").yields

      assert_enqueued_with(job: Indexer) do
        ReorderVersionsJob.new.perform(rubygem: @rubygem)
      end

      assert_equal 0, v3.reload.position
      assert_equal 1, v2.reload.position
      assert_equal 2, v1.reload.position

      refute v1.reload.latest
      refute v2.reload.latest
      assert v3.reload.latest
    end

    should "run reorder inside a transaction" do
      create(:version, rubygem: @rubygem, number: "1.0.0", indexed: true)

      @rubygem.expects(:transaction).yields
      StatsD.stubs(:increment)
      StatsD.stubs(:measure).with("reorder_versions.duration").yields
      GemCachePurger.stubs(:call)
      Indexer.stubs(:perform_later)
      SetLinksetHomeJob.stubs(:perform_later)

      assert_nothing_raised do
        ReorderVersionsJob.new.perform(rubygem: @rubygem)
      end
    end

    should "discard job if rubygem no longer exists" do
      ReorderVersionsJob.perform_later(rubygem: @rubygem)
      @rubygem.destroy

      StatsD.stubs(:measure)
      StatsD.stubs(:histogram)
      StatsD.stubs(:increment)
      StatsD.expects(:increment).with(
        "good_job.discarded",
        tags: has_entries(
          queue: "default",
          job_class: "ReorderVersionsJob",
          exception: "ActiveJob::DeserializationError",
          adapter: "ActiveJob::QueueAdapters::TestAdapter"
        )
      ).once

      assert_nothing_raised do
        perform_enqueued_jobs(only: ReorderVersionsJob)
      end
    end
  end
end
