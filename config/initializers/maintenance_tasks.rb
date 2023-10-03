MaintenanceTasks.error_handler = lambda { |error, task_context, errored_element|
  errored_element =
    case errored_element
    when ActiveRecord::Base
      errored_element.to_gid
    end

  Rails.error.report(
    error,
    context: { task_context:, errored_element: },
    handled: false
  )
}

Rails.autoloaders.main.on_load("MaintenanceTasks::ApplicationController") do
  MaintenanceTasks::ApplicationController.include GitHubOAuthable
  MaintenanceTasks::ApplicationController.prepend MaintenanceTasksAuditable
end
