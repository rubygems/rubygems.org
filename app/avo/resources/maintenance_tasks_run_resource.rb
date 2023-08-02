class MaintenanceTasksRunResource < Avo::BaseResource
  self.title = :id
  self.includes = []
  self.model_class = ::MaintenanceTasks::Run
  # self.search_query = -> do
  #   scope.ransack(id_eq: params[:q], m: "or").result(distinct: false)
  # end

  class StatusFilter < ScopeBooleanFilter; end
  filter StatusFilter, arguments: { default: MaintenanceTasks::Run.statuses.transform_values { true } }

  field :id, as: :id
  # Fields generated from the model
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
  # add fields here
end
