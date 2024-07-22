class UploadNamesFileJob < ApplicationJob
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
    names = GemInfo.ordered_names(cached: false)
    response_body = CompactIndex.names(names)

    content_md5 = Digest::MD5.base64digest(response_body)
    checksum_sha256 = Digest::SHA256.base64digest(response_body)

    response = RubygemFs.compact_index.store(
      "names", response_body,
      public_acl: false, # the compact-index bucket does not have ACLs enabled
      metadata: {
        "surrogate-control" => "max-age=3600, stale-while-revalidate=1800",
        "surrogate-key" => "names s3-compact-index s3-names",
        "sha256" => checksum_sha256,
        "md5" => content_md5
      },
      cache_control: "max-age=60, public",
      content_type: "text/plain; charset=utf-8",
      checksum_sha256:,
      content_md5:
    )

    logger.info(message: "Uploading names file succeeded", response:)

    FastlyPurgeJob.perform_later(key: "s3-names", soft: true)
  end
end
