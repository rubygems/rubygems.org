# frozen_string_literal: true

class Avo::Resources::LogTicket < Avo::BaseResource
  self.includes = []
  # log_tickets is large and has no created_at index; sort by the primary key and skip COUNT(*).
  self.default_sort_column = :id
  self.default_sort_direction = :desc
  self.pagination = { type: :countless }

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
    field :processed_count, as: :number
  end
end
