class Adoption < ApplicationRecord
  belongs_to :rubygem
  belongs_to :user
  validates :rubygem, :user, :status, presence: true

  enum status: { requested: 0, seeked: 1, approved: 2, canceled: 3 }
end
