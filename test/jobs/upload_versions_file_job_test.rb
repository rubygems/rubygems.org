# frozen_string_literal: true

require "test_helper"

class UploadVersionsFileJobTest < ActiveJob::TestCase
  setup do
    RubygemFs.compact_index.remove("versions", "v2/versions")
  end

  test "uploads the v1 versions file but skips v2 if the v2 file does not exist" do
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
    assert_nil RubygemFs.compact_index.get("v2/versions")

    assert_equal_hash(
      { metadata: {
          "surrogate-control" => "max-age=3600, stale-while-revalidate=1800",
          "surrogate-key" => "versions s3-compact-index s3-versions",
          "sha256" => Digest::SHA256.base64digest(content),
          "md5" => Digest::MD5.base64digest(content)
        },
        cache_control: "max-age=60, public",
        content_type: "text/plain; charset=utf-8",
        checksum_sha256: Digest::SHA256.base64digest(content),
        content_md5: Digest::MD5.base64digest(content),
        key: "versions" },
      RubygemFs.compact_index.head("versions")
    )

    assert_enqueued_with(job: FastlyPurgeJob, args: [key: "s3-versions", soft: true])
    assert_enqueued_jobs 1, only: FastlyPurgeJob
  end

  test "uploads the v1 and v2 versions file if the v2 file exists" do
    version = create(:version)
    info_checksum = GemInfo.new(version.rubygem.name).info_checksum
    info_checksum_v2 = GemInfo.new(version.rubygem.name).info_checksum_v2
    version.update!(info_checksum:, info_checksum_v2:)

    RubygemFs.compact_index.store("v2/versions", "placeholder", public_acl: false)

    UploadVersionsFileJob.perform_now

    content = <<~VERSIONS
      created_at: 2015-08-23T17:22:53-07:00
      ---
      old_gem_one 1 e63fe62df0f1f459d2f70986f79745c6
      old_gem_two 0.1.0,0.1.1,0.1.2,0.2.0,0.2.1,0.3.0,0.4.0,0.4.1,0.5.0,0.5.1,0.5.2,0.5.3 c54e4b7e14861a5d8c225283b75075f4
      #{version.rubygem.name} #{version.number} #{info_checksum}
    VERSIONS

    v2_content = <<~VERSIONS
      created_at: 2015-08-23T17:22:53-07:00
      ---
      #{version.rubygem.name} #{version.number} #{info_checksum_v2}
    VERSIONS

    assert_equal content, RubygemFs.compact_index.get("versions")
    assert_equal v2_content, RubygemFs.compact_index.get("v2/versions")

    assert_equal_hash(
      { metadata: {
          "surrogate-control" => "max-age=3600, stale-while-revalidate=1800",
          "surrogate-key" => "versions s3-compact-index s3-versions",
          "sha256" => Digest::SHA256.base64digest(content),
          "md5" => Digest::MD5.base64digest(content)
        },
        cache_control: "max-age=60, public",
        content_type: "text/plain; charset=utf-8",
        checksum_sha256: Digest::SHA256.base64digest(content),
        content_md5: Digest::MD5.base64digest(content),
        key: "versions" },
      RubygemFs.compact_index.head("versions")
    )

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

    assert_enqueued_with(job: FastlyPurgeJob, args: [key: "s3-versions", soft: true])
    assert_enqueued_with(job: FastlyPurgeJob, args: [key: "s3-v2/versions", soft: true])
  end

  test "skips v2 upload when the v2 file exists but any gem still has NULL info_checksum_v2" do
    version = create(:version)
    info_checksum = GemInfo.new(version.rubygem.name).info_checksum
    version.update!(info_checksum:, info_checksum_v2: nil)

    RubygemFs.compact_index.store("v2/versions", "placeholder", public_acl: false)

    UploadVersionsFileJob.perform_now

    content = <<~VERSIONS
      created_at: 2015-08-23T17:22:53-07:00
      ---
      old_gem_one 1 e63fe62df0f1f459d2f70986f79745c6
      old_gem_two 0.1.0,0.1.1,0.1.2,0.2.0,0.2.1,0.3.0,0.4.0,0.4.1,0.5.0,0.5.1,0.5.2,0.5.3 c54e4b7e14861a5d8c225283b75075f4
      #{version.rubygem.name} #{version.number} #{info_checksum}
    VERSIONS

    assert_equal content, RubygemFs.compact_index.get("versions")

    # v2 file is NOT overwritten, placeholder remains
    assert_equal "placeholder", RubygemFs.compact_index.get("v2/versions")

    assert_enqueued_with(job: FastlyPurgeJob, args: [key: "s3-versions", soft: true])
    assert_enqueued_jobs 1, only: FastlyPurgeJob
  end

  test "skips v2 upload when the v2 file exists but any gem has NULL yanked_info_checksum_v2" do
    version = create(:version)
    info_checksum = GemInfo.new(version.rubygem.name).info_checksum
    info_checksum_v2 = GemInfo.new(version.rubygem.name).info_checksum_v2
    version.update_columns(
      info_checksum: info_checksum,
      info_checksum_v2: info_checksum_v2,
      indexed: false,
      yanked_at: 1.hour.ago,
      yanked_info_checksum: "yankedv1",
      yanked_info_checksum_v2: nil
    )

    RubygemFs.compact_index.store("v2/versions", "placeholder", public_acl: false)

    UploadVersionsFileJob.perform_now

    # v2 file is NOT overwritten because yanked_info_checksum_v2 is nil
    assert_equal "placeholder", RubygemFs.compact_index.get("v2/versions")

    # Only v1 FastlyPurgeJob enqueued (v2 was skipped)
    assert_enqueued_with(job: FastlyPurgeJob, args: [key: "s3-versions", soft: true])
    assert_enqueued_jobs 1, only: FastlyPurgeJob
  end
end
