class Avo::Resources::Team < Avo::BaseResource
  self.title = :id
  self.includes = []
  # self.search_query = -> do
  #   scope.ransack(id_eq: params[:q], m: "or").result(distinct: false)
  # end

  def fields
    field :id, as: :id
    field :handle, as: :string
    field :name, as: :string
  end

  # add fields here
end
