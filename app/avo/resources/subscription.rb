# frozen_string_literal: true

class Avo::Resources::Subscription < Avo::BaseResource
  self.includes = %i[rubygem user]

  def fields
    field :id, as: :id
    field :rubygem_id, as: :number
    field :user_id, as: :number
    field :rubygem, as: :belongs_to
    field :user, as: :belongs_to
  end
end
