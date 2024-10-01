class Avo::Resources::Membership < Avo::BaseResource
  self.includes = []

  class ConfirmedFilter < Avo::Filters::ScopeBooleanFilter; end

  def filters
    filter ConfirmedFilter, arguments: { default: { confirmed: true, unconfirmed: false } }
  end

  def fields
    field :id, as: :id
    field :user, as: :belongs_to
    field :organization, as: :belongs_to
  end
end
