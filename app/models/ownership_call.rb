class OwnershipCall < ApplicationRecord
  belongs_to :rubygem
  belongs_to :user
  has_many :ownership_requests, -> { opened }, dependent: :destroy, inverse_of: :ownership_call

  validates :note, length: { maximum: Gemcutter::MAX_TEXT_FIELD_LENGTH }
  validates :rubygem_id, :user_id, :status, :note, presence: true
  validates :rubygem_id, uniqueness: { conditions: -> { opened }, message: "can have only one open ownership call" }

  delegate :name, to: :rubygem, prefix: true
  delegate :display_handle, to: :user, prefix: true

  enum status: { opened: true, closed: false }

  def close
    ownership_requests.close_all
    update(status: :closed)
  end
end
