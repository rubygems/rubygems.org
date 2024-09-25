class Team < ApplicationRecord
  belongs_to :organization

  validates :slug, presence: true, uniqueness: { scope: :organization_id }
  validates :name, presence: true
end
