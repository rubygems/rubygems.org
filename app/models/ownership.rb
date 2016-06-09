class Ownership < ActiveRecord::Base
  belongs_to :rubygem
  belongs_to :user

  validates :user_id, uniqueness: { scope: :rubygem_id }
end
