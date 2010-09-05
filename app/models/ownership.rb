class Ownership < ActiveRecord::Base
  belongs_to :rubygem
  belongs_to :user

  validates_uniqueness_of :user_id, :scope => :rubygem_id

  before_create :generate_token
  before_destroy :keep_last_owner

  def generate_token
    self.token = ActiveSupport::SecureRandom.hex
  end

  def keep_last_owner
    if rubygem.owners.count == 1
      errors[:base] << "Can't delete last owner of a gem."
      false
    else
      true
    end
  end

end
