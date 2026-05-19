# frozen_string_literal: true

class Maintenance::BackfillCompactIndexChecksumsTask < MaintenanceTasks::Task
  attribute :format_version, :string, default: "v2"
  attribute :min_rubygem_id, :integer
  attribute :max_rubygem_id, :integer

  throttle_on(backoff: 1.second) do
    ActiveRecord::Base.connection_pool.stat[:busy] > (ActiveRecord::Base.connection_pool.stat[:size] * 0.8)
  end

  def collection
    scope = Rubygem.with_versions
    scope = scope.where("id >= ?", min_rubygem_id) if min_rubygem_id.present?
    scope = scope.where("id <= ?", max_rubygem_id) if max_rubygem_id.present?
    scope
  end

  def process(rubygem)
    format_key = format_version.to_sym
    fmt = GemInfo::FORMATS.fetch(format_key) do
      raise ArgumentError, "Unknown format version: #{format_version}. Valid: #{GemInfo::FORMATS.keys.join(', ')}"
    end

    gem_info = GemInfo.new(rubygem.name, cached: false)
    checksum = gem_info.checksum_for_format(format_key)

    last_version = rubygem.versions
      .order(Arel.sql("COALESCE(yanked_at, created_at) DESC, number DESC, platform DESC"))
      .first

    return unless last_version

    if last_version.indexed?
      last_version.update_columns(fmt.checksum_column => checksum)
    else
      last_version.update_columns(fmt.yanked_checksum_column => checksum)
    end

    UploadInfoFileJob.perform_later(rubygem_name: rubygem.name)
  end

  def count
    collection.count
  end
end
