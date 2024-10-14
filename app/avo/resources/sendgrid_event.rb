class Avo::Resources::SendgridEvent < Avo::BaseResource
  self.title = :sendgrid_id
  self.includes = []
  # self.search_query = -> do
  #   query.ransack(id_eq: params[:q], m: "or").result(distinct: false)
  # end

  class StatusFilter < Avo::Filters::ScopeBooleanFilter; end
  class EventTypeFilter < Avo::Filters::ScopeBooleanFilter; end

  def filters
    filter StatusFilter, arguments: { default: SendgridEvent.statuses.transform_values { true } }
    filter EventTypeFilter, arguments: { default: SendgridEvent.event_types.transform_values { true } }
    filter Avo::Filters::EmailFilter
  end

  def fields
    field :id, as: :id, hide_on: :index

    field :sendgrid_id, as: :text, link_to_resource: true
    field :email, as: :text
    field :event_type, as: :text
    field :occurred_at, as: :date_time, sortable: true
    field :payload, as: :json_viewer
    field :status, as: :select, enum: SendgridEvent.statuses
  end
end
