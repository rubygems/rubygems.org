class DownloadResource < Avo::BaseResource
  self.title = :id
  self.includes = []
  # self.search_query = -> do
  #   scope.ransack(id_eq: params[:q], m: "or").result(distinct: false)
  # end

  field :id, as: :id
  # Fields generated from the model
  field :rubygem_id, as: :number
  field :version_id, as: :number
  field :downloads, as: :number
  field :key, as: :text
  field :bucket, as: :text
  field :occurred_at, as: :date_time
  # add fields here
end
