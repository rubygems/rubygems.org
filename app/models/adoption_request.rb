class AdoptionRequest < ApplicationRecord
  belongs_to :user
  belongs_to :rubygem
  validates :rubygem, :user, :status, presence: true
  validates :user_id, uniqueness: { scope: :rubygem_id }

  enum status: { opened: 0, approved: 1, canceled: 2 }
end
