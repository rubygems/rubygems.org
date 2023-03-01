class DelayedJobResource < Avo::BaseResource
  self.title = :id
  self.includes = []
  self.model_class = ::Delayed::Job

  field :id, as: :id, link_to_resource: true
  field :name, as: :text, format_using: ->(value) { view == :index ? value.truncate(50) : value }
  field :queue, as: :text
  field :priority, as: :number, sortable: true
  field :attempts, as: :number, sortable: true
  field :handler, as: :code, language: :yaml
  field :last_error, as: :textarea

  field :max_attempts, as: :number, sortable: true
  field :max_run_time, as: :number, sortable: true
  field :run_at, as: :date_time, sortable: true
  field :locked_at, as: :date_time, sortable: true
  field :failed_at, as: :date_time, sortable: true
  field :reschedule_at, as: :date_time, sortable: true
  field :locked_by, as: :text
end
