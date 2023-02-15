class UserPolicy < ApplicationPolicy
  class Scope < Scope
    # NOTE: Be explicit about which records you allow access to!
    def resolve
      scope.all
    end
  end

  def avo_index?
    rubygems_org_admin?
  end

  def avo_show?
    rubygems_org_admin?
  end

  def act_on?
    rubygems_org_admin?
  end

  has_association :webauthn_credentials
  has_association :ownerships
  has_association :rubygems
  has_association :subscriptions
  has_association :subscribed_gems
  has_association :deletions
  has_association :web_hooks
  has_association :unconfirmed_ownerships
  has_association :api_keys
  has_association :ownership_calls
  has_association :ownership_requests
  has_association :pushed_versions
  has_association :audits
end
