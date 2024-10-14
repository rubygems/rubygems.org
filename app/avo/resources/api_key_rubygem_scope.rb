class Avo::Resources::ApiKeyRubygemScope < Avo::BaseResource
  self.title = :cache_key
  self.includes = []

  def fields
    field :id, as: :id

    field :api_key, as: :belongs_to
    field :ownership, as: :belongs_to
  end
end
