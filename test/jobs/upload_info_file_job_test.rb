# frozen_string_literal: true

require "test_helper"

class UploadInfoFileJobTest < ActiveJob::TestCase
  make_my_diffs_pretty!

  test "uploads the info file" do
    version = create(:version, number: "0.0.1", required_ruby_version: ">= 2.0.0", required_rubygems_version: ">= 2.6.3")
    version.reload
    checksum = "b5d4045c3f466fa91fe2cc6abe79232a1a57cdf104f7a26e716e0a1e2789df78"
    compact_index_info_v2 = [CompactIndex::GemVersionV2.new(
      "0.0.1", "ruby", checksum, GemInfo.new(version.rubygem.name).info_checksum, [], ">= 2.0.0", ">= 2.6.3",
      version.created_at.utc.iso8601
    )]

    Rails.cache.expects(:write).with("info_v2/#{version.rubygem.name}", compact_index_info_v2)

    perform_enqueued_jobs only: [UploadInfoFileJob] do
      UploadInfoFileJob.perform_now(rubygem_name: version.rubygem.name)
    end

    v2_content = <<~INFO
      ---
      0.0.1 |checksum:b5d4045c3f466fa91fe2cc6abe79232a1a57cdf104f7a26e716e0a1e2789df78,ruby:>= 2.0.0,rubygems:>= 2.6.3,created_at:#{version.created_at.utc.iso8601}
    INFO

    assert_nil RubygemFs.compact_index.get("info/#{version.rubygem.name}")
    assert_equal v2_content, RubygemFs.compact_index.get("v2/info/#{version.rubygem.name}")

    assert_equal_hash(
      { metadata: {
          "surrogate-control" => "max-age=3600, stale-while-revalidate=1800",
          "surrogate-key" =>
            "v2/info/* v2/info/#{version.rubygem.name} gem/#{version.rubygem.name} " \
            "s3-compact-index s3-v2/info/* s3-v2/info/#{version.rubygem.name}",
          "sha256" => Digest::SHA256.base64digest(v2_content),
          "md5" => Digest::MD5.base64digest(v2_content)
        },
        cache_control: "max-age=60, public",
        content_type: "text/plain; charset=utf-8",
        checksum_sha256: Digest::SHA256.base64digest(v2_content),
        content_md5: Digest::MD5.base64digest(v2_content),
        key: "v2/info/#{version.rubygem.name}" },
      RubygemFs.compact_index.head("v2/info/#{version.rubygem.name}")
    )

    assert_enqueued_with(job: FastlyPurgeJob, args: [key: "s3-v2/info/#{version.rubygem.name}", soft: true])
  end

  test "info_checksum_v2 matches the MD5 of uploaded v2 info file body" do
    # /versions advertises the MD5 of /v2/info/<gem>; if they diverge Bundler rejects on hash mismatch.
    version = create(:version)
    rubygem_name = version.rubygem.name
    version.update!(info_checksum_v2: GemInfo.new(rubygem_name).info_checksum)

    UploadInfoFileJob.perform_now(rubygem_name: rubygem_name)

    v2_body = RubygemFs.compact_index.get("v2/info/#{rubygem_name}")
    version.reload

    assert_equal Digest::MD5.hexdigest(v2_body), version.info_checksum_v2
  end

  test "backfill_only_version uploads only that version and skips Fastly purge" do
    version = create(:version, number: "0.0.1", required_ruby_version: ">= 2.0.0", required_rubygems_version: ">= 2.6.3")

    perform_enqueued_jobs only: [UploadInfoFileJob] do
      UploadInfoFileJob.perform_now(rubygem_name: version.rubygem.name, backfill_only_version: 2)
    end

    assert_nil RubygemFs.compact_index.get("info/#{version.rubygem.name}")
    assert_not_nil RubygemFs.compact_index.get("v2/info/#{version.rubygem.name}")
    assert_no_enqueued_jobs only: FastlyPurgeJob
  end

  test "backfill_only_version: 2 persists info_checksum_v2 on the last indexed version" do
    rubygem = create(:rubygem, name: "testgem")
    create(:version, rubygem: rubygem, number: "1.0.0", indexed: true).update_columns(info_checksum_v2: nil)
    last_version = create(:version, rubygem: rubygem, number: "1.0.1", indexed: true)
    last_version.update_columns(info_checksum_v2: nil)

    UploadInfoFileJob.perform_now(rubygem_name: "testgem", backfill_only_version: 2)

    body = RubygemFs.compact_index.get("v2/info/testgem")

    assert_equal Digest::MD5.hexdigest(body), last_version.reload.info_checksum_v2
  end

  test "backfill_only_version: 2 persists yanked_info_checksum_v2 when last version is yanked" do
    rubygem = create(:rubygem, name: "testgem")
    create(:version, rubygem: rubygem, number: "1.0.0", indexed: true).update_columns(yanked_info_checksum_v2: nil)
    last_version = create(:version, rubygem: rubygem, number: "1.0.1", indexed: false)
    last_version.update_columns(yanked_info_checksum_v2: nil)

    UploadInfoFileJob.perform_now(rubygem_name: "testgem", backfill_only_version: 2)

    body = RubygemFs.compact_index.get("v2/info/testgem")

    assert_equal Digest::MD5.hexdigest(body), last_version.reload.yanked_info_checksum_v2
  end

  test "backfill_only_version: 2 is a no-op for persistence when the rubygem no longer exists" do
    assert_nothing_raised do
      UploadInfoFileJob.perform_now(rubygem_name: "missing-gem", backfill_only_version: 2)
    end
  end

  test "backfill_only_version: 2 does not overwrite an already-populated info_checksum_v2" do
    rubygem = create(:rubygem, name: "testgem")
    last_version = create(:version, rubygem: rubygem, number: "1.0.0", indexed: true, info_checksum_v2: "set-by-after-version-write")

    UploadInfoFileJob.perform_now(rubygem_name: "testgem", backfill_only_version: 2)

    assert_equal "set-by-after-version-write", last_version.reload.info_checksum_v2
  end

  test "backfill_only_version: 2 does not overwrite an already-populated yanked_info_checksum_v2" do
    rubygem = create(:rubygem, name: "testgem")
    last_version = create(:version, rubygem: rubygem, number: "1.0.0", indexed: false, yanked_info_checksum_v2: "set-by-deletion")

    UploadInfoFileJob.perform_now(rubygem_name: "testgem", backfill_only_version: 2)

    assert_equal "set-by-deletion", last_version.reload.yanked_info_checksum_v2
  end

  test "rejects unknown backfill_only_version values" do
    job = UploadInfoFileJob.new
    assert_raises(UploadInfoFileJob::InvalidBackfillVersion) do
      job.perform(rubygem_name: "anything", backfill_only_version: 3)
    end
  end

  test "persist_backfill_checksum does not write info_checksum_v2 if indexed flipped to false mid-perform" do
    version = create(:version, indexed: false, yanked_at: 1.minute.ago)
    version.update_column(:info_checksum_v2, nil)

    Version.any_instance.stubs(:indexed).returns(true)

    UploadInfoFileJob.perform_now(rubygem_name: version.rubygem.name, backfill_only_version: 2)

    version.reload

    assert_nil version.info_checksum_v2
    assert_nil version.yanked_info_checksum_v2
  end

  test "#good_job_concurrency_key" do
    job = UploadInfoFileJob.new(rubygem_name: "foo")

    assert_equal "UploadInfoFileJob:foo", job.good_job_concurrency_key
  end
end
