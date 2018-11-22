class Subscription < ApplicationRecord
  belongs_to :rubygem
  belongs_to :user

  validates :rubygem_id, uniqueness: { scope: :user_id }
  validates :user, :rubygem, presence: true
end
