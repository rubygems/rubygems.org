# frozen_string_literal: true

class UpdateVersionsListJob < ApplicationJob
  class UnsupportedVersionError < ArgumentError; end

  queue_with_priority PRIORITIES.fetch(:push)
  discard_on UnsupportedVersionError do |job, exception|
    job.log_discarded_unsupported_version(exception)
  end

  include GoodJob::ActiveJobExtensions::Concurrency

  good_job_control_concurrency_with(
    enqueue_limit: 1,
    perform_limit: 1,
    key: -> { "#{self.class.name}-v#{version_arg}" }
  )

  VERSION_CONFIG = {
    2 => {
      config_key: "versions_file_location_v2",
      store_key: "versions/versions_v2.list"
    }
  }.freeze

  def perform(version:)
    version = normalize_version(version)
    config = VERSION_CONFIG[version]
    raise UnsupportedVersionError, "Unsupported compact index version: #{version}" unless config

    timestamp = Time.now.utc.iso8601
    file_path = Rails.application.config.rubygems[config.fetch(:config_key)]
    versions_file = CompactIndex::VersionsFile.new(file_path)
    gems = GemInfo.each_compact_index_public_version(timestamp, version:)

    versions_file.create_from_sorted(gems, timestamp)
    RubygemFs.instance.store(config.fetch(:store_key), File.read(file_path))
  end

  def log_discarded_unsupported_version(exception)
    logger.info(
      message: "Discarding update versions list job",
      error: exception.message,
      version: version_arg
    )
  end

  private

  def version_arg
    arguments.first.fetch(:version)
  end

  def normalize_version(version)
    Integer(version)
  rescue ArgumentError, TypeError
    raise UnsupportedVersionError, "Unsupported compact index version: #{version}"
  end
end
