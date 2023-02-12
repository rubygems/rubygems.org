class DependencyResource < Avo::BaseResource
  self.title = :id
  self.includes = []
  # self.search_query = -> do
  #   scope.ransack(id_eq: params[:q], m: "or").result(distinct: false)
  # end

  field :id, as: :id, link_to_resource: true

  field :version, as: :belongs_to
  field :rubygem, as: :belongs_to
  field :requirements, as: :text
  field :unresolved_name, as: :text

  field :scope, as: :badge,
    options: {
      warning: "development"
    }
end
