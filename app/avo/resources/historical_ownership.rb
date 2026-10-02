# frozen_string_literal: true

class Avo::Resources::HistoricalOwnership < Avo::BaseResource
  self.title = :cache_key
  self.includes = []

  def fields
    field :id, as: :id, link_to_resource: true

    field :user, as: :belongs_to
    field :rubygem, as: :belongs_to

    field :first_owned_at, as: :date_time
    field :removed_at, as: :date_time
    field :private_at, as: :date_time
  end
end
