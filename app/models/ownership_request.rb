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

  def approve!(approver)
    return unless Pundit.policy!(approver, self).approve?
    transaction do
      update!(status: :approved, approver: approver)
      Ownership.create_confirmed(rubygem, user, approver)
    end

    rubygem.ownership_notifiable_owners.each do |notified_user|
      OwnersMailer.owner_added(notified_user.id, user_id, approver.id, rubygem_id).deliver_later
    end

    OwnersMailer.ownership_request_approved(id).deliver_later
  end

  def close!(closer = nil)
    update!(status: :closed)
    return if closer && closer == user # Don't notify the requester if they closed their own request
    OwnersMailer.ownership_request_closed(id).deliver_later
  end
end
