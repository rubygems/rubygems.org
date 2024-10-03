class OrganizationOnboarding < ApplicationRecord
  enum status: { pending: "pending", completed: "completed", failed: "failed" }, _default: "pending"

  belongs_to :organization, optional: true, foreign_key: :onboarded_organization_id, inverse_of: :organization_onboarding

  validates :created_by, presence: true
  validate :user_gem_ownerships
  validate :check_user_roles

  with_options if: :completed? do
    validates :onboarded_at, presence: true
  end

  with_options if: :failed? do
    validates :error, presence: true
  end

  def onboard!
    raise StandardError, "onboard has already been completed" if completed?

    transaction do
      onboarded_organization = create_organization!

      update!(
        onboarded_at: Time.zone.now,
        status: :completed,
        onboarded_organization_id: onboarded_organization.id
      )
    end
  rescue ActiveRecord::ActiveRecordError => e
    update!(
      error: e.message,
      status: :failed
    )
  end

  private

  def create_organization!
    memberships = []
    memberships << build_owner
    invitees.each do |user_id, role|
      next if user_id == created_by
      memberships.push build_membership(user_id, role)
    end

    Organization.create!(
      name: title,
      handle: slug,
      memberships: memberships
    )
  end

  def build_membership(user_id, role)
    Membership.build(
      user_id: user_id,
      role: role
    )
  end

  def build_owner
    Membership.build(
      user_id: created_by,
      role: :owner,
      confirmed_at: Time.zone.now
    )
  end

  def check_user_roles
    invitees.each do |user_id, role|
      errors.add(:invitees, "Invalid Role '#{role}' for User #{user_id}") unless Access::ROLES.key?(role)
    end
  end

  def user_gem_ownerships
    rubygems.each do |id|
      ownership = Ownership.includes(:rubygem).find_by(rubygem_id: id, user_id: created_by)

      if ownership.blank?
        errors.add(:rubygems, "User does not own gem: #{id}")
        next
      end

      errors.add(:rubygems, "User does not have owner permissions for gem: #{ownership.rubygem.name}") unless ownership.owner?
    end
  end
end
