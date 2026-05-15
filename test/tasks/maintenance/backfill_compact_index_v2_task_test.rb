# frozen_string_literal: true

require "test_helper"

class Maintenance::BackfillCompactIndexV2TaskTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  context "#collection" do
    should "return rubygems with versions between min_rubygem_id and max_rubygem_id" do
      gem1 = create(:rubygem)
      gem2 = create(:rubygem)
      gem3 = create(:rubygem)
      create(:version, rubygem: gem1)
      create(:version, rubygem: gem2)
      create(:version, rubygem: gem3)

      task = Maintenance::BackfillCompactIndexV2Task.new
      task.min_rubygem_id = gem1.id
      task.max_rubygem_id = gem2.id

      assert_equal [gem1, gem2], task.collection.to_a
    end
  end

  context "#process" do
    context "with an indexed last version" do
      should "backfill info_checksum_v2 on the most recent version and enqueue UploadInfoFileJob" do
        rubygem = create(:rubygem, name: "testgem")
        version = create(:version, rubygem: rubygem, number: "1.0.0", indexed: true, info_checksum_v2: nil)
        version2 = create(:version, rubygem: rubygem, number: "1.0.1", indexed: true, info_checksum_v2: nil)

        task = Maintenance::BackfillCompactIndexV2Task.new
        task.process(rubygem)

        assert_not_nil version2.reload.info_checksum_v2
        assert_nil version.reload.info_checksum_v2
        assert_enqueued_with(job: UploadInfoFileJob, args: [rubygem_name: "testgem"])
      end
    end

    context "with a yanked last version" do
      should "backfill yanked_info_checksum_v2 on the most recent version and enqueue UploadInfoFileJob" do
        rubygem = create(:rubygem, name: "testgem")
        version = create(:version, rubygem: rubygem, number: "1.0.0", indexed: true, info_checksum_v2: nil)
        version2 = create(:version, rubygem: rubygem, number: "1.0.1", indexed: false, yanked_info_checksum_v2: nil)

        task = Maintenance::BackfillCompactIndexV2Task.new
        task.process(rubygem)

        assert_not_nil version2.reload.yanked_info_checksum_v2
        assert_nil version.reload.info_checksum_v2
        assert_enqueued_with(job: UploadInfoFileJob, args: [rubygem_name: "testgem"])
      end
    end

    context "with no versions" do
      should "do nothing" do
        rubygem = create(:rubygem, name: "testgem")

        task = Maintenance::BackfillCompactIndexV2Task.new
        task.process(rubygem)

        assert_no_enqueued_jobs only: UploadInfoFileJob
      end
    end
  end
end
