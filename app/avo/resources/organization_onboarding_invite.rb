class Avo::Resources::OrganizationOnboardingInvite < Avo::BaseResource
  self.title = :id
  self.includes = [:organization_onboarding]

  def fields
    field :id, as: :id
    field :organization_onboarding, as: :belongs_to
    field :user, as: :belongs_to
    field :role, as: :select, enum: OrganizationOnboardingInvite.roles
  end
end
