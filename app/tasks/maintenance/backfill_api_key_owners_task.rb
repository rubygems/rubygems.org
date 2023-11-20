# frozen_string_literal: true

class Maintenance::BackfillApiKeyOwnersTask < MaintenanceTasks::Task
  def collection
    ApiKey.where(owner_id: nil).or(ApiKey.where(owner_type: nil))
  end

  def process(api_key)
    api_key.owner ||= api_key.user
    api_key.save!(validate: false)
  end
end
