class Avo::Resources::OrganizationOnboarding < Avo::BaseResource
  self.title = :organization_name
  self.includes = [:invites]

  def actions
    action Avo::Actions::OnboardOrganization
  end

  def fields
    field :id, as: :id
    field :status, as: :select, enum: OrganizationOnboarding.statuses
    field :organization_name, as: :text
    field :organization_handle, as: :text
    field :created_by, as: :belongs_to
    field :error, as: :text

    field :onboarded_at, as: :date_time
    field :created_at, as: :date_time
    field :updated_at, as: :date_time

    tabs style: :pills do
      field :users, as: :has_many, through: :invites
      field :invites, as: :has_many, use_resource: Avo::Resources::OrganizationOnboardingInvite
      field :organization, as: :has_one
    end
  end
end
