# frozen_string_literal: true

class Maintenance::BackfillCompactIndexV2Task < MaintenanceTasks::Task
  attribute :min_rubygem_id, :integer
  attribute :max_rubygem_id, :integer

  def collection
    scope = Rubygem.with_versions
    scope = scope.where(rubygems: { id: min_rubygem_id.. }) if min_rubygem_id.present?
    scope = scope.where(rubygems: { id: ..max_rubygem_id }) if max_rubygem_id.present?
    scope
  end

  def process(rubygem)
    # Backfill info_checksum_v2 on the most recent version (same logic as CompactIndexTasksHelper)
    gem_info = GemInfo.new(rubygem.name, cached: false)
    checksum_v2 = gem_info.info_checksum_v2

    last_version = rubygem.versions
      .order(Arel.sql("COALESCE(yanked_at, created_at) DESC, number DESC, platform DESC"))
      .first

    return unless last_version

    if last_version.indexed
      last_version.update_column(:info_checksum_v2, checksum_v2)
    else
      last_version.update_column(:yanked_info_checksum_v2, checksum_v2)
    end

    # Regenerate and upload v2 info file (UploadInfoFileJob dual-writes v1 and v2)
    UploadInfoFileJob.perform_later(rubygem_name: rubygem.name)
  end
end
