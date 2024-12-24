class Admin::UserPolicy < Admin::ApplicationPolicy
  class Scope < Admin::ApplicationPolicy::Scope
    # NOTE: Be explicit about which records you allow access to!
    def resolve
      scope.all
    end
  end

  has_association :api_keys
  has_association :audits
  has_association :deletions
  has_association :events
  has_association :memberships
  has_association :oidc_api_key_roles
  has_association :organizations
  has_association :ownerships
  has_association :pushed_versions
  has_association :rubygems
  has_association :subscribed_gems
  has_association :subscriptions
  has_association :unconfirmed_ownerships
  has_association :web_hooks
  has_association :webauthn_credentials
  has_association :webauthn_verification

  def avo_index?
    rubygems_org_admin?
  end

  def avo_show?
    rubygems_org_admin?
  end

  def act_on?
    rubygems_org_admin?
  end
end
