class DeletionResource < Avo::BaseResource
  self.title = :id
  self.includes = [:version]
  # self.search_query = -> do
  #   scope.ransack(id_eq: params[:q], m: "or").result(distinct: false)
  # end

  field :id, as: :id
  # Fields generated from the model
  field :created_at, as: :date_time, sortable: true, title: "Deleted At"
  field :rubygem, as: :text
  field :number, as: :text
  field :platform, as: :text
  field :user, as: :belongs_to
  field :version, as: :belongs_to
  # add fields here
end
