class Audit < ApplicationRecord
  belongs_to :auditable, polymorphic: true

  serialize :audited_changes, JSON

  validates :github_username, presence: true
  validates :github_user_id, presence: true
end
