# frozen_string_literal: true

# An operator's approval of a temporary push grant's eligibility and exact scope.
class TemporaryPushGrantApproval < ApplicationRecord
  belongs_to :temporary_push_grant, inverse_of: :approvals
  belongs_to :admin_github_user, class_name: "Admin::GitHubUser"

  validates :conflict_disclosure, :scope_digest, presence: true
  validates :admin_github_user_id, uniqueness: { scope: :temporary_push_grant_id }
  validate :approver_is_independent

  # Neither the requester nor the grantee can supply an independent approval.
  def independent?
    temporary_push_grant.independent_login?(admin_github_user.login)
  end

  private

  def approver_is_independent
    return if admin_github_user.nil? || independent?

    errors.add(:admin_github_user, "cannot be the requester or grantee of the grant")
  end
end
