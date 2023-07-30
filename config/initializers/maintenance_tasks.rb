MaintenanceTasks.error_handler = lambda { |error, task_context, errored_element|
  Rails.error.report error, context: { task_context:, errored_element: }, handled: false
}

Rails.autoloaders.main.on_load("MaintenanceTasks::ApplicationController") do
  MaintenanceTasks::ApplicationController.include GitHubOAuthable
  MaintenanceTasks::ApplicationController.prepend MaintenanceTasksAuditable
end
