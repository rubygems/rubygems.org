# frozen_string_literal: true

class ApplicationMaintenanceTaskJob < MaintenanceTasks::TaskJob
  queue_as :maintenance
end
