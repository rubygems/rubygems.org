class MembershipResource < Avo::BaseResource
  self.title = :id
  self.includes = []

  class ConfirmedFilter < ScopeBooleanFilter; end
  filter ConfirmedFilter, arguments: { default: { confirmed: true, unconfirmed: false } }

  field :id, as: :id
  field :user, as: :belongs_to
  field :organization, as: :belongs_to
end
