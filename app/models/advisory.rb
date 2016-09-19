class Advisory < ActiveRecord::Base
  belongs_to :user

  validates :user, :rubygem, :number, presence: true
  validates :version, presence: true
  validates :rubygem, uniqueness: { scope: :number, message: "^This version is already marked as vulnerable." }
  before_validation :record_metadata

  attr_accessor :version

  private

  def rubygem_name
    @version.rubygem.name
  end

  def record_metadata
    self.rubygem = rubygem_name
    self.number = @version.number
    self.platform = @version.platform
  end
end
