# frozen_string_literal: true

class Maintenance::BackfillApiKeyScopesTask < MaintenanceTasks::Task
  def collection
    ApiKey.all
  end

  def process(element)
    return unless element.scopes.nil?

    element.update_attribute!(:scopes, element.enabled_scopes)
  end
end
