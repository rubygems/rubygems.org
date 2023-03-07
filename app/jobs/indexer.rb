class Indexer < ApplicationJob
  extend StatsD::Instrument
  include TraceTagger

  queue_with_priority PRIORITIES.fetch(:push)

  def self.batch_perform_later
    GoodJob::Batch.enqueue(on_finish: OnFinish) do
      Indexer.perform_later(resource: "specs.4.8.gz")
      Indexer.perform_later(resource: "latest_specs.4.8.gz")
      Indexer.perform_later(resource: "prerelease_specs.4.8.gz")
    end
  end

  class OnFinish < ApplicationJob
    queue_with_priority PRIORITIES.fetch(:push)
    def perform(batch, params)
      purge_cdn
    end

    def purge_cdn
      Rails.logger.info "Purged index urls from fastly" if Fastly.purge_key("full-index")
    end
  end

  before_perform { @resource = arguments.dig(0, :resource) }

  def perform(...)
    update_index
    OnFinish.perform_now if @resource.blank?
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
    generate_and_upload("specs.4.8.gz") { Version.rows_for_index }
    generate_and_upload("latest_specs.4.8.gz") { Version.rows_for_latest_index }
    generate_and_upload("prerelease_specs.4.8.gz") { Version.rows_for_prerelease_index }
  end

  def generate_and_upload(resource, &)
    return if @resource.present? && @resource != resource

    trace("gemcutter.indexer.index", resource:) do
      upload(resource, minimize_specs(yield))
      Rails.logger.info "Uploaded #{resource}"
    end
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
end
