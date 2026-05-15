# frozen_string_literal: true

namespace :compact_index_v2 do
  desc "Generate/update the v2 versions.list file and upload to S3"
  task regenerate_versions_file: :environment do
    ts = Time.now.utc.iso8601
    file_path = Rails.application.config.rubygems["versions_file_location_v2"]
    versions_file = CompactIndex::VersionsFile.new(file_path)
    gems = GemInfo.compact_index_public_versions_v2(ts)

    missing = gems.select { |g| g.versions.any? { |v| v.info_checksum.nil? } }.map(&:name)
    if missing.any?
      raise "Refusing to upload v2/versions: #{missing.size} gem(s) missing info_checksum_v2 " \
            "(first 20: #{missing.first(20).join(', ')}). Run the backfill task first."
    end

    versions_file.create(gems, ts)

    version_file_content = File.read(file_path)

    content_md5 = Digest::MD5.base64digest(version_file_content)
    checksum_sha256 = Digest::SHA256.base64digest(version_file_content)

    RubygemFs.compact_index.store(
      "v2/versions", version_file_content,
      public_acl: false,
      metadata: {
        "surrogate-control" => "max-age=3600, stale-while-revalidate=1800",
        "surrogate-key" => "v2/versions s3-compact-index s3-v2/versions",
        "sha256" => checksum_sha256,
        "md5" => content_md5
      },
      cache_control: "max-age=60, public",
      content_type: "text/plain; charset=utf-8",
      checksum_sha256:,
      content_md5:
    )

    puts "V2 versions file regenerated and uploaded (#{gems.size} gems)."

    FastlyPurgeJob.perform_later(key: "s3-v2/versions", soft: true)
  end
end
