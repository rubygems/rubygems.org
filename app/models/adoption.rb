class Adoption < ApplicationRecord
  belongs_to :rubygem
  belongs_to :user
  validates :rubygem, :user, presence: true
  validates :user_id, uniqueness: { scope: :rubygem_id }
end
