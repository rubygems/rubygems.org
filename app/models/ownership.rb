class Ownership < ActiveRecord::Base
  belongs_to :rubygem
  belongs_to :user

  validates :user_id, uniqueness: { scope: :rubygem_id }

  def safe_destroy
    rubygem.owners.count != 1 && destroy ? true : false
  end
end
