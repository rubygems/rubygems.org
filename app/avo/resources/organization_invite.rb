class Avo::Resources::OrganizationInvite < Avo::BaseResource
  self.title = :id
  self.includes = [:invitable]

  def fields
    field :id, as: :id
    field :invitable, as: :belongs_to
    field :user, as: :belongs_to
    field :role, as: :select, enum: OrganizationInvite.roles
  end
end
