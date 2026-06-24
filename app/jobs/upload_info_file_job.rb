# frozen_string_literal: true

class UploadInfoFileJob < ApplicationJob
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
    key: -> { "#{self.class.name}:#{rubygem_name_arg}" }
  )

  class InvalidBackfillVersion < ArgumentError; end

  discard_on InvalidBackfillVersion

  PATH_PREFIXES = { 2 => "v2/info" }.freeze

  def perform(rubygem_name:, backfill_only_version: nil)
    unless backfill_only_version.nil? || PATH_PREFIXES.key?(backfill_only_version)
      raise InvalidBackfillVersion,
        "backfill_only_version must be nil or one of #{PATH_PREFIXES.keys.inspect}, got #{backfill_only_version.inspect}"
    end

    gem_info = GemInfo.new(rubygem_name, cached: false)

    if backfill_only_version
      response_body = upload_info_file(gem_info, rubygem_name, version: backfill_only_version, purge: false)
      persist_backfill_checksum(rubygem_name, version: backfill_only_version, checksum: Digest::MD5.hexdigest(response_body))
    else
      upload_info_file(gem_info, rubygem_name, version: GemInfo::CURRENT_VERSION, purge: true)
    end
  end

  private

  def rubygem_name_arg
    arguments.first.fetch(:rubygem_name)
  end

  def upload_info_file(gem_info, rubygem_name, version:, purge:)
    compact_index_info = gem_info.compact_index_info(version:)
    response_body = CompactIndex.info(compact_index_info)

    content_md5 = Digest::MD5.base64digest(response_body)
    checksum_sha256 = Digest::SHA256.base64digest(response_body)
    path_prefix = PATH_PREFIXES.fetch(version)
    key = "#{path_prefix}/#{rubygem_name}"

    response = RubygemFs.compact_index.store(
      key, response_body,
      public_acl: false, # the compact-index bucket does not have ACLs enabled
      metadata: {
        "surrogate-control" => "max-age=3600, stale-while-revalidate=1800",
        "surrogate-key" => "#{path_prefix}/* #{key} gem/#{rubygem_name} s3-compact-index s3-#{path_prefix}/* s3-#{key}",
        "sha256" => checksum_sha256,
        "md5" => content_md5
      },
      cache_control: "max-age=60, public",
      content_type: "text/plain; charset=utf-8",
      checksum_sha256:,
      content_md5:
    )

    logger.info(message: "Uploading v#{version} info file for #{rubygem_name} succeeded", response:)

    FastlyPurgeJob.perform_later(key: "s3-#{key}", soft: true) if purge

    response_body
  end

  def persist_backfill_checksum(rubygem_name, version:, checksum:)
    rubygem = Rubygem.find_by(name: rubygem_name)
    return unless rubygem

    last_version = rubygem.versions
      .order(Arel.sql("COALESCE(yanked_at, created_at) DESC, number DESC, platform DESC"))
      .first
    return unless last_version

    config = GemInfo::VERSIONS.fetch(version)
    checksum_column = config.fetch(:checksum_column)
    yanked_checksum_column = config.fetch(:yanked_checksum_column)

    scope = Version.where(id: last_version.id)
    if last_version.indexed
      scope.where(indexed: true, checksum_column => nil).update_all(checksum_column => checksum)
    else
      scope.where(indexed: false, yanked_checksum_column => nil).update_all(yanked_checksum_column => checksum)
    end
  end
end
