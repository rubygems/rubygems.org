class AttestationResource < Avo::BaseResource
  self.title = :id
  self.includes = []
  # self.search_query = -> do
  #   scope.ransack(id_eq: params[:q], m: "or").result(distinct: false)
  # end

  field :id, as: :id
  # Fields generated from the model
  field :version, as: :text
  field :body, as: :json_viewer
  field :identifier, as: :text
  # add fields here
end
