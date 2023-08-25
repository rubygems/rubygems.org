class SendgridEventResource < Avo::BaseResource
  self.title = :sendgrid_id
  self.includes = []
  # self.search_query = -> do
  #   scope.ransack(id_eq: params[:q], m: "or").result(distinct: false)
  # end

  class StatusFilter < ScopeBooleanFilter; end
  filter StatusFilter, arguments: { default: SendgridEvent.statuses.transform_values { true } }

  filter EmailFilter

  field :id, as: :id, hide_on: :index
  # Fields generated from the model
  field :sendgrid_id, as: :text, link_to_resource: true
  field :email, as: :text
  field :event_type, as: :text
  field :occurred_at, as: :date_time, sortable: true
  field :payload, as: :json_viewer
  field :status, as: :select, enum: SendgridEvent.statuses
  # add fields here
end
