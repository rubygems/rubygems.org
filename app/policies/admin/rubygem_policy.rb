class Admin::RubygemPolicy < Admin::ApplicationPolicy
  class Scope < Admin::ApplicationPolicy::Scope
    def resolve
      if rubygems_org_admin?
        scope.all
      else
        scope.with_versions
      end
    end
  end

  has_association :versions
  has_association :latest_version
  has_association :ownerships
  has_association :ownerships_including_unconfirmed
  has_association :ownership_calls
  has_association :ownership_requests
  has_association :subscriptions
  has_association :subscribers
  has_association :web_hooks
  has_association :linkset
  has_association :gem_download
  has_association :audits
  has_association :link_verifications
  has_association :oidc_rubygem_trusted_publishers

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
