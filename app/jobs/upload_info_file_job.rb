class UploadInfoFileJob < ApplicationJob
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
    key: -> { "#{self.class.name}:#{rubygem_name_arg}" }
  )

  def perform(rubygem_name:)
    compact_index_info = GemInfo.new(rubygem_name).compact_index_info
    response_body = CompactIndex.info(compact_index_info)

    content_md5 = Digest::MD5.base64digest(response_body)
    checksum_sha256 = Digest::SHA256.base64digest(response_body)

    response = RubygemFs.compact_index.store(
      "info/#{rubygem_name}", response_body,
      public_acl: false, # the compact-index bucket does not have ACLs enabled
      metadata: {
        "surrogate-control" => "max-age=3600, stale-while-revalidate=1800",
        "surrogate-key" => "info/* info/#{rubygem_name} gem/#{rubygem_name} s3-compact-index s3-info/* s3-info/#{rubygem_name}",
        "sha256" => checksum_sha256,
        "md5" => content_md5
      },
      cache_control: "max-age=60, public",
      content_type: "text/plain; charset=utf-8",
      checksum_sha256:,
      content_md5:
    )

    logger.info(message: "Uploading info file for #{rubygem_name} succeeded", response:)

    FastlyPurgeJob.perform_later(key: "s3-info/#{rubygem_name}", soft: true)
  end

  private

  def rubygem_name_arg
    arguments.first.fetch(:rubygem_name)
  end
end
