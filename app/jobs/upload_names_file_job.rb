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
    body = CompactIndex.names(names)

    CompactIndex.active_formats.each do |format|
      s3_path = format.s3_path("names")

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

      logger.info(message: "Uploading names file (#{format.version_key}) succeeded", response:)
      FastlyPurgeJob.perform_later(key: "s3-#{s3_path}", soft: true)
    end
  end
end
