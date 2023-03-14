class LogTicketResource < Avo::BaseResource
  self.title = :id
  self.includes = []

  class BackendFilter < ScopeBooleanFilter; end
  filter BackendFilter, arguments: { default: LogTicket.backends.transform_values { true } }

  class StatusFilter < ScopeBooleanFilter; end
  filter StatusFilter, arguments: { default: LogTicket.statuses.transform_values { true } }

  field :id, as: :id, link_to_resource: true

  field :key, as: :text
  field :directory, as: :text
  field :backend, as: :select, enum: LogTicket.backends
  field :status, as: :select, enum: LogTicket.statuses
  field :processed_count, as: :number, sortable: true
end
