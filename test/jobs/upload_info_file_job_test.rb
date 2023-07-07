require "test_helper"

class UploadInfoFileJobTest < ActiveJob::TestCase
  make_my_diffs_pretty!

  test "uploads the info file" do
    version = create(:version, number: "0.0.1", required_ruby_version: ">= 2.0.0", required_rubygems_version: ">= 2.6.3")

    perform_enqueued_jobs only: [UploadInfoFileJob] do
      UploadInfoFileJob.perform_now(rubygem_name: version.rubygem.name)
    end

    content = <<~INFO
      ---
      0.0.1 |checksum:b5d4045c3f466fa91fe2cc6abe79232a1a57cdf104f7a26e716e0a1e2789df78,ruby:>= 2.0.0,rubygems:>= 2.6.3
    INFO

    assert_equal content, RubygemFs.compact_index.get("info/#{version.rubygem.name}")

    assert_equal(
      {
        metadata: {
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
        key: "info/#{version.rubygem.name}"
      }, RubygemFs.compact_index.head("info/#{version.rubygem.name}")
    )

    assert_enqueued_with(job: FastlyPurgeJob, args: [{ key: "s3-info/#{version.rubygem.name}", soft: true }])
  end

  test "#good_job_concurrency_key" do
    job = UploadInfoFileJob.new(rubygem_name: "foo")

    assert_equal "UploadInfoFileJob:foo", job.good_job_concurrency_key
  end
end
