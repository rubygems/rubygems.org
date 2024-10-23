class OrganizationOnboarding < ApplicationRecord
  enum :status, { pending: "pending", completed: "completed", failed: "failed" }, default: "pending"

  belongs_to :organization, optional: true, foreign_key: :onboarded_organization_id, inverse_of: :organization_onboarding
  belongs_to :created_by, class_name: "User", foreign_key: :created_by, inverse_of: :organization_onboardings

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

      onboard_rubygems!(onboarded_organization)

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

  def avaliable_rubygems
    created_by.rubygems
  end

  def avaliable_users
    User # TODO: Move this to a scope, verify performance
      .joins(:ownerships)
      .where(ownerships: { rubygem_id: avaliable_rubygems.pluck(:id) })
      .where.not(ownerships: { user_id: created_by })
      .distinct(:id)
  end

  private

  def create_organization!
    memberships = []
    memberships << build_owner

    invitees.each do |invitee|
      user_id = invitee["id"]
      role = invitee["role"]

      next if user_id == created_by
      memberships.push build_membership(user_id, role)
    end

    Organization.create!(
      name: title,
      handle: slug,
      memberships: memberships,
      teams: [build_team]
    )
  end

  def onboard_rubygems!(onboarded_organization)
    onboarding_gems = Rubygem.where(id: rubygems).all
    onboarding_gems.each do |rubygem|
      rubygem.update!(organization_id: onboarded_organization.id)
    end
  end

  def build_membership(user_id, role)
    Membership.build(
      user_id: user_id,
      role: role
    )
  end

  def build_owner
    Membership.build(
      user: created_by,
      role: :owner,
      confirmed_at: Time.zone.now
    )
  end

  def build_team
    Team.build(
      name: "Default",
      slug: "default",
      team_members: build_team_members
    )
  end

  def build_team_members
    users = invitees.pluck("id").append(created_by.id)
    users.map do |user_id|
      TeamMember.build(
        user_id: user_id
      )
    end
  end

  def check_user_roles
    invitees.each do |invitee|
      user_id = invitee["id"]
      role = invitee["role"]
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
