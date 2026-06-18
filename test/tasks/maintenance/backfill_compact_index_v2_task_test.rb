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
      should "enqueue UploadInfoFileJob for v2 only" do
        rubygem = create(:rubygem, name: "testgem")
        create(:version, rubygem: rubygem, number: "1.0.0", indexed: true).update_columns(info_checksum_v2: nil)
        create(:version, rubygem: rubygem, number: "1.0.1", indexed: true).update_columns(info_checksum_v2: nil)

        task = Maintenance::BackfillCompactIndexV2Task.new
        task.process(rubygem)

        assert_enqueued_with(job: UploadInfoFileJob, args: [rubygem_name: "testgem", backfill_only_version: 2])
      end
    end

    context "with a yanked last version" do
      should "enqueue UploadInfoFileJob for v2 only" do
        rubygem = create(:rubygem, name: "testgem")
        create(:version, rubygem: rubygem, number: "1.0.0", indexed: true).update_columns(info_checksum_v2: nil)
        create(:version, rubygem: rubygem, number: "1.0.1", indexed: false)
          .update_columns(info_checksum_v2: nil, yanked_info_checksum_v2: nil)

        task = Maintenance::BackfillCompactIndexV2Task.new
        task.process(rubygem)

        assert_enqueued_with(job: UploadInfoFileJob, args: [rubygem_name: "testgem", backfill_only_version: 2])
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

    context "when already backfilled" do
      should "skip version that already has info_checksum_v2" do
        rubygem = create(:rubygem, name: "testgem")
        create(:version, rubygem: rubygem, number: "1.0.0", indexed: true, info_checksum_v2: "already_set")

        task = Maintenance::BackfillCompactIndexV2Task.new
        task.process(rubygem)

        assert_no_enqueued_jobs only: UploadInfoFileJob
      end

      should "skip version that already has yanked_info_checksum_v2" do
        rubygem = create(:rubygem, name: "testgem")
        create(:version, rubygem: rubygem, number: "1.0.0", indexed: false, yanked_info_checksum_v2: "already_set")

        task = Maintenance::BackfillCompactIndexV2Task.new
        task.process(rubygem)

        assert_no_enqueued_jobs only: UploadInfoFileJob
      end

      should "enqueue UploadInfoFileJob when forced and info_checksum_v2 is already set" do
        rubygem = create(:rubygem, name: "testgem")
        create(:version, rubygem: rubygem, number: "1.0.0", indexed: true, info_checksum_v2: "already_set")

        task = Maintenance::BackfillCompactIndexV2Task.new
        task.force_upload_info_file_job = true
        task.process(rubygem)

        assert_enqueued_with(job: UploadInfoFileJob, args: [rubygem_name: "testgem", backfill_only_version: 2])
      end

      should "enqueue UploadInfoFileJob when forced and yanked_info_checksum_v2 is already set" do
        rubygem = create(:rubygem, name: "testgem")
        create(:version, rubygem: rubygem, number: "1.0.0", indexed: false, yanked_info_checksum_v2: "already_set")

        task = Maintenance::BackfillCompactIndexV2Task.new
        task.force_upload_info_file_job = true
        task.process(rubygem)

        assert_enqueued_with(job: UploadInfoFileJob, args: [rubygem_name: "testgem", backfill_only_version: 2])
      end
    end
  end
end
