class OwnershipRequest < ApplicationRecord
  belongs_to :rubygem
  belongs_to :user
  belongs_to :ownership_call, optional: true
  belongs_to :approver, class_name: "User", optional: true

  validates :rubygem_id, :user_id, :status, :note, presence: true
  validates :note, length: { maximum: Gemcutter::MAX_TEXT_FIELD_LENGTH }
  validates :user_id, uniqueness: { scope: :rubygem_id, conditions: -> { opened } }

  delegate :name, to: :user, prefix: true
  delegate :name, to: :rubygem, prefix: true

  enum status: { opened: 0, approved: 1, closed: 2 }

  def approve(approver)
    return false unless rubygem.owned_by?(approver)
    return false unless update(status: :approved, approver: approver)

    Ownership.create_confirmed(rubygem, user, approver)
  end

  def close(user)
    can_close?(user) && update(status: :closed)
  end

  def self.close_all
    closed_ids = ids
    return false unless update_all(status: :closed) == closed_ids.size
    closed_ids.each do |id|
      OwnersMailer.delay.ownership_request_closed(id)
    end
    true
  end

  private

  def can_close?(user)
    self.user == user || rubygem.owned_by?(user)
  end
end
