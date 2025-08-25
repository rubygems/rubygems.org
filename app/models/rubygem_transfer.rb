class RubygemTransfer < ApplicationRecord
  enum :status, { pending: "pending", completed: "completed", failed: "failed" }, default: "pending"

  belongs_to :organization
  belongs_to :created_by, class_name: "User"

  has_many :invites, as: :invitable, class_name: "OrganizationInvite", dependent: :destroy
  has_many :users, through: :invites

  accepts_nested_attributes_for :invites

  validate :rubygems_owned_by_transferrer, :created_by_organization_ownership, :rubygem_existing_organization

  before_save :sync_invites, if: :rubygems_changed?

  def transfer!
    transaction do
      memberships = approved_invites.filter_map { it.to_membership(actor: created_by) }
      organization.memberships << memberships

      update!(
        status: :completed,
        completed_at: Time.zone.now
      )

      selected_rubygems.each do |rubygem|
        rubygem.update!(organization_id: organization.id)
      end

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

  def available_rubygems
    return Rubygem.none if created_by.blank?
    created_by.rubygems.where(organization_id: nil).order(:name)
  end

  def selected_rubygems
    @selected_rubygems ||= Rubygem.preload({ ownerships: :user }, :organization).where(id: rubygems)
  end

  def rubygems=(value)
    @selected_rubygems = nil
    super
  end

  private

  def remove_ownerships_for_joining_members
    invited_users = invites.includes(:user).reject { |invite| invite.role.nil? || invite.outside_contributor? }.map(&:user)
    invited_users << created_by

    Ownership.includes(:rubygem, :user, :api_key_rubygem_scopes).where(user: invited_users, rubygem: selected_rubygems).destroy_all
  end

  def demote_outside_contributors_to_maintainer
    outside_contributors = invites.select(&:outside_contributor?).map(&:user)

    Ownership.includes(:rubygem, :user, api_key_rubygem_scopes: :api_key)
      .where(user: outside_contributors, rubygem: rubygems)
      .update_all(role: :maintainer)
  end

  def users_for_rubygem
    return User.none if selected_rubygems.blank? || created_by.blank?
    User
      .joins(:ownerships)
      .where(ownerships: { rubygem_id: rubygems })
      .where.not(ownerships: { user_id: created_by.id })
  end

  def sync_invites
    existing_invites = invites.includes(:user).index_by(&:user_id)
    self.invites = users_for_rubygem.map { |user| existing_invites[user.id] || OrganizationInvite.new(user: user) }
  end

  def rubygems_owned_by_transferrer
    return if created_by.blank? || rubygems.blank?

    ownerships = Ownership.where(user: created_by, rubygem: rubygems).index_by(&:rubygem_id)

    selected_rubygems.reject { ownerships[it.id].present? && ownerships[it.id].owner? }.each do |rubygem|
      errors.add(:created_by, "must be an owner of the #{rubygem.name} gem")
    end
  end

  def created_by_organization_ownership
    return if OrganizationPolicy.new(created_by, organization).transfer_gem?
    errors.add(:created_by, "does not have permission to transfer gems to this organization")
  end

  def rubygem_existing_organization
    rubygems_with_organization = Rubygem.where(id: rubygems).where.not(organization_id: nil)
    return if rubygems_with_organization.empty?

    rubygems_with_organization.each do |rubygem|
      errors.add(:rubygems, "#{rubygem.name} is already owned by an organization")
    end
  end

  def email_onboarded_users(memberships)
    memberships.each { OrganizationMailer.user_invited(it).deliver_later }
  end
end
