class Avo::Resources::OrganizationInvite < Avo::BaseResource
  self.title = :id
  self.includes = [:invitable]

  def fields
    field :id, as: :id
    field :invitable_type, as: :text
    field :invitable, as: :belongs_to, polymorphic_as: :invitable
    field :user, as: :belongs_to
    field :role, as: :select, enum: OrganizationInvite.roles
  end
end
