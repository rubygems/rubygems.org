class Subscription < ActiveRecord::Base
  belongs_to :rubygem, :touch => true
  belongs_to :user

  validates :rubygem_id, :uniqueness => {:scope => :user_id}
end
