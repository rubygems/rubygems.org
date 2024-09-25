class OrganizationOnboarding < ApplicationRecord
  enum status: { pending: "pending", completed: "completed", failed: "failed" }, _default: "pending"

  validates :created_by, presence: true
  validate :user_gem_ownerships

  with_options if: :completed? do
    validates :onboarded_at, presence: true
  end

  with_options if: :failed? do
    validates :errors, presence: true
  end

  def onboard!
    raise StandardError, "onboard has already been completed" if completed?

    update!(
      onboarded_at: Time.zone.now,
      status: :completed
    )
  end

  private

  def user_gem_ownerships
    rubygems.each do |id|
      ownership = Ownership.includes(:rubygem).find_by(rubygem_id: id, user_id: created_by)

      if ownership.blank?
        errors.add(:rubygems, "User does not own gem #{id}")
        next
      end

      errors.add(:rubygems, "User does not have owner permissions for gem: #{ownership.rubygem.name}") unless ownership.owner?
    end
  end
end
