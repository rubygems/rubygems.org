class Indexer < ApplicationJob
  extend StatsD::Instrument
  include TraceTagger
  include SemanticLogger::Loggable

  queue_with_priority PRIORITIES.fetch(:push)

  include GoodJob::ActiveJobExtensions::Concurrency
  good_job_control_concurrency_with(
    # Maximum number of jobs with the concurrency key to be
    # concurrently enqueued (excludes performing jobs)
    #
    # Because the indexer job only uses current state at time of perform,
    # it makes no sense to enqueue more than one at a time
    enqueue_limit: good_job_concurrency_enqueue_limit(default: 1),
    perform_limit: good_job_concurrency_perform_limit(default: 1),
    key: name
  )

  def perform
    log "Updating the index"
    update_index
    purge_cdn
    log "Finished updating the index"
  end
  statsd_count_success :perform, "Indexer.perform"
  statsd_measure :perform, "Indexer.perform"

  private

  def stringify(value)
    final = StringIO.new
    gzip = Zlib::GzipWriter.new(final)
    gzip.write(Marshal.dump(value))
    gzip.close

    final.string
  end

  def upload(key, value)
    RubygemFs.instance.store(key, stringify(value), metadata: { "surrogate-key" => "full-index" })
  end

  def update_index
    trace("gemcutter.indexer.index", resource: "specs.4.8.gz") do
      upload("specs.4.8.gz", specs_index)
      log "Uploaded all specs index"
    end
    trace("gemcutter.indexer.index", resource: "latest_specs.4.8.gz") do
      upload("latest_specs.4.8.gz", latest_index)
      log "Uploaded latest specs index"
    end
    trace("gemcutter.indexer.index", resource: "prerelease_specs.4.8.gz") do
      upload("prerelease_specs.4.8.gz", prerelease_index)
      log "Uploaded prerelease specs index"
    end
  end

  def purge_cdn
    log "Purged index urls from fastly" if Fastly.purge_key("full-index")
  end

  def minimize_specs(data)
    names     = Hash.new { |h, k| h[k] = k }
    versions  = Hash.new { |h, k| h[k] = Gem::Version.new(k) }
    platforms = Hash.new { |h, k| h[k] = k }

    data.each do |row|
      row[0] = names[row[0]]
      row[1] = versions[row[1].strip]
      row[2] = platforms[row[2]]
    end

    data
  end

  def specs_index
    minimize_specs Version.rows_for_index
  end

  def latest_index
    minimize_specs Version.rows_for_latest_index
  end

  def prerelease_index
    minimize_specs Version.rows_for_prerelease_index
  end

  def log(message)
    logger.info message
  end
end
