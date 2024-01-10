class Avo::Resources::LogTicket < Avo::BaseResource
  self.title = :id
  self.includes = []

  class BackendFilter < Avo::Filters::ScopeBooleanFilter; end
  class StatusFilter < Avo::Filters::ScopeBooleanFilter; end

  def filters
    filter BackendFilter, arguments: { default: LogTicket.backends.transform_values { true } }
    filter StatusFilter, arguments: { default: LogTicket.statuses.transform_values { true } }
  end

  def fields
    field :id, as: :id, link_to_resource: true

    field :key, as: :text
    field :directory, as: :text
    field :backend, as: :select, enum: LogTicket.backends
    field :status, as: :select, enum: LogTicket.statuses
    field :processed_count, as: :number, sortable: true
  end
end
