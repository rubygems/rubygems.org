class Deletion < ActiveRecord::Base
  belongs_to :user

  validates :user, :rubygem, :number, presence: true
  validates :version, presence: true
  validate :version_is_indexed

  before_validation :record_metadata
  after_create :remove_from_index
  after_commit :remove_from_storage

  attr_accessor :version

  private

  def version_is_indexed
    errors.add(:number, "is already deleted") unless @version.indexed?
  end

  def rubygem_name
    @version.rubygem.name
  end

  def record_metadata
    self.rubygem = rubygem_name
    self.number = @version.number
    self.platform = @version.platform
  end

  def remove_from_index
    @version.update!(indexed: false, yanked_at: Time.now.utc)
    Redis.current.lrem(Rubygem.versions_key(rubygem_name), 1, @version.full_name)
    Delayed::Job.enqueue Indexer.new, priority: PRIORITIES[:push]
  end

  def remove_from_storage
    RubygemFs.instance.remove("gems/#{@version.full_name}.gem")
    RubygemFs.instance.remove("quick/Marshal.4.8/#{@version.full_name}.gemspec.rz")
    return unless ENV['FASTLY_DOMAIN']
    domain = "https://#{ENV['FASTLY_DOMAIN']}"
    Fastly.purge("#{domain}/gems/#{@version.full_name}.gem")
    Fastly.purge("#{domain}/quick/Marshal.4.8/#{@version.full_name}.gemspec.rz")
  end
end
