# frozen_string_literal: true

class UploadInfoFileJob < ApplicationJob
  queue_with_priority PRIORITIES.fetch(:push)

  include GoodJob::ActiveJobExtensions::Concurrency

  good_job_control_concurrency_with(
    enqueue_limit: 1,
    perform_limit: 1,
    key: -> { "#{self.class.name}:#{rubygem_name_arg}" }
  )

  def perform(rubygem_name:)
    gem_info = GemInfo.new(rubygem_name, cached: false)

    CompactIndex.active_formats.each do |format|
      info = gem_info.compact_index_info_for(format)
      body = CompactIndex.info(info)
      s3_path = format.s3_path("info/#{rubygem_name}")
      prefix = s3_path.delete_suffix("/#{rubygem_name}")

      content_md5 = Digest::MD5.base64digest(body)
      checksum_sha256 = Digest::SHA256.base64digest(body)

      response = RubygemFs.compact_index.store(
        s3_path, body,
        public_acl: false,
        metadata: {
          "surrogate-control" => "max-age=3600, stale-while-revalidate=1800",
          "surrogate-key" => "#{prefix}/* #{prefix}/#{rubygem_name} gem/#{rubygem_name} s3-compact-index s3-#{prefix}/* s3-#{prefix}/#{rubygem_name}",
          "sha256" => checksum_sha256,
          "md5" => content_md5
        },
        cache_control: "max-age=60, public",
        content_type: "text/plain; charset=utf-8",
        checksum_sha256:,
        content_md5:
      )

      logger.info(message: "Uploading info file for #{rubygem_name} (#{format.version_key}) succeeded", response:)
      FastlyPurgeJob.perform_later(key: "s3-#{s3_path}", soft: true)
    end
  end

  private

  def rubygem_name_arg
    arguments.first.fetch(:rubygem_name)
  end
end
