# frozen_string_literal: true

require "test_helper"

class UploadVersionsFileJobTest < ActiveJob::TestCase
  setup do
    RubygemFs.compact_index.remove("versions", "v2/versions")
  end

  test "uploads the v2 versions file" do
    version = create(:version)
    info_checksum_v2 = GemInfo.new(version.rubygem.name).info_checksum
    version.update!(info_checksum_v2:)

    UploadVersionsFileJob.perform_now

    v2_content = <<~VERSIONS
      created_at: 2015-08-23T17:22:53-07:00
      ---
      #{version.rubygem.name} #{version.number} #{info_checksum_v2}
    VERSIONS

    assert_nil RubygemFs.compact_index.get("versions")
    assert_equal v2_content, RubygemFs.compact_index.get("v2/versions")

    assert_equal_hash(
      { metadata: {
          "surrogate-control" => "max-age=3600, stale-while-revalidate=1800",
          "surrogate-key" => "v2/versions s3-compact-index s3-v2/versions",
          "sha256" => Digest::SHA256.base64digest(v2_content),
          "md5" => Digest::MD5.base64digest(v2_content)
        },
        cache_control: "max-age=60, public",
        content_type: "text/plain; charset=utf-8",
        checksum_sha256: Digest::SHA256.base64digest(v2_content),
        content_md5: Digest::MD5.base64digest(v2_content),
        key: "v2/versions" },
      RubygemFs.compact_index.head("v2/versions")
    )

    assert_enqueued_with(job: FastlyPurgeJob, args: [key: "s3-v2/versions", soft: true])
  end
end
