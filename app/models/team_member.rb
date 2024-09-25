class TeamMember < ApplicationRecord
  belongs_to :team
  belongs_to :user

  validates :user_id, uniqueness: { scope: :team_id }
end
