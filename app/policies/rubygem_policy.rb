class RubygemPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
  end

  ABANDONED_RELEASE_AGE = 1.year
  ABANDONED_DOWNLOADS_MAX = 10_000

  def show?
    true
  end

  def create?
    user.present?
  end

  def update?
    false
  end

  def destroy?
    false
  end

  def show_adoption?
    record.owned_by?(user) || request_ownership?
  end

  def show_events?
    record.owned_by?(user)
  end

  def request_ownership?
    return false if record.owned_by?(user)
    return true if record.ownership_calls.any?
    return false if record.downloads >= ABANDONED_DOWNLOADS_MAX
    return false unless record.latest_version&.created_at&.before?(ABANDONED_RELEASE_AGE.ago)
    true
  end

  def close_ownership_requests?
    record.owned_by?(user)
  end

  def show_trusted_publishers?
    record.owned_by?(user)
  end

  def show_unconfirmed_ownerships?
    record.owned_by?(user)
  end
end
