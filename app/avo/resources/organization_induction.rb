class Avo::Resources::OrganizationInduction < Avo::BaseResource
  self.title = :id
  self.includes = [:organization_onboarding]

  def fields
    field :id, as: :id
    field :organization_onboarding, as: :belongs_to
    field :user, as: :belongs_to
    field :role, as: :select, enum: OrganizationInduction.roles
  end
end
