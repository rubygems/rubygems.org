require "test_helper"

class UploadNamesFileJobTest < ActiveJob::TestCase
  make_my_diffs_pretty!

  test "uploads the names file" do
    version = create(:version, number: "0.0.1", required_ruby_version: ">= 2.0.0", required_rubygems_version: ">= 2.6.3")

    perform_enqueued_jobs only: [UploadNamesFileJob] do
      UploadNamesFileJob.perform_now
    end

    content = <<~INFO
      ---
      #{version.rubygem.name}
    INFO

    assert_equal content, RubygemFs.compact_index.get("names")

    assert_equal(
      {
        metadata: {
          "surrogate-control" => "max-age=3600, stale-while-revalidate=1800",
          "surrogate-key" =>
            "names s3-compact-index s3-names",
          "sha256" => Digest::SHA256.base64digest(content),
          "md5" => Digest::MD5.base64digest(content)
        },
        cache_control: "max-age=60, public",
        content_type: "text/plain; charset=utf-8",
        checksum_sha256: Digest::SHA256.base64digest(content),
        content_md5: Digest::MD5.base64digest(content),
        key: "names"
      }, RubygemFs.compact_index.head("names")
    )

    assert_enqueued_with(job: FastlyPurgeJob, args: [{ key: "s3-names", soft: true }])
  end

  test "#good_job_concurrency_key" do
    job = UploadNamesFileJob.new

    assert_equal "UploadNamesFileJob", job.good_job_concurrency_key
  end
end
