class OrgResource < Avo::BaseResource
  self.title = :id
  self.includes = []
  # self.search_query = -> do
  #   scope.ransack(id_eq: params[:q], m: "or").result(distinct: false)
  # end

  field :id, as: :id
  # Fields generated from the model
  field :handle, as: :text
  field :full_name, as: :text
  field :deleted_at, as: :date_time
  # add fields here
end
