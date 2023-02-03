class Audit < ApplicationRecord
  belongs_to :auditable, polymorphic: true

  serialize :audited_changes, JSON

  validates :action, presence: true
  validates :github_user_id, presence: true
  validates :github_username, presence: true
end
