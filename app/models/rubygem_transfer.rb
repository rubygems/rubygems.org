class RubygemTransfer < ApplicationRecord
  enum :status, { pending: "pending", completed: "completed", failed: "failed" }, default: "pending"

  belongs_to :rubygem
  belongs_to :organization
  belongs_to :created_by, class_name: "User"

  has_many :invites, as: :principal, class_name: "OrganizationInduction", dependent: :destroy
  has_many :users, through: :invites

  accepts_nested_attributes_for :invites

  validate :rubygem_ownership, :organization_ownership

  before_save :sync_invites, if: :organization_changed?

  def transfer!
    transaction do
      organization.memberships << approved_invites.filter_map(&:to_membership)

      rubygem.update!(organization_id: organization.id)

      update!(
        status: :completed,
        completed_at: Time.zone.now
      )

      remove_ownerships!
      email_onboarded_users
    end
  rescue ActiveRecord::ActiveRecordError => e
    self.status = :failed
    self.error = e.message
    save(validate: false)

    raise e
  end

  def approved_invites
    invites.select { |invite| invite.user.present? && invite.role.present? }
  end

  private

  def remove_ownerships!
    invited_users = invites.reject { it.role.nil? || it.outside_contributor? }.map(&:user)
    invited_users << created_by
    Ownership.includes(:rubygem, :user, :api_key_rubygem_scopes).where(user: invited_users, rubygem: rubygem).destroy_all
  end

  def email_onboarded_users
    # TODO
  end

  def users_for_rubygem
    return User.none if rubygem.blank? || created_by.blank?
    User
      .joins(:ownerships)
      .where(ownerships: { rubygem_id: rubygem.id })
      .where.not(ownerships: { user_id: created_by.id })
  end

  def sync_invites
    existing_invites = invites.index_by(&:user_id)
    self.invites = users_for_rubygem.map { existing_invites[it.id] || OrganizationInduction.new(user: it) }
  end

  def rubygem_ownership
    return if RubygemPolicy.new(created_by, rubygem).transfer_gem?
    errors.add(:rubygem, "does not have permission to transfer this gem")
  end

  def organization_ownership
    return if OrganizationPolicy.new(created_by, organization).transfer_gem?
    errors.add(:organization, "does not have permission to transfer gems to this organization")
  end
end
