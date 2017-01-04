class Deletion < ActiveRecord::Base
  belongs_to :user

  validates :user, :rubygem, :number, presence: true
  validates :version, presence: true
  validate :version_is_indexed

  before_validation :record_metadata
  after_create :remove_from_index, :set_yanked_info_checksum
  after_commit :remove_from_storage
  after_commit :expire_cache
  after_commit :update_search_index

  attr_accessor :version

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
    GemCachePurger.call(rubygem)
  end

  def remove_from_index
    @version.update!(indexed: false, yanked_at: Time.now.utc)
    Delayed::Job.enqueue Indexer.new, priority: PRIORITIES[:push]
  end

  def remove_from_storage
    RubygemFs.instance.remove("gems/#{@version.full_name}.gem")
    RubygemFs.instance.remove("quick/Marshal.4.8/#{@version.full_name}.gemspec.rz")
    Fastly.delay.purge("gems/#{@version.full_name}.gem")
    Fastly.delay.purge("quick/Marshal.4.8/#{@version.full_name}.gemspec.rz")
  end

  def update_search_index
    @version.rubygem.delay.update_document
  end

  def set_yanked_info_checksum
    # expire info cache of last version
    Rails.cache.delete("info/#{rubygem}")
    gem_info = GemInfo.new(version.rubygem.name)
    checksum = Digest::MD5.hexdigest(CompactIndex.info(gem_info.compact_index_info))
    version.update_attribute :yanked_info_checksum, checksum
  end
end
