class RubygemPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
  end

  ABANDONED_RELEASE_AGE = 1.year
  ABANDONED_DOWNLOADS_MAX = 10_000

  alias rubygem record
  delegate :organization, to: :rubygem

  def create?
    user.present?
  end

  def configure_oidc?
    gem_permissions.can_perform_gem_admin? || deny
  end

  def configure_trusted_publishers?
    gem_permissions.can_perform_gem_admin? || deny
  end

  def show_events?
    gem_permissions.can_push? || deny
  end

  def show_unconfirmed_ownerships?
    gem_permissions.can_perform_gem_admin? || deny
  end

  def add_owner?
    gem_permissions.can_manage_owners? || deny
  end

  def update_owner?
    gem_permissions.can_manage_owners? || deny
  end

  def remove_owner?
    gem_permissions.can_manage_owners? || deny
  end

  def transfer_gem?
    gem_permissions.can_manage_owners? || deny
  end

  private

  def gem_permissions
    GemPermissions.new(record, user)
  end
end
