# frozen_string_literal: true

require "test_helper"

class UploadInfoFileJobTest < ActiveJob::TestCase
  make_my_diffs_pretty!

  test "uploads the info file" do
    version = create(:version, number: "0.0.1", required_ruby_version: ">= 2.0.0", required_rubygems_version: ">= 2.6.3")
    version.reload
    checksum = "b5d4045c3f466fa91fe2cc6abe79232a1a57cdf104f7a26e716e0a1e2789df78"
    compact_index_info = [CompactIndex::GemVersion.new(
      "0.0.1", "ruby", checksum, version.info_checksum, [], ">= 2.0.0", ">= 2.6.3"
    )]
    compact_index_info_v2 = [CompactIndex::GemVersion.new(
      "0.0.1", "ruby", checksum, version.info_checksum, [], ">= 2.0.0", ">= 2.6.3",
      version.created_at.utc.iso8601
    )]

    Rails.cache.expects(:write).with("info/#{version.rubygem.name}", compact_index_info)
    Rails.cache.expects(:write).with("info_v2/#{version.rubygem.name}", compact_index_info_v2)

    perform_enqueued_jobs only: [UploadInfoFileJob] do
      UploadInfoFileJob.perform_now(rubygem_name: version.rubygem.name)
    end

    content = <<~INFO
      ---
      0.0.1 |checksum:b5d4045c3f466fa91fe2cc6abe79232a1a57cdf104f7a26e716e0a1e2789df78,ruby:>= 2.0.0,rubygems:>= 2.6.3
    INFO

    v2_content = <<~INFO
      ---
      0.0.1 |checksum:b5d4045c3f466fa91fe2cc6abe79232a1a57cdf104f7a26e716e0a1e2789df78,ruby:>= 2.0.0,rubygems:>= 2.6.3,created_at:#{version.created_at.utc.iso8601}
    INFO

    assert_equal content, RubygemFs.compact_index.get("info/#{version.rubygem.name}")
    assert_equal v2_content, RubygemFs.compact_index.get("v2/info/#{version.rubygem.name}")

    assert_equal_hash(
      { metadata: {
          "surrogate-control" => "max-age=3600, stale-while-revalidate=1800",
          "surrogate-key" =>
            "info/* info/#{version.rubygem.name} gem/#{version.rubygem.name} s3-compact-index s3-info/* s3-info/#{version.rubygem.name}",
          "sha256" => Digest::SHA256.base64digest(content),
          "md5" => Digest::MD5.base64digest(content)
        },
        cache_control: "max-age=60, public",
        content_type: "text/plain; charset=utf-8",
        checksum_sha256: Digest::SHA256.base64digest(content),
        content_md5: Digest::MD5.base64digest(content),
        key: "info/#{version.rubygem.name}" },
      RubygemFs.compact_index.head("info/#{version.rubygem.name}")
    )

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

    assert_enqueued_with(job: FastlyPurgeJob, args: [key: "s3-info/#{version.rubygem.name}", soft: true])
    assert_enqueued_with(job: FastlyPurgeJob, args: [key: "s3-v2/info/#{version.rubygem.name}", soft: true])
  end

  test "#good_job_concurrency_key" do
    job = UploadInfoFileJob.new(rubygem_name: "foo")

    assert_equal "UploadInfoFileJob:foo", job.good_job_concurrency_key
  end
end
