class Audit < ApplicationRecord
  belongs_to :auditable, polymorphic: true
  belongs_to :admin_github_user, class_name: "Admin::GitHubUser"

  serialize :audited_changes, coder: JSON

  validates :action, presence: true
  validates :auditable, presence: false
end
