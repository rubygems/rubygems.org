class Deletion < ApplicationRecord
  belongs_to :user

  belongs_to :version, ->(d) { joins(:rubygem).where(platform: d.platform, rubygem: { name: d.rubygem }) },
    class_name: "Version",
    foreign_key: :number,
    primary_key: :number,
    inverse_of: :deletion

  validates :user, :rubygem, :number, presence: true
  validates :version, presence: true
  validate :version_is_indexed, on: :create
  validate :metadata_matches_version

  before_validation :record_metadata
  after_create :remove_from_index, :set_yanked_info_checksum
  after_commit :remove_from_storage, on: :create
  after_commit :remove_version_contents, on: :create
  after_commit :expire_cache
  after_commit :update_search_index
  after_commit :send_gem_yanked_mail, on: :create

  def restore!
    restore_to_index
    restore_to_storage
    restore_version_contents
    destroy!
  end

  private

  def version_is_indexed
    errors.add(:base, "#{rubygem_name} #{version} has already been deleted") unless version.indexed?
  end

  def metadata_matches_version
    errors.add(:rubygem, "does not match version rubygem name") unless rubygem == version.rubygem.name
    errors.add(:number, "does not match version number") unless number == version.number
    errors.add(:platform, "does not match version platform") unless platform == version.platform
  end

  def rubygem_name
    version.rubygem.name
  end

  def record_metadata
    self.rubygem = rubygem_name
    self.number = version.number
    self.platform = version.platform
  end

  def expire_cache
    purge_fastly
    GemCachePurger.call(rubygem)
  end

  def remove_from_index
    version.update!(indexed: false, yanked_at: Time.now.utc)
    reindex
  end

  def restore_to_index
    version.update!(indexed: true, yanked_at: nil, yanked_info_checksum: nil)
    reindex
  end

  def reindex
    Indexer.perform_later
    UploadInfoFileJob.perform_later(rubygem_name: rubygem_name)
    UploadVersionsFileJob.perform_later
  end

  def remove_from_storage
    RubygemFs.instance.remove(
      "gems/#{version.gem_file_name}",
      "quick/Marshal.4.8/#{version.full_name}.gemspec.rz"
    )
  end

  def restore_to_storage
    RubygemFs.instance.restore("gems/#{version.gem_file_name}")
    RubygemFs.instance.restore("quick/Marshal.4.8/#{version.full_name}.gemspec.rz")
  end

  def remove_version_contents
    YankVersionContentsJob.perform_later(version:)
  end

  def restore_version_contents
    StoreVersionContentsJob.perform_later(version:)
  end

  def purge_fastly
    FastlyPurgeJob.perform_later(path: "gems/#{version.gem_file_name}", soft: false)
    FastlyPurgeJob.perform_later(path: "quick/Marshal.4.8/#{version.full_name}.gemspec.rz", soft: false)
  end

  def update_search_index
    ReindexRubygemJob.perform_later(rubygem: version.rubygem)
  end

  def set_yanked_info_checksum
    checksum = GemInfo.new(version.rubygem.name).info_checksum
    version.update_attribute :yanked_info_checksum, checksum
  end

  def send_gem_yanked_mail
    version.rubygem.push_notifiable_owners.each do |notified_user|
      Mailer.gem_yanked(user.id, version.id, notified_user.id).deliver_later
    end
  end
end
