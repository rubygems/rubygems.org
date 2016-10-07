class Advisory < ActiveRecord::Base
  belongs_to :user
  belongs_to :rubygem
  belongs_to :version

  validates :user, :rubygem, :version, :message, presence: true
  validates :version, presence: true
  validates :rubygem_id, uniqueness: { scope: :version_id, message: "^This version is already marked as vulnerable." }
  before_validation :record_metadata

  private

  def record_metadata
    self.rubygem_id = version.rubygem_id
    self.version_id = version.id
    self.platform = version.platform
  end
end
