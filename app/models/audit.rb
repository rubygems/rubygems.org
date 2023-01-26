class Audit < ApplicationRecord
  belongs_to :auditable, polymorphic: true
  belongs_to :user, optional: true

  serialize :audited_changes, JSON
end
