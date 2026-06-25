# frozen_string_literal: true

require "test_helper"

class ReorderVersionsJobTest < ActiveJob::TestCase
  setup do
    @rubygem = create(:rubygem, name: "test-gem")
    @user = create(:user)
  end

  context "reordering versions" do
    should "reorder versions correctly" do
      v3 = create(:version, rubygem: @rubygem, number: "3.0.0", indexed: true)
      v1 = create(:version, rubygem: @rubygem, number: "1.0.0", indexed: true)
      v2 = create(:version, rubygem: @rubygem, number: "2.0.0", indexed: true)

      ReorderVersionsJob.new.perform(rubygem: @rubygem)

      assert_equal 0, v3.reload.position
      assert_equal 1, v2.reload.position
      assert_equal 2, v1.reload.position
    end

    should "set latest flag correctly" do
      v1 = create(:version, rubygem: @rubygem, number: "1.0.0", indexed: true)
      v2 = create(:version, rubygem: @rubygem, number: "2.0.0", indexed: true)

      ReorderVersionsJob.new.perform(rubygem: @rubygem)

      refute v1.reload.latest
      assert v2.reload.latest
    end

    should "handle concurrent reorder attempts gracefully" do
      create(:version, rubygem: @rubygem, number: "1.0.0", indexed: true)

      job1 = ReorderVersionsJob.new
      job2 = ReorderVersionsJob.new

      assert_nothing_raised do
        threads = [
          Thread.new do
            ActiveRecord::Base.connection_pool.with_connection do
              job1.perform(rubygem: @rubygem)
            end
          end,
          Thread.new do
            ActiveRecord::Base.connection_pool.with_connection do
              job2.perform(rubygem: @rubygem)
            end
          end
        ]
        threads.each(&:join)
      end

      assert_equal 0, @rubygem.versions.first.reload.position
    end

    should "increment success metric when reorder completes" do
      create(:version, rubygem: @rubygem, number: "1.0.0", indexed: true)

      StatsD.expects(:increment).with("reorder_versions.success", tags: { gem: "test-gem" })
      StatsD.expects(:measure).with("reorder_versions.duration", anything, tags: { gem: "test-gem" })

      ReorderVersionsJob.new.perform(rubygem: @rubygem)
    end

    should "handle errors and increment error metric" do
      create(:version, rubygem: @rubygem, number: "1.0.0", indexed: true)

      @rubygem.stubs(:reorder_versions).raises(StandardError.new("Test error"))

      StatsD.expects(:increment).with("reorder_versions.error", tags: { gem: "test-gem", error: "StandardError" })

      assert_raises(StandardError) do
        ReorderVersionsJob.new.perform(rubygem: @rubygem)
      end
    end

    should "discard job if rubygem no longer exists" do
      rubygem_id = @rubygem.id
      @rubygem.destroy

      assert_nothing_raised do
        ReorderVersionsJob.perform_now(rubygem: Rubygem.find(rubygem_id))
      rescue ActiveRecord::RecordNotFound, ActiveJob::DeserializationError => e
        Rails.logger.info "Job discarded as expected: #{e.class}"
      end
    end
  end
end
