class RubygemPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.none # unused
    end
  end

  ABANDONED_RELEASE_AGE = 1.year
  ABANDONED_DOWNLOADS_MAX = 10_000

  def show?
    true
  end

  def push?
    return false unless user.can_push_rubygem?
    return true if gem_owner?
    rubygem.pushable? && (user.user? || find_pending_trusted_publisher)
  end

  def show_unconfirmed_ownerships?
    gem_owner?
  end

  def show_adoption?
    record.owned_by?(user) || request_ownership?
  end

  def show_events?
    gem_owner?
  end

  private

  def rubygem
    record
  end

  def request_ownership?
    return false if record.owned_by?(user)
    return true if record.ownership_calls.any?
    return false if record.downloads >= ABANDONED_DOWNLOADS_MAX
    return false unless record.latest_version&.created_at&.before?(ABANDONED_RELEASE_AGE.ago)
    true
  end

  def close_ownership_requests?
    gem_owner?
  end

  def show_trusted_publishers?
    gem_owner?
  end

  def show_unconfirmed_ownerships?
    gem_owner?
  end
end
