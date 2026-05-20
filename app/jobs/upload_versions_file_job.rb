# frozen_string_literal: true

class UploadVersionsFileJob < ApplicationJob
  queue_with_priority PRIORITIES.fetch(:push)

  include GoodJob::ActiveJobExtensions::Concurrency

  good_job_control_concurrency_with(
    enqueue_limit: 1,
    perform_limit: 1,
    key: name
  )

  def perform
    CompactIndex.active_formats.each do |format|
      versions_path = format.versions_file_path

      unless File.exist?(versions_path)
        logger.info "Skipping versions file upload (#{format.version_key}): #{versions_path} does not exist"
        next
      end

      versions_file = CompactIndex::VersionsFile.new(versions_path)
      from_date = versions_file.updated_at

      logger.info "Generating versions file (#{format.version_key}) from #{from_date}"

      extra_gems = GemInfo.compact_index_versions_for(from_date, format)

      missing = extra_gems.select { |g| g.versions.any? { |v| v.info_checksum.nil? } }
      if missing.any?
        logger.warn "Skipping versions upload (#{format.version_key}): #{missing.size} gem(s) missing checksum " \
                    "(first 5: #{missing.map(&:name).first(5).join(', ')})"
        next
      end

      body = CompactIndex.versions(versions_file, extra_gems)
      s3_path = format.s3_path("versions")

      content_md5 = Digest::MD5.base64digest(body)
      checksum_sha256 = Digest::SHA256.base64digest(body)

      response = RubygemFs.compact_index.store(
        s3_path, body,
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

      logger.info(message: "Uploading versions file (#{format.version_key}) succeeded", response:)
      FastlyPurgeJob.perform_later(key: "s3-#{s3_path}", soft: true)
    end
  end
end
