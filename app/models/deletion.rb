class Deletion < ApplicationRecord
  belongs_to :user

  validates :user, :rubygem, :number, presence: true
  validates :version, presence: true
  validate :version_is_indexed

  before_validation :record_metadata
  after_create :remove_from_index, :set_yanked_info_checksum
  after_commit :remove_from_storage, on: :create
  after_commit :expire_cache
  after_commit :update_search_index
  after_commit :send_gem_yanked_mail

  attr_accessor :version

  def restore!
    restore_to_index
    restore_to_storage
    destroy!
  end

  private

  def version_is_indexed
    errors.add(:base, "#{rubygem_name} #{version} has already been deleted") unless @version.indexed?
  end

  def rubygem_name
    @version.rubygem.name
  end

  def record_metadata
    self.rubygem = rubygem_name
    self.number = @version.number
    self.platform = @version.platform
  end

  def expire_cache
    purge_fastly
    GemCachePurger.call(rubygem)
  end

  def remove_from_index
    @version.update!(indexed: false, yanked_at: Time.now.utc)
    Delayed::Job.enqueue Indexer.new, priority: PRIORITIES[:push]
  end

  def restore_to_index
    version.update!(indexed: true, yanked_at: nil, yanked_info_checksum: nil)
    Delayed::Job.enqueue Indexer.new, priority: PRIORITIES[:push]
  end

  def remove_from_storage
    RubygemFs.instance.remove("gems/#{@version.full_name}.gem")
    RubygemFs.instance.remove("quick/Marshal.4.8/#{@version.full_name}.gemspec.rz")
  end

  def restore_to_storage
    RubygemFs.instance.restore("gems/#{@version.full_name}.gem")
    RubygemFs.instance.restore("quick/Marshal.4.8/#{@version.full_name}.gemspec.rz")
  end

  def purge_fastly
    Fastly.delay.purge(path: "gems/#{@version.full_name}.gem")
    Fastly.delay.purge(path: "quick/Marshal.4.8/#{@version.full_name}.gemspec.rz")
  end

  def update_search_index
    @version.rubygem.delay.reindex
  end

  def set_yanked_info_checksum
    checksum = GemInfo.new(version.rubygem.name).info_checksum
    version.update_attribute :yanked_info_checksum, checksum
  end

  def send_gem_yanked_mail
    version.rubygem.push_notifiable_owners.each do |notified_user|
      Mailer.delay.gem_yanked(user.id, version.id, notified_user.id)
    end
  end
end
