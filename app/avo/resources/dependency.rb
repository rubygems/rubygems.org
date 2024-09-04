class Avo::Resources::Dependency < Avo::BaseResource
  self.includes = []

  def fields
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
end
