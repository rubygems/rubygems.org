class Deletion < ApplicationRecord
  belongs_to :user

  validates :user, :rubygem, :number, presence: true
  validates :version, presence: true
  validate :version_is_indexed

  before_validation :record_metadata
  after_create :remove_from_index, :set_yanked_info_checksum
  after_commit :remove_from_storage, on: :create
  after_commit :remove_version_contents, on: :create
  after_commit :expire_cache
  after_commit :update_search_index
  after_commit :send_gem_yanked_mail

  attr_accessor :version

  def restore!
    restore_to_index
    restore_to_storage
    restore_version_contents
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
    Indexer.perform_later
  end

  def restore_to_index
    version.update!(indexed: true, yanked_at: nil, yanked_info_checksum: nil)
    Indexer.perform_later
  end

  def remove_from_storage
    RubygemFs.instance.remove(
      "gems/#{@version.full_name}.gem",
      "quick/Marshal.4.8/#{@version.full_name}.gemspec.rz"
    )
  end

  def restore_to_storage
    RubygemFs.instance.restore("gems/#{@version.full_name}.gem")
    RubygemFs.instance.restore("quick/Marshal.4.8/#{@version.full_name}.gemspec.rz")
  end

  def remove_version_contents
    YankVersionContentsJob.perform_later(version:)
  end

  def restore_version_contents
    StoreVersionContentsJob.perform_later(version:)
  end

  def purge_fastly
    FastlyPurgeJob.perform_later(path: "gems/#{@version.full_name}.gem", soft: false)
    FastlyPurgeJob.perform_later(path: "quick/Marshal.4.8/#{@version.full_name}.gemspec.rz", soft: false)
  end

  def update_search_index
    ReindexRubygemJob.perform_later(rubygem: @version.rubygem)
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
