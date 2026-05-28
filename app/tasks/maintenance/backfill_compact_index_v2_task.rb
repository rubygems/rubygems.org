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
    return if last_version.info_checksum_v2.present? || last_version.yanked_info_checksum_v2.present?

    UploadInfoFileJob.perform_later(rubygem_name: rubygem.name, backfill_only_version: 2)
  end
end
