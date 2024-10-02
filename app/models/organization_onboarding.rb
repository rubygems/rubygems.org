class OrganizationOnboarding < ApplicationRecord
  enum status: { pending: "pending", completed: "completed", failed: "failed" }, _default: "pending"

  belongs_to :organization, optional: true, foreign_key: :onboarded_organization_id, inverse_of: :organization_onboarding

  validates :created_by, presence: true
  validate :user_gem_ownerships

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
    Organization.create!(
      name: title,
      handle: slug
    )
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
