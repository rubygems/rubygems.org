require "test_helper"

class UploadVersionsFileJobTest < ActiveJob::TestCase
  test "uploads the versions file" do
    version = create(:version)
    info_checksum = GemInfo.new(version.rubygem.name).info_checksum
    version.update!(info_checksum:)

    UploadVersionsFileJob.perform_now

    content = <<~VERSIONS
      created_at: 2015-08-23T17:22:53-07:00
      ---
      old_gem_one 1 e63fe62df0f1f459d2f70986f79745c6
      old_gem_two 0.1.0,0.1.1,0.1.2,0.2.0,0.2.1,0.3.0,0.4.0,0.4.1,0.5.0,0.5.1,0.5.2,0.5.3 c54e4b7e14861a5d8c225283b75075f4
      #{version.rubygem.name} #{version.number} #{info_checksum}
    VERSIONS

    assert_equal content, RubygemFs.compact_index.get("versions")

    assert_equal(
      {
        metadata: {
          "surrogate-key" => "versions s3-compact-index s3-versions",
          "sha256" => Digest::SHA256.base64digest(content),
          "md5" => Digest::MD5.base64digest(content)
        },
        cache_control: "max-age=60, public",
        content_type: "text/plain; charset=utf-8",
        checksum_sha256: Digest::SHA256.base64digest(content),
        content_md5: Digest::MD5.base64digest(content),
        key: "versions"
      }, RubygemFs.compact_index.head("versions")
    )

    assert_enqueued_with(job: FastlyPurgeJob, args: [{ key: "s3-versions", soft: true }])
  end
end
