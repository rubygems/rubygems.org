class GemTypoExceptionResource < Avo::BaseResource
  self.title = :name
  self.includes = []
  self.search_query = lambda {
    scope.where("name ILIKE ?", "%#{params[:q]}%")
  }

  field :id, as: :id, hide_on: :index
  # Fields generated from the model
  field :name, as: :text, link_to_resource: true
  field :info, as: :textarea
  # add fields here
  field :created_at, as: :date_time, sortable: true, readonly: true, only_on: %i[index show]
  field :updated_at, as: :date_time, sortable: true, readonly: true, only_on: %i[index show]
end
