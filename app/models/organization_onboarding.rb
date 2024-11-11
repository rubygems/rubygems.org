class OrganizationOnboarding < ApplicationRecord
  enum :name_type, { gem: "gem", user: "user" }, prefix: true
  enum :status, { pending: "pending", completed: "completed", failed: "failed" }, default: "pending"

  has_many :invites, -> { preload(:user) }, class_name: "OrganizationOnboardingInvite", inverse_of: :organization_onboarding, dependent: :destroy
  has_many :users, through: :invites
  belongs_to :organization, optional: true, foreign_key: :onboarded_organization_id, inverse_of: :organization_onboarding
  belongs_to :created_by, class_name: "User", inverse_of: :organization_onboardings

  accepts_nested_attributes_for :invites

  validate :created_by_gem_ownerships

  validates :organization_name, :organization_handle, :name_type, presence: true

  with_options if: :completed? do
    validates :onboarded_at, presence: true
  end

  with_options if: :failed? do
    validates :error, presence: true
  end

  with_options if: :name_type_user? do
    before_validation :set_user_handle
  end

  with_options if: :name_type_gem? do
    validate :organization_handle_matches_rubygem_name
    after_validation :add_namesake_rubygem
  end

  before_save :sync_invites, if: :rubygems_changed?

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

    remove_ownerships
  rescue ActiveRecord::ActiveRecordError => e
    update!(
      error: e.message,
      status: :failed
    )
    false
  end

  def available_rubygems
    created_by.rubygems.order(:name)
  end

  def selected_rubygems
    Rubygem.where(id: rubygems).all
  end

  def namesake_rubygem
    return unless name_type_gem?
    @namesake_rubygem ||= created_by.rubygems.find_by(name: organization_handle)
  end

  def approved_invites
    @approved_invites ||= invites.select { |invite| invite.role.present? }
  end

  def rubygems=(value)
    super(value.compact_blank)
  end

  private

  def users_for_selected_gems
    User
      .joins(:ownerships)
      .where(ownerships: { rubygem_id: available_rubygems.pluck(:id) })
      .where.not(ownerships: { user_id: created_by })
      .order(Arel.sql("COUNT (ownerships.id) DESC"))
      .group(users: [:id])
  end

  def sync_invites
    existing_invites = invites.index_by(&:user_id)
    self.invites = users_for_selected_gems.map { existing_invites[_1.id] || OrganizationOnboardingInvite.new(user: _1) }
  end

  def create_organization!
    memberships = invites.filter_map(&:to_membership)
    memberships << build_owner

    Organization.create!(
      name: organization_name,
      handle: organization_handle,
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
      handle: "default",
      team_members: build_team_members
    )
  end

  def build_team_members
    team_members = users.map { TeamMember.build(user: _1) }
    team_members << TeamMember.build(user: created_by)
  end

  def set_user_handle
    return if created_by.blank? || !name_type_user?
    self.organization_handle = created_by.handle
  end

  def remove_ownerships
    onboarded_users = invites.reject { _1.role.nil? || _1.outside_contributor? }.map(&:user)
    onboarded_users << created_by

    Ownership.includes(:rubygem, :user, :api_key_rubygem_scopes).where(user: onboarded_users, rubygem: selected_rubygems).destroy_all
  end

  def add_namesake_rubygem
    return unless namesake_rubygem && rubygems.exclude?(namesake_rubygem.id)
    rubygems.unshift(namesake_rubygem.id)
  end

  def organization_handle_matches_rubygem_name
    return if organization_handle.blank?
    return if namesake_rubygem.present?
    return if selected_rubygems.any? { _1.name == organization_handle }

    errors.add(:organization_handle, "must match a rubygem you own")
  end

  def created_by_gem_ownerships
    return if created_by.blank? || rubygems.blank?

    ownerships = Ownership.where(user: created_by, rubygem: rubygems).index_by(&:rubygem_id)

    selected_rubygems.each do |rubygem|
      ownership = ownerships[rubygem.id]
      next if ownership.present? && ownership.owner?

      errors.add(:created_by, "must be an owner of the #{rubygem.name} gem")
    end
  end
end
