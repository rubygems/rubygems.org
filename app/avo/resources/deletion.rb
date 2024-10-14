class Avo::Resources::Deletion < Avo::BaseResource
  self.includes = [:version]

  def fields
    field :id, as: :id

    field :created_at, as: :date_time, sortable: true, title: "Deleted At"
    field :rubygem, as: :text
    field :number, as: :text
    field :platform, as: :text
    field :user, as: :belongs_to
    field :version, as: :belongs_to
  end
end
