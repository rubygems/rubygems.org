# frozen_string_literal: true

class Avo::Resources::ApiKeyOrganizationScope < Avo::BaseResource
  self.title = :cache_key
  self.includes = []

  def fields
    field :id, as: :id

    field :api_key, as: :belongs_to
    field :membership, as: :belongs_to
  end
end
