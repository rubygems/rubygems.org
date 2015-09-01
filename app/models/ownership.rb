class Ownership < ActiveRecord::Base
  belongs_to :rubygem
  belongs_to :user

  validates :user_id, uniqueness: { scope: :rubygem_id }

  before_destroy :keep_last_owner

  private

  def keep_last_owner
    if rubygem.owners.count == 1
      errors[:base] << "Can't delete last owner of a gem."
      false
    else
      true
    end
  end
end
