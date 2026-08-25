# frozen_string_literal: true

class Advisory::Fetcher
  BATCH_SIZE = 500
  UPDATE_COLUMNS = %i[
    aliases summary severity url published_at modified_at withdrawn_at ranges payload updated_at
  ].freeze

  class << self
    def feature_flag
      raise NotImplementedError, "#{name} must define .feature_flag"
    end

    def advisory_class
      raise NotImplementedError, "#{name} must define .advisory_class"
    end

    def enabled?
      FeatureFlag.enabled?(feature_flag)
    end

    def all
      [Advisory::OSV::Fetcher]
    end

    def enabled
      all.select(&:enabled?)
    end

    def sync_all
      enabled.each { |fetcher| fetcher.new.sync }
    end
  end

  def sync
    return unless self.class.enabled?

    import(fetch.flat_map { |document| map(document) })
  end

  def fetch
    raise NotImplementedError, "#{self.class}#fetch must be implemented"
  end

  def map(_document)
    raise NotImplementedError, "#{self.class}#map must be implemented"
  end

  def import(records)
    return 0 if records.empty?

    self.class.advisory_class.transaction do
      records.each_slice(BATCH_SIZE) do |slice|
        self.class.advisory_class.upsert_all(
          slice,
          unique_by: %i[type identifier rubygem_name],
          update_only: UPDATE_COLUMNS
        )
      end
    end

    records.size
  end
  end
end
