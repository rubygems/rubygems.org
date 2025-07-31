class RubygemTransfer < ApplicationRecord
  enum :status, { pending: "pending", completed: "completed", failed: "failed" }, default: "pending"

  belongs_to :rubygem
  belongs_to :organization
  belongs_to :created_by, class_name: "User"

  has_many :invites, as: :invitable, class_name: "OrganizationInvite", dependent: :destroy
  has_many :users, through: :invites

  accepts_nested_attributes_for :invites

  validate :rubygem_ownership, :organization_ownership, :rubygem_existing_organization

  before_save :sync_invites, if: :organization_changed?

  def transfer!
    transaction do
      memberships = approved_invites.filter_map { it.to_membership(actor: created_by) }
      organization.memberships << memberships

      update!(
        status: :completed,
        completed_at: Time.zone.now
      )

      rubygem.update!(organization_id: organization.id)

      remove_ownerships_for_joining_members
      demote_outside_contributors_to_maintainer
      email_onboarded_users(memberships)
    end
  rescue ActiveRecord::ActiveRecordError => e
    self.status = :failed
    self.error = e.message
    save(validate: false)

    raise e
  end

  def approved_invites
    invites.includes(:user).select { |invite| invite.user.present? && invite.role.present? }
  end

  private

  def remove_ownerships_for_joining_members
    invited_users = invites.includes(:user).reject { |invite| invite.role.nil? || invite.outside_contributor? }.map(&:user)
    invited_users << created_by

    Ownership.includes(:rubygem, :user, :api_key_rubygem_scopes).where(user: invited_users, rubygem: rubygem).destroy_all
  end

  def demote_outside_contributors_to_maintainer
    outside_contributors = invites.select(&:outside_contributor?).map(&:user)

    Ownership.includes(:rubygem, :user, api_key_rubygem_scopes: :api_key)
      .where(user: outside_contributors, rubygem: rubygem)
      .update_all(role: :maintainer)
  end

  def users_for_rubygem
    return User.none if rubygem.blank? || created_by.blank?
    User
      .joins(:ownerships)
      .where(ownerships: { rubygem_id: rubygem.id })
      .where.not(ownerships: { user_id: created_by.id })
  end

  def sync_invites
    existing_invites = invites.includes(:user).index_by(&:user_id)
    self.invites = users_for_rubygem.map { |user| existing_invites[user.id] || OrganizationInvite.new(user: user) }
  end

  def rubygem_ownership
    return if RubygemPolicy.new(created_by, rubygem).transfer_gem?
    errors.add(:rubygem, "does not have permission to transfer this gem")
  end

  def organization_ownership
    return if OrganizationPolicy.new(created_by, organization).transfer_gem?
    errors.add(:organization, "does not have permission to transfer gems to this organization")
  end

  def rubygem_existing_organization
    return if rubygem.organization.nil?
    errors.add(:rubygem, "is already owned by an organization")
  end

  def email_onboarded_users(memberships)
    memberships.each { OrganizationMailer.user_invited(it).deliver_later }
  end
end
