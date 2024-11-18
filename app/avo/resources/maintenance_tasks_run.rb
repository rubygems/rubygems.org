class Avo::Resources::MaintenanceTasksRun < Avo::BaseResource
  self.includes = []
  self.model_class = ::MaintenanceTasks::Run

  class StatusFilter < Avo::Filters::ScopeBooleanFilter; end

  def filters
    filter StatusFilter, arguments: { default: MaintenanceTasks::Run.statuses.transform_values { true } }
  end

  def fields
    field :id, as: :id

    field :task_name, as: :text
    field :started_at, as: :date_time, sortable: true
    field :ended_at, as: :date_time, sortable: true
    field :time_running, as: :number, sortable: true
    field :tick_count, as: :number
    field :tick_total, as: :number
    field :job_id, as: :text
    field :cursor, as: :number
    field :status, as: :select, enum: MaintenanceTasks::Run.statuses
    field :error_class, as: :text
    field :error_message, as: :text
    field :backtrace, as: :textarea
    field :arguments, as: :textarea
    field :lock_version, as: :number
  end
end
