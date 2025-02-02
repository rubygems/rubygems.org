Rails.autoloaders.main.on_load("MaintenanceTasks::ApplicationController") do
  MaintenanceTasks::ApplicationController.include GitHubOAuthable
  MaintenanceTasks::ApplicationController.prepend MaintenanceTasksAuditable
end
