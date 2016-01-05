class Indexer
  extend StatsD::Instrument

  def perform
    log "Updating the index"
    update_index
    purge_cdn
    log "Finished updating the index"
  end
  statsd_count_success :perform, 'Indexer.perform.success'
  statsd_measure :perform, 'Indexer.perform'

  def write_gem(body, spec)
    RubygemFs.instance.store("gems/#{spec.original_name}.gem", body.string)

    self.class.sanitize_spec(spec)

    RubygemFs.instance.store(
      "quick/Marshal.4.8/#{spec.original_name}.gemspec.rz",
      Gem.deflate(Marshal.dump(spec)))
  end

  private

  def stringify(value)
    final = StringIO.new
    gzip = Zlib::GzipWriter.new(final)
    gzip.write(Marshal.dump(value))
    gzip.close

    final.string
  end

  def upload(key, value)
    RubygemFs.instance.store(key, stringify(value), 'surrogate-key' => 'full-index')
  end

  def update_index
    upload("specs.4.8.gz", specs_index)
    log "Uploaded all specs index"
    upload("latest_specs.4.8.gz", latest_index)
    log "Uploaded latest specs index"
    upload("prerelease_specs.4.8.gz", prerelease_index)
    log "Uploaded prerelease specs index"
  end

  def purge_cdn
    if ENV['FASTLY_SERVICE_ID'] && ENV['FASTLY_API_KEY']
      Fastly.purge_key('full-index')
      log 'Purged index urls from fastly'
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
    Rails.logger.info "[GEMCUTTER:#{Time.zone.now}] #{message}"
  end

  # TODO: remove this after we upgrade rubygems client to 2.5.0+
  if Gem::VERSION < '2.5.0'
    def self.indexer
      @indexer ||=
        begin
          indexer = Gem::Indexer.new(Rails.root.join("server"), build_legacy: false)
          def indexer.say(_) end
          indexer
        end
    end

    def self.sanitize_spec(spec)
      indexer.abbreviate spec
      indexer.sanitize spec
    end
  else # >= 2.5.0
    def self.sanitize_spec(spec)
      spec.abbreviate
      spec.sanitize
    end
  end
end
