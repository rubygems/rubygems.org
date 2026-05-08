# frozen_string_literal: true

class UploadVersionsFileJob < ApplicationJob
  queue_with_priority PRIORITIES.fetch(:push)

  include GoodJob::ActiveJobExtensions::Concurrency

  good_job_control_concurrency_with(
    # Maximum number of jobs with the concurrency key to be
    # concurrently enqueued (excludes performing jobs)
    #
    # Because the job only uses current state at time of perform,
    # it makes no sense to enqueue more than one at a time
    enqueue_limit: 1,
    perform_limit: 1,
    key: name
  )

  def perform
    versions_path = Rails.application.config.rubygems["versions_file_location"]
    versions_file = CompactIndex::VersionsFile.new(versions_path)
    from_date = versions_file.updated_at

    logger.info "Generating versions file from #{from_date}"

    # V1: existing format
    extra_gems = GemInfo.compact_index_versions(from_date)
    response_body = CompactIndex.versions(versions_file, extra_gems)

    content_md5 = Digest::MD5.base64digest(response_body)
    checksum_sha256 = Digest::SHA256.base64digest(response_body)

    response = RubygemFs.compact_index.store(
      "versions", response_body,
      public_acl: false, # the compact-index bucket does not have ACLs enabled
      metadata: {
        "surrogate-control" => "max-age=3600, stale-while-revalidate=1800",
        "surrogate-key" => "versions s3-compact-index s3-versions",
        "sha256" => checksum_sha256,
        "md5" => content_md5
      },
      cache_control: "max-age=60, public",
      content_type: "text/plain; charset=utf-8",
      checksum_sha256:,
      content_md5:
    )

    logger.info(message: "Uploading versions file succeeded", response:)

    # V2: new format (uses info_checksum_v2 columns)
    versions_path_v2 = Rails.application.config.rubygems["versions_file_location_v2"]
    versions_file_v2 = CompactIndex::VersionsFile.new(versions_path_v2)
    from_date_v2 = versions_file_v2.updated_at

    extra_gems_v2 = GemInfo.compact_index_versions_v2(from_date_v2)
    response_body_v2 = CompactIndex.versions(versions_file_v2, extra_gems_v2)

    content_md5_v2 = Digest::MD5.base64digest(response_body_v2)
    checksum_sha256_v2 = Digest::SHA256.base64digest(response_body_v2)

    response_v2 = RubygemFs.compact_index.store(
      "v2/versions", response_body_v2,
      public_acl: false,
      metadata: {
        "surrogate-control" => "max-age=3600, stale-while-revalidate=1800",
        "surrogate-key" => "v2-versions s3-compact-index s3-v2-versions",
        "sha256" => checksum_sha256_v2,
        "md5" => content_md5_v2
      },
      cache_control: "max-age=60, public",
      content_type: "text/plain; charset=utf-8",
      checksum_sha256: checksum_sha256_v2,
      content_md5: content_md5_v2
    )

    logger.info(message: "Uploading v2 versions file succeeded", response: response_v2)

    FastlyPurgeJob.perform_later(key: "s3-versions", soft: true)
  end
end
