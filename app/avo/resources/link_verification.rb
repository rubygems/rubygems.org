class Avo::Resources::LinkVerification < Avo::BaseResource
  self.title = :id
  self.includes = []

  def fields
    field :id, as: :id

    field :linkable, as: :belongs_to,
      polymorphic_as: :linkable,
      types: [::Rubygem]
    field :uri, as: :text
    field :verified?, as: :boolean
    field :last_verified_at, as: :date_time
    field :last_failure_at, as: :date_time
    field :failures_since_last_verification, as: :number
  end
end
