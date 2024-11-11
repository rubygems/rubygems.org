class Team < ApplicationRecord
  has_many :team_members, dependent: :destroy
  belongs_to :organization

  validates :handle, presence: true, uniqueness: { scope: :organization_id }
  validates :name, presence: true
end