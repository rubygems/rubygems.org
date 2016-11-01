class Advisory < ActiveRecord::Base
  belongs_to :user
  belongs_to :version

  validates :user, :version, :message, presence: true
  validates :version_id, uniqueness: { message: "^This version is already marked as vulnerable." }
end
