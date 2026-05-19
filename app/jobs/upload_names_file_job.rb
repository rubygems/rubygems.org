# frozen_string_literal: true

class UploadNamesFileJob < ApplicationJob
  queue_with_priority PRIORITIES.fetch(:push)

  include GoodJob::ActiveJobExtensions::Concurrency

  good_job_control_concurrency_with(
    enqueue_limit: 1,
    perform_limit: 1,
    key: name
  )

  def perform
    names = GemInfo.ordered_names(cached: false)
    response_body = CompactIndex.names(names)

    content_md5 = Digest::MD5.base64digest(response_body)
    checksum_sha256 = Digest::SHA256.base64digest(response_body)

    GemInfo.enabled_formats.each do |format_key, _fmt|
      upload_names_file(format_key, response_body, content_md5, checksum_sha256)
    end
  end

  private

  def upload_names_file(format_key, response_body, content_md5, checksum_sha256)
    s3_path = s3_names_path(format_key)

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

    logger.info(message: "Uploading #{format_key} names file succeeded", response:)
    FastlyPurgeJob.perform_later(key: "s3-#{s3_path}", soft: true)
  end

  def s3_names_path(format_key)
    format_key == :v1 ? "names" : "#{format_key}/names"
  end
end
