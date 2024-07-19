require "digest/sha2"

class Version < ApplicationRecord # rubocop:disable Metrics/ClassLength
  RUBYGEMS_IMPORT_DATE = Date.parse("2009-07-25")

  belongs_to :rubygem, touch: true
  has_many :dependencies, lambda {
                            order(Rubygem.arel_table["name"].asc).includes(:rubygem).references(:rubygem)
                          }, dependent: :destroy, inverse_of: "version"
  has_many :audits, as: :auditable, inverse_of: :auditable, dependent: :nullify
  has_one :gem_download, inverse_of: :version, dependent: :destroy
  belongs_to :pusher, class_name: "User", inverse_of: :pushed_versions, optional: true
  belongs_to :pusher_api_key, class_name: "ApiKey", inverse_of: :pushed_versions, optional: true
  has_one :deletion, dependent: :delete, inverse_of: :version, required: false
  has_one :yanker, through: :deletion, source: :user, inverse_of: :yanked_versions, required: false

  before_validation :set_canonical_number, if: :number_changed?
  before_validation :full_nameify!
  before_validation :gem_full_nameify!
  before_save :create_link_verifications, if: :metadata_changed?
  before_save :update_prerelease, if: :number_changed?
  # TODO: Remove this once we move to GemDownload only
  after_create :create_gem_download
  after_create :record_push_event
  after_save :reorder_versions, if: -> { saved_change_to_indexed? || saved_change_to_id? }
  after_save :enqueue_web_hook_jobs, if: -> { saved_change_to_indexed? && (!saved_change_to_id? || indexed?) }
  after_save :refresh_rubygem_indexed, if: -> { saved_change_to_indexed? || saved_change_to_id? }

  serialize :licenses, coder: YAML
  serialize :requirements, coder: YAML
  serialize :cert_chain, coder: CertificateChainSerializer

  validates :number, length: { maximum: Gemcutter::MAX_FIELD_LENGTH }, format: { with: Patterns::VERSION_PATTERN }
  validates :platform, length: { maximum: Gemcutter::MAX_FIELD_LENGTH }, format: { with: Patterns::NAME_PATTERN }
  validates :gem_platform, length: { maximum: Gemcutter::MAX_FIELD_LENGTH }, format: { with: Patterns::NAME_PATTERN },
            if: -> { validation_context == :create || gem_platform_changed? }
  validates :full_name, presence: true, uniqueness: { case_sensitive: false },
            if: -> { validation_context == :create || full_name_changed? }
  validates :gem_full_name, presence: true, uniqueness: { case_sensitive: false },
            if: -> { validation_context == :create || gem_full_name_changed? }
  validates :rubygem, presence: true
  validates :licenses, length: { maximum: Gemcutter::MAX_FIELD_LENGTH }, allow_blank: true
  validates :required_rubygems_version, :required_ruby_version, length: { maximum: Gemcutter::MAX_FIELD_LENGTH },
    gem_requirements: true, allow_blank: true
  validates :description, :summary, :authors, :requirements, :cert_chain,
    length: { minimum: 0, maximum: Gemcutter::MAX_TEXT_FIELD_LENGTH },
    allow_blank: true
  validates :sha256, :spec_sha256, format: { with: Patterns::BASE64_SHA256_PATTERN }, allow_nil: true

  validates :number, :platform, :gem_platform, :full_name, :gem_full_name, :canonical_number,
    name_format: { requires_letter: false },
    if: -> { validation_context == :create || number_changed? || platform_changed? },
    presence: true

  validate :unique_canonical_number, on: :create
  validate :platform_and_number_are_unique, on: :create
  validate :gem_platform_and_number_are_unique, on: :create
  validate :original_platform_resolves_to_gem_platform, on: %i[create platform_changed? gem_platform_changed?]
  validate :authors_format, on: :create
  validate :metadata_links_format, if: -> { validation_context == :create || metadata_changed? }
  validate :metadata_attribute_length
  validate :no_dashes_in_version_number, on: :create

  class AuthorType < ActiveModel::Type::String
    def cast_value(value)
      if value.is_a?(Array)
        value.join(", ")
      else
        super
      end
    end
  end
  attribute :authors, AuthorType.new

  def create_gem_download
    GemDownload.create!(count: 0, rubygem_id: rubygem_id, version_id: id)
  end

  def self.reverse_dependencies(name)
    joins(dependencies: :rubygem)
      .indexed
      .where(rubygems_dependencies: { name: name })
  end

  def self.reverse_runtime_dependencies(name)
    reverse_dependencies(name)
      .merge(Dependency.runtime)
  end

  def self.reverse_development_dependencies(name)
    reverse_dependencies(name)
      .merge(Dependency.development)
  end

  def self.owned_by(user)
    where(rubygem_id: user.rubygem_ids)
  end

  def self.subscribed_to_by(user)
    where(rubygem_id: user.subscribed_gem_ids)
      .by_created_at
  end

  def self.created_after(time)
    where(arel_table[:created_at].gt(Arel::Nodes::BindParam.new(time)))
  end

  def self.latest
    where(latest: true)
  end

  def self.prerelease
    where(prerelease: true)
  end

  def self.release
    where(prerelease: false)
  end

  def self.indexed
    where(indexed: true)
  end

  def self.yanked
    where(indexed: false)
  end

  def self.by_position
    order(:position)
  end

  def self.by_created_at
    order(created_at: :desc)
  end

  def self.rows_for_index
    joins(:rubygem)
      .indexed
      .release
      .order("rubygems.name asc, position desc")
      .pluck("rubygems.name", :number, :platform)
  end

  def self.rows_for_latest_index
    joins(:rubygem)
      .indexed
      .latest
      .order("rubygems.name asc, position desc")
      .pluck("rubygems.name", :number, :platform)
  end

  def self.rows_for_prerelease_index
    joins(:rubygem)
      .indexed
      .prerelease
      .order("rubygems.name asc, position desc")
      .pluck("rubygems.name", :number, :platform)
  end

  # This method returns the new versions for brand new rubygems
  def self.new_pushed_versions(limit = 5)
    subquery = <<~SQL.squish
      versions.rubygem_id IN (SELECT versions.rubygem_id FROM versions
        GROUP BY versions.rubygem_id HAVING COUNT(versions.rubygem_id) = 1
        ORDER BY versions.rubygem_id DESC LIMIT :limit)
    SQL

    where(subquery, limit: limit).by_created_at
  end

  def self.just_updated(limit = 5)
    where(rubygem_id: Version.default_scoped
                        .select(:rubygem_id)
                        .indexed
                        .created_after(6.months.ago)
                        .group(:rubygem_id)
                        .having(arel_table["id"].count.gt(1))
                        .order(arel_table["created_at"].maximum.desc)
                        .limit(limit))
      .joins(:rubygem)
      .indexed
      .by_created_at
      .limit(limit)
  end

  def self.published
    indexed.by_created_at
  end

  def self.rubygem_name_for(full_name)
    find_by(full_name: full_name)&.rubygem&.name
  end

  # id is added to ORDER to return stable results for gems pushed at the same time
  def self.created_between(start_time, end_time)
    where(created_at: start_time..end_time).order(:created_at, :id)
  end

  def platformed?
    platform != "ruby"
  end

  delegate :reorder_versions, to: :rubygem

  def authored_at
    return built_at if rely_on_built_at?

    created_at
  end

  # Originally used to prevent showing misidentified dates for gems predating RubyGems,
  # this method also covers cases where a Gem::Specification date is obviously invalid due to build-time considerations.
  def rely_on_built_at?
    return false if created_at.to_date != RUBYGEMS_IMPORT_DATE

    built_at && built_at <= RUBYGEMS_IMPORT_DATE
  end

  def refresh_rubygem_indexed
    rubygem.refresh_indexed!
  end

  def previous
    rubygem.versions.find_by(position: position + 1)
  end

  def next
    rubygem.versions.find_by(position: position - 1)
  end

  def yanked?
    !indexed
  end

  def cert_chain_valid_not_before
    cert_chain.map(&:not_before).max
  end

  def cert_chain_valid_not_after
    cert_chain.map(&:not_after).min
  end

  def signature_expired?
    return false unless (expiration_time = cert_chain_valid_not_after)
    expiration_time < Time.now.utc
  end

  def size
    self[:size] || "N/A"
  end

  def byte_size
    self[:size]
  end

  def byte_size=(size)
    self[:size] = size.to_i
  end

  def info
    [description, summary, "This rubygem does not have a description or summary."].find(&:present?)
  end

  def update_attributes_from_gem_specification!(spec)
    update!(
      authors: spec.authors,
      description: spec.description,
      summary: spec.summary,
      licenses: spec.licenses,
      metadata: spec.metadata || {},
      requirements: spec.requirements,
      built_at: spec.date,
      required_rubygems_version: spec.required_rubygems_version.to_s,
      required_ruby_version: spec.required_ruby_version.to_s
    )
  end

  def platform_as_number
    if platformed?
      0
    else
      1
    end
  end

  def <=>(other)
    self_version  = to_gem_version
    other_version = other.to_gem_version

    if self_version == other_version
      platform_as_number <=> other.platform_as_number
    else
      self_version <=> other_version
    end
  end

  def slug
    full_name.remove(/^#{rubygem.name}-/)
  end

  def downloads_count
    gem_download&.count || 0
  end

  def payload
    {
      "authors"                    => authors,
      "built_at"                   => built_at,
      "created_at"                 => created_at,
      "description"                => description,
      "downloads_count"            => downloads_count,
      "metadata"                   => metadata,
      "number"                     => number,
      "summary"                    => summary,
      "platform"                   => platform,
      "rubygems_version"           => required_rubygems_version,
      "ruby_version"               => required_ruby_version,
      "prerelease"                 => prerelease,
      "licenses"                   => licenses,
      "requirements"               => requirements,
      "sha"                        => sha256_hex,
      "spec_sha"                   => spec_sha256_hex
    }
  end

  delegate :as_json, :to_yaml, to: :payload

  def to_xml(options = {})
    payload.to_xml(options.merge(root: "version"))
  end

  def to_s
    number
  end

  def to_title
    if platformed?
      "#{rubygem.name} (#{number}-#{platform})"
    else
      "#{rubygem.name} (#{number})"
    end
  end

  def to_bundler(locked_version: false)
    if prerelease?
      modifier = locked_version ? "" : "~> "
      %(gem '#{rubygem.name}', '#{modifier}#{number}')
    elsif number[0] == "0"
      %(gem '#{rubygem.name}', '~> #{number}')
    else
      release = feature_release
      if release == Gem::Version.new(number)
        %(gem '#{rubygem.name}', '~> #{release}')
      else
        %(gem '#{rubygem.name}', '~> #{release}', '>= #{number}')
      end
    end
  end

  def to_gem_version
    Gem::Version.new(number)
  end

  def to_install
    command = "gem install #{rubygem.name}"
    latest = if prerelease
               rubygem.versions.by_position.prerelease.first
             else
               rubygem.most_recent_version
             end
    command << " -v #{number}" if latest != self
    command << " --pre" if prerelease
    command
  end

  def authors_array
    authors.split(",").flatten
  end

  def sha256_hex
    Version._sha256_hex(sha256) if sha256
  end

  def spec_sha256_hex
    Version._sha256_hex(spec_sha256) if spec_sha256
  end

  def self._sha256_hex(raw)
    raw.unpack1("m0").unpack1("H*")
  end

  def metadata_uri_set?
    Links::LINKS.any? { |_, long| metadata.key? long }
  end

  def rubygems_metadata_mfa_required?
    ActiveRecord::Type::Boolean.new.cast(metadata["rubygems_mfa_required"])
  end

  def prerelease
    !!to_gem_version.prerelease?
  end
  alias prerelease? prerelease

  def manifest
    rubygem.version_manifest(number, platformed? ? platform : nil)
  end

  def gem_file_name
    "#{full_name}.gem"
  end

  private

  def update_prerelease
    self[:prerelease] = prerelease
  end

  def platform_and_number_are_unique
    return unless Version.exists?(rubygem_id: rubygem_id, number: number, platform: platform)
    errors.add(:base, "A version already exists with this number or platform.")
  end

  def gem_platform_and_number_are_unique
    platforms = Version.where(rubygem_id: rubygem_id, number: number, gem_platform: gem_platform).pluck(:platform)
    return if platforms.empty?
    errors.add(:base, "A version already exists with this number and resolved platform #{platforms}")
  end

  def original_platform_resolves_to_gem_platform
    resolved = Gem::Platform.new(platform).to_s
    return if gem_platform == resolved
    errors.add(:base, "The original platform #{platform} does not resolve the platform #{gem_platform} (instead it is #{resolved})")
  end

  def authors_format
    authors = authors_before_type_cast
    return unless authors
    string_authors = authors.is_a?(Array) && authors.grep(String)
    return unless string_authors.blank? || string_authors.size != authors.size
    errors.add :authors, "must be an Array of Strings"
  end

  def full_nameify!
    return if rubygem.nil?
    self.full_name = "#{rubygem.name}-#{number}"
    full_name << "-#{platform}" if platformed?
  end

  def gem_full_nameify!
    return if gem_platform.blank?
    return if rubygem.nil?
    self.gem_full_name = "#{rubygem.name}-#{number}"
    gem_full_name << "-#{gem_platform}" unless gem_platform == "ruby"
  end

  def set_canonical_number
    return unless Gem::Version.correct?(number)
    self.canonical_number = to_gem_version.canonical_segments.join(".")
  end

  def feature_release
    feature_version = to_gem_version.release.segments[0, 2].join(".")
    Gem::Version.new(feature_version)
  end

  def metadata_links_format
    Linkset::LINKS.each do |link|
      url = metadata[link]
      next unless url
      next if Patterns::URL_VALIDATION_REGEXP.match?(url)
      errors.add(:metadata, "['#{link}'] does not appear to be a valid URL")
    end
  end

  def metadata_attribute_length
    return if metadata.blank?

    max_key_size = 128
    max_value_size = 1024
    metadata.each do |key, value|
      errors.add(:metadata, "metadata key ['#{key}'] is too large (maximum is #{max_key_size} bytes)") if key.size > max_key_size
      errors.add(:metadata, "metadata value ['#{value}'] is too large (maximum is #{max_value_size} bytes)") if value.size > max_value_size
      errors.add(:metadata, "metadata key is empty") if key.empty?
    end
  end

  def unique_canonical_number
    version = Version.find_by(canonical_number: canonical_number, rubygem_id: rubygem_id, platform: platform)
    errors.add(:canonical_number, "has already been taken. Existing version: #{version.number}") unless version.nil?
  end

  def no_dashes_in_version_number
    return unless number&.include?("-")
    errors.add(:number, "cannot contain a dash (it will be uninstallable)")
  end

  def create_link_verifications
    uris = metadata.values_at(*Links::LINKS.values).compact_blank.uniq
    verifications = rubygem.link_verifications.where(uri: uris).index_by(&:uri)
    uris.each do |uri|
      verification = verifications.fetch(uri) { rubygem.link_verifications.create_or_find_by!(uri:) }
      verification.retry_if_needed
    end
  end

  def record_push_event
    rubygem.record_event!(Events::RubygemEvent::VERSION_PUSHED, number: number, platform: platform, sha256: sha256_hex,
      pushed_by: pusher&.display_handle, version_gid: to_gid, actor_gid: pusher&.to_gid)
  end

  def enqueue_web_hook_jobs
    jobs = rubygem.web_hooks.or(WebHook.global).enabled
    jobs.find_each do |job|
      job.fire(Gemcutter::PROTOCOL, Gemcutter::HOST, self)
    end
  end
end
