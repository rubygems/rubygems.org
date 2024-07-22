class Admin::OIDC::TrustedPublisher::GitHubActionPolicy < Admin::ApplicationPolicy
  class Scope < Admin::ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end

  has_association :trusted_publishers
  has_association :rubygem_trusted_publishers
  has_association :pending_trusted_publishers
  has_association :rubygems
  has_association :api_keys

  def avo_index? = rubygems_org_admin?
  def avo_show? = rubygems_org_admin?
end
