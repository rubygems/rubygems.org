class UploadVersionsFileJob < ApplicationJob
  queue_with_priority PRIORITIES.fetch(:push)

  include GoodJob::ActiveJobExtensions::Concurrency
  good_job_control_concurrency_with(
    # Maximum number of jobs with the concurrency key to be
    # concurrently enqueued (excludes performing jobs)
    #
    # Because the job only uses current state at time of perform,
    # it makes no sense to enqueue more than one at a time
    enqueue_limit: good_job_concurrency_enqueue_limit(default: 1),
    perform_limit: good_job_concurrency_perform_limit(default: 1),
    key: name
  )

  def perform
    versions_path = Rails.application.config.rubygems["versions_file_location"]
    versions_file = CompactIndex::VersionsFile.new(versions_path)
    from_date = versions_file.updated_at

    logger.info "Generating versions file from #{from_date}"

    extra_gems = GemInfo.compact_index_versions(from_date)
    response_body = CompactIndex.versions(versions_file, extra_gems)

    md5 = Digest::MD5.new.update(response_body)
    checksum_sha256 = Digest::SHA256.base64digest(response_body)

    response = RubygemFs.compact_index.store(
      "versions", response_body,
      metadata: { "surrogate-key" => "versions s3-compact-index s3-versions" },
      cache_control: "max-age=60, public",
      content_type: "text/plain; charset=utf-8",
      checksum_sha256:,
      content_md5: md5.base64digest
    )

    logger.info(message: "Uploading versions file succeeded", response:)

    FastlyPurgeJob.perform_later(key: "s3-versions", soft: true)
  end
end
