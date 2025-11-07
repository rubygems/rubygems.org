class Avo::Resources::Subscription < Avo::BaseResource
  def fields
    field :id, as: :id
    field :rubygem_id, as: :number
    field :user_id, as: :number
    field :rubygem, as: :belongs_to
    field :user, as: :belongs_to
  end
end
