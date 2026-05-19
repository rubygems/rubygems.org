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
    GemInfo.active_formats.each do |format|
      upload_versions_file(format)
    end
  end

  private

  def upload_versions_file(format)
    versions_path = format.versions_file_path

    unless File.exist?(versions_path)
      logger.info "Skipping versions file upload (#{format.cache_prefix}): #{versions_path} does not exist"
      return
    end

    versions_file = CompactIndex::VersionsFile.new(versions_path)
    from_date = versions_file.updated_at

    logger.info "Generating versions file (#{format.cache_prefix}) from #{from_date}"

    extra_gems = GemInfo.compact_index_versions_for_format(from_date, format)

    missing = extra_gems.select { |g| g.versions.any? { |v| v.info_checksum.nil? } }
    if missing.any?
      logger.warn "Skipping versions upload (#{format.cache_prefix}): #{missing.size} gem(s) missing checksum " \
                  "(first 5: #{missing.map(&:name).first(5).join(', ')})"
      return
    end

    response_body = CompactIndex.versions(versions_file, extra_gems)

    content_md5 = Digest::MD5.base64digest(response_body)
    checksum_sha256 = Digest::SHA256.base64digest(response_body)

    s3_path = format.s3_path("versions")

    response = RubygemFs.compact_index.store(
      s3_path, response_body,
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

    logger.info(message: "Uploading versions file (#{format.cache_prefix}) succeeded", response:)
    FastlyPurgeJob.perform_later(key: "s3-#{s3_path}", soft: true)
  end
end
