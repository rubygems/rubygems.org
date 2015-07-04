class Subscription < ActiveRecord::Base
  belongs_to :rubygem
  belongs_to :user

  validates :rubygem_id, uniqueness: {scope: :user_id}
end
