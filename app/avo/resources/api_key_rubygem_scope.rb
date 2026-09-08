# frozen_string_literal: true

class Avo::Resources::ApiKeyRubygemScope < Avo::BaseResource
  self.title = :cache_key
  self.includes = %i[api_key ownership]

  def fields
    field :id, as: :id

    field :api_key, as: :belongs_to
    field :ownership, as: :belongs_to
  end
end
