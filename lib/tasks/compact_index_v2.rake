# frozen_string_literal: true

namespace :compact_index do
  desc "Generate/upload a versions file for a given format version. Usage: rake compact_index:regenerate_versions_file[v2]"
  task :regenerate_versions_file, [:format_version] => :environment do |_task, args|
    format_key = (args[:format_version] || "v2").to_sym

    unless GemInfo::FORMATS.key?(format_key)
      abort "Unknown format version: #{format_key}. Valid: #{GemInfo::FORMATS.keys.join(', ')}"
    end

    fmt = GemInfo::FORMATS.fetch(format_key)

    puts "Regenerating #{format_key} versions file..."

    ts = Time.now.utc.iso8601
    gems = GemInfo.compact_index_public_versions_for_format(ts, format_key)

    missing_count = Version.where(indexed: true, fmt.checksum_column => nil).count
    if missing_count > 0
      abort "Refusing to generate #{format_key}/versions: #{missing_count} version(s) still missing " \
            "#{fmt.checksum_column}. Run the backfill task first."
    end

    file_path = Rails.application.config.rubygems["versions_file_location_#{format_key}"]
    abort "No versions_file_location_#{format_key} configured in rubygems.yml" unless file_path

    versions_file = CompactIndex::VersionsFile.new(file_path)
    versions_file.create(gems, ts)

    version_file_content = File.read(file_path)
    RubygemFs.instance.store("versions/#{format_key}_versions.list", version_file_content)

    content_md5 = Digest::MD5.base64digest(version_file_content)
    checksum_sha256 = Digest::SHA256.base64digest(version_file_content)
    s3_path = "#{format_key}/versions"

    RubygemFs.compact_index.store(
      s3_path, version_file_content,
      public_acl: false,
      metadata: {
        "surrogate-control" => "max-age=3600, stale-while-revalidate=1800",
        "surrogate-key" => "#{s3_path} s3-compact-index s3-#{s3_path}",
        "sha256" => checksum_sha256,
        "md5" => content_md5
      },
      cache_control: "max-age=60, public",
      content_type: "text/plain; charset=utf-8",
      checksum_sha256:,
      content_md5:
    )

    puts "Successfully uploaded #{format_key} versions file to S3 (#{gems.size} gems)"
  end
end
