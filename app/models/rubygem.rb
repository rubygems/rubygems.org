# frozen_string_literal: true

class Rubygem < ApplicationRecord
  include Patterns
  include RubygemSearchable

  has_many :ownerships, dependent: :destroy
  has_many :owners, through: :ownerships, source: :user
  has_many :subscriptions, dependent: :destroy
  has_many :subscribers, through: :subscriptions, source: :user
  has_many :versions, dependent: :destroy, validate: false
  has_one :latest_version, -> { where(latest: true).order(:position) }, class_name: "Version", inverse_of: :rubygem
  has_many :web_hooks, dependent: :destroy
  has_one :linkset, dependent: :destroy
  has_one :gem_download, -> { where(version_id: 0) }, inverse_of: :rubygem

  validate :ensure_name_format, if: :needs_name_validation?
  validates :name,
    presence: true,
    uniqueness: { case_sensitive: false },
    if: :needs_name_validation?
  validate :blacklist_names_exclusion

  after_create :update_unresolved
  before_destroy :mark_unresolved

  # TODO: Remove this once we move to GemDownload only
  after_create :create_gem_download
  def create_gem_download
    GemDownload.create!(count: 0, rubygem_id: id, version_id: 0)
  end

  def self.with_versions
    where("rubygems.id IN (SELECT rubygem_id FROM versions where versions.indexed IS true)")
  end

  def self.with_one_version
    select('rubygems.*')
      .joins(:versions)
      .group(column_names.map { |name| "rubygems.#{name}" }.join(', '))
      .having('COUNT(versions.id) = 1')
  end

  def self.name_is(name)
    sensitive = where(name: name.strip).limit(1)
    return sensitive unless sensitive.empty?

    where("UPPER(name) = UPPER(?)", name.strip).limit(1)
  end

  def self.name_starts_with(letter)
    where("UPPER(name) LIKE UPPER(?)", "#{letter}%")
  end

  def self.total_count
    count_by_sql "SELECT COUNT(*) from (SELECT DISTINCT rubygem_id FROM versions WHERE indexed = true) AS v"
  end

  def self.latest(limit = 5)
    with_one_version.order(created_at: :desc).limit(limit)
  end

  def self.downloaded(limit = 5)
    with_versions.by_downloads.limit(limit)
  end

  def self.letter(letter)
    name_starts_with(letter).by_name.with_versions
  end

  def self.letterize(letter)
    letter =~ /\A[A-Za-z]\z/ ? letter.upcase : 'A'
  end

  def self.by_name
    order(name: :asc)
  end

  def self.by_downloads
    joins(:gem_download).order('gem_downloads.count DESC')
  end

  def self.current_rubygems_release
    rubygem = find_by(name: "rubygems-update")
    rubygem && rubygem.versions.release.indexed.latest.first
  end

  def self.news(days)
    includes(:latest_version, :gem_download)
      .with_versions
      .where("versions.created_at BETWEEN ? AND ?", days.ago.in_time_zone, Time.zone.now)
      .order("versions.created_at DESC")
  end

  def all_errors(version = nil)
    [self, linkset, version].compact.map do |ar|
      ar.errors.full_messages
    end.flatten.join(", ")
  end

  def public_versions(limit = nil)
    versions.by_position.published(limit)
  end

  def public_versions_with_extra_version(extra_version)
    versions = public_versions(5).to_a
    versions << extra_version
    versions.uniq.sort_by(&:position)
  end

  def public_version_payload(number)
    version = public_versions.find_by(number: number)
    payload(version).merge!(version.as_json) if version
  end

  def hosted?
    versions.count.nonzero?
  end

  def unowned?
    ownerships.blank?
  end

  def indexed_versions?
    versions.indexed.count > 0
  end

  def owned_by?(user)
    return false unless user
    ownerships.exists?(user_id: user.id)
  end

  def to_s
    versions.most_recent.try(:to_title) || name
  end

  def downloads
    gem_download.try(:count) || 0
  end

  def links(version = versions.most_recent)
    Links.new(self, version)
  end

  def payload(version = versions.most_recent, protocol = Gemcutter::PROTOCOL, host_with_port = Gemcutter::HOST)
    versioned_links = links(version)
    deps = version.dependencies.to_a
    {
      'name'              => name,
      'downloads'         => downloads,
      'version'           => version.number,
      'version_downloads' => version.downloads_count,
      'platform'          => version.platform,
      'authors'           => version.authors,
      'info'              => version.info,
      'licenses'          => version.licenses,
      'metadata'          => version.metadata,
      'sha'               => version.sha256_hex,
      'project_uri'       => "#{protocol}://#{host_with_port}/gems/#{name}",
      'gem_uri'           => "#{protocol}://#{host_with_port}/gems/#{version.full_name}.gem",
      'homepage_uri'      => versioned_links.homepage_uri,
      'wiki_uri'          => versioned_links.wiki_uri,
      'documentation_uri' => versioned_links.documentation_uri,
      'mailing_list_uri'  => versioned_links.mailing_list_uri,
      'source_code_uri'   => versioned_links.source_code_uri,
      'bug_tracker_uri'   => versioned_links.bug_tracker_uri,
      'changelog_uri'     => versioned_links.changelog_uri,
      'dependencies'      => {
        'development' => deps.select { |r| r.rubygem && r.scope == 'development' },
        'runtime'     => deps.select { |r| r.rubygem && r.scope == 'runtime' }
      }
    }
  end

  def as_json(*)
    payload
  end

  def to_xml(options = {})
    payload.to_xml(options.merge(root: 'rubygem'))
  end

  def to_param
    name.remove(/[^#{Patterns::ALLOWED_CHARACTERS}]/)
  end

  def pushable?
    new_record? || (versions.indexed.none? && not_protected?)
  end

  def create_ownership(user)
    ownerships.create(user: user) if unowned?
  end

  def update_versions!(version, spec)
    version.update_attributes_from_gem_specification!(spec)
  end

  def update_dependencies!(version, spec)
    spec.dependencies.each do |dependency|
      version.dependencies.create!(gem_dependency: dependency)
    end
  rescue ActiveRecord::RecordInvalid => ex
    # ActiveRecord can't chain a nested error here, so we have to add and reraise
    errors[:base] << ex.message
    raise ex
  end

  def update_linkset!(spec)
    self.linkset ||= Linkset.new
    self.linkset.update_attributes_from_gem_specification!(spec)
    self.linkset.save!
  end

  def update_attributes_from_gem_specification!(version, spec)
    Rubygem.transaction do
      save!
      update_versions! version, spec
      update_dependencies! version, spec
      update_linkset! spec if version.reload.latest?
    end
  end

  delegate :count, to: :versions, prefix: true

  def yanked_versions?
    versions.yanked.exists?
  end

  def reorder_versions
    numbers = reload.versions.sort.reverse.map(&:number).uniq

    versions.each do |version|
      Version.find(version.id).update_column(:position, numbers.index(version.number))
    end

    versions.update_all(latest: false)

    versions_of_platforms = versions
      .release
      .indexed
      .group_by(&:platform)

    versions_of_platforms.each_value do |platforms|
      Version.find(platforms.max.id).update_column(:latest, true)
    end
  end

  def disown
    ownerships.each(&:delete)
    ownerships.clear
  end

  def find_version_from_spec(spec)
    versions.find_by_number_and_platform(spec.version.to_s, spec.original_platform.to_s)
  end

  def find_or_initialize_version_from_spec(spec)
    version = versions.find_or_initialize_by(number: spec.version.to_s,
                                             platform: spec.original_platform.to_s)
    version.rubygem = self
    version
  end

  def first_created_date
    versions.by_earliest_created_at.first.created_at
  end

  # returns days left before the reserved namespace will be released
  # 100 + 1 days are added so that last_protected_day / 1.day = 1
  def protected_days
    (updated_at + 101.days - Time.zone.now).to_i / 1.day
  end

  def reverse_dependencies
    self.class.joins("inner join versions as v on v.rubygem_id = rubygems.id
      inner join dependencies as d on d.version_id = v.id").where("v.indexed = 't'
      and v.position = 0 and d.rubygem_id = ?", id)
  end

  def reverse_development_dependencies
    reverse_dependencies.where("d.scope = 'development'")
  end

  def reverse_runtime_dependencies
    reverse_dependencies.where("d.scope ='runtime'")
  end

  private

  # a gem namespace is not protected if it is
  # updated(yanked) in more than 100 days or it is created in last 30 days
  def not_protected?
    updated_at < 100.days.ago || created_at > 30.days.ago
  end

  def ensure_name_format
    if name.class != String
      errors.add :name, "must be a String"
    elsif name !~ /[a-zA-Z]+/
      errors.add :name, "must include at least one letter"
    elsif name !~ NAME_PATTERN
      errors.add :name, "can only include letters, numbers, dashes, and underscores"
    elsif name =~ /\A[#{Regexp.escape(Patterns::SPECIAL_CHARACTERS)}]+/
      errors.add :name, "can not begin with a period, dash, or underscore"
    end
  end

  def needs_name_validation?
    new_record? || name_changed?
  end

  def blacklist_names_exclusion
    return unless GEM_NAME_BLACKLIST.include? name.downcase
    errors.add :name, "'#{name}' is a reserved gem name."
  end

  def update_unresolved
    Dependency.where(unresolved_name: name).find_each do |dependency|
      dependency.update_resolved(self)
    end
  end

  def mark_unresolved
    Dependency.mark_unresolved_for(self)
  end
end
