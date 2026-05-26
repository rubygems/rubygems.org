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
    last_version = rubygem.versions
      .order(Arel.sql("COALESCE(yanked_at, created_at) DESC, number DESC, platform DESC"))
      .first

    return unless last_version

    # Skip if already backfilled
    return if last_version.info_checksum_v2.present? || last_version.yanked_info_checksum_v2.present?

    # Compute and persist the v2 checksum
    gem_info = GemInfo.new(rubygem.name, cached: false)
    checksum_v2 = gem_info.info_checksum(version: 2)

    if last_version.indexed
      last_version.update_column(:info_checksum_v2, checksum_v2)
    else
      last_version.update_column(:yanked_info_checksum_v2, checksum_v2)
    end

    # Create s3 v2 info file
    UploadInfoFileJob.perform_later(rubygem_name: rubygem.name, backfill_only_version: 2)
  end
end
