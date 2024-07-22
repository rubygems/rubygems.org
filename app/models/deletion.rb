class Deletion < ApplicationRecord
  # we nullify the user when they delete their account
  belongs_to :user, optional: true

  belongs_to :version, inverse_of: :deletion

  validates :user, presence: true, on: :create
  validates :rubygem, :number, presence: true
  validates :version, presence: true
  validate :version_is_indexed, on: :create
  validate :eligibility, on: :create
  validate :metadata_matches_version

  before_validation :record_metadata
  after_create :remove_from_index, :set_yanked_info_checksum
  after_create :record_yank_event
  after_destroy :record_unyank_event
  after_commit :remove_from_storage, on: :create
  after_commit :remove_version_contents, on: :create
  after_commit :expire_cache
  after_commit :update_search_index
  after_commit :send_gem_yanked_mail, on: :create

  attr_accessor :force

  def restore!
    restore_to_index
    restore_to_storage
    restore_version_contents
    destroy!
  end

  def ineligible?
    ineligible_reason.present?
  end

  def ineligible_reason
    if version.created_at&.before? 30.days.ago
      "Versions published more than 30 days ago cannot be deleted."
    elsif version.downloads_count > 100_000
      "Versions with more than 100,000 downloads cannot be deleted."
    end
  end

  def record_yank_forbidden_event!
    return unless user && version && version.indexed? && ineligible?
    version.rubygem.record_event!(
      Events::RubygemEvent::VERSION_YANK_FORBIDDEN,
      reason: ineligible_reason,
      number: version.number,
      platform: version.platform,
      yanked_by: user.display_handle,
      actor_gid: user.to_gid,
      version_gid: version.to_gid
    )
  end

  private

  def version_is_indexed
    errors.add(:base, "#{rubygem_name} #{version} has already been deleted") unless version.indexed?
  end

  def eligibility
    return if force
    errors.add(:base, ineligible_reason) if ineligible?
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
    Rstuf::RemoveJob.perform_later(version:)
  end

  def restore_to_index
    version.update!(indexed: true, yanked_at: nil, yanked_info_checksum: nil)
    reindex
    Rstuf::AddJob.perform_later(version:)
  end

  def reindex
    Indexer.perform_later
    UploadInfoFileJob.perform_later(rubygem_name: rubygem_name)
    UploadVersionsFileJob.perform_later
    UploadNamesFileJob.perform_later
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

  def record_yank_event
    version.rubygem.record_event!(Events::RubygemEvent::VERSION_YANKED, number: version.number, platform: version.platform,
yanked_by: user&.display_handle, actor_gid: user&.to_gid, version_gid: version.to_gid, force:)
  end

  def record_unyank_event
    version.rubygem.record_event!(Events::RubygemEvent::VERSION_UNYANKED, number: version.number, platform: version.platform,
version_gid: version.to_gid)
  end
end
