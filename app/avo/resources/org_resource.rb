class OrgResource < Avo::BaseResource
  self.title = :name
  self.includes = []
  self.search_query = lambda {
    scope.where("name LIKE ? OR handle LIKE ?", "%#{params[:q]}%", "%#{params[:q]}%")
  }
  self.unscoped_queries_on_index = true

  class DeletedFilter < ScopeBooleanFilter; end
  filter DeletedFilter, arguments: { default: { not_deleted: true, deleted: false } }

  field :id, as: :id
  # Fields generated from the model
  field :handle, as: :text
  field :name, as: :text
  field :deleted_at, as: :date_time
  # add fields here
end
