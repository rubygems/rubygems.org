# frozen_string_literal: true

class Maintenance::BackfillHistoricalOwnershipsTask < MaintenanceTasks::Task
  attribute :min_ownership_id, :integer
  attribute :max_ownership_id, :integer

  def collection
    scope = Ownership.confirmed
    scope = scope.where(id: min_ownership_id..) if min_ownership_id.present?
    scope = scope.where(id: ..max_ownership_id) if max_ownership_id.present?
    scope
  end

  def process(ownership)
    HistoricalOwnership.find_or_create_by!(rubygem_id: ownership.rubygem_id, user_id: ownership.user_id, removed_at: nil) do |historical|
      historical.role = ownership.role
      historical.first_owned_at = ownership.confirmed_at
    end
  end
end
