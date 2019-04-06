class Ownership < ApplicationRecord
  belongs_to :rubygem
  belongs_to :user

  validates :user_id, uniqueness: { scope: :rubygem_id }

  def self.by_gem_name
    joins(:rubygem).order("rubygems.name ASC")
  end

  def safe_destroy
    rubygem.owners.many? && destroy
  end
end
