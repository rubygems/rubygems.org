require "digest/sha2"

class Version < ApplicationRecord
  RUBYGEMS_IMPORT_DATE = Date.parse("2009-07-25")

  belongs_to :rubygem, touch: true
  has_many :dependencies, -> { order("rubygems.name ASC").includes(:rubygem) }, dependent: :destroy, inverse_of: "version"
  has_one :gem_download, inverse_of: :version, dependent: :destroy
  belongs_to :pusher, class_name: "User", inverse_of: false, optional: true

  before_validation :full_nameify!
  before_save :update_prerelease, if: :number_changed?
  # TODO: Remove this once we move to GemDownload only
  after_create :create_gem_download
  after_save :reorder_versions, if: -> { saved_change_to_indexed? || saved_change_to_id? }
  after_save :refresh_rubygem_indexed, if: -> { saved_change_to_indexed? || saved_change_to_id? }

  serialize :licenses
  serialize :requirements
  serialize :cert_chain, CertificateChainSerializer

  validates :number, length: { maximum: Gemcutter::MAX_FIELD_LENGTH }, format: { with: /\A#{Gem::Version::VERSION_PATTERN}\z/o }
  validates :platform, length: { maximum: Gemcutter::MAX_FIELD_LENGTH }, format: { with: Rubygem::NAME_PATTERN }
  validates :full_name, presence: true, uniqueness: { case_sensitive: false }
  validates :rubygem, presence: true
  validates :required_rubygems_version, :licenses, length: { maximum: Gemcutter::MAX_FIELD_LENGTH }, allow_blank: true
  validates :description, :summary, :authors, :requirements, :cert_chain,
    length: { minimum: 0, maximum: Gemcutter::MAX_TEXT_FIELD_LENGTH },
    allow_blank: true

  validate :unique_canonical_number, on: :create
  validate :platform_and_number_are_unique, on: :create
  validate :authors_format, on: :create
  validate :metadata_links_format
  validate :metadata_attribute_length

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

  def self.most_recent
    latest.find_by(platform: "ruby") || latest.order(number: :desc).first || last
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
    six_months_ago_ts = 6.months.ago
    subquery = <<~SQL.squish
      versions.rubygem_id IN (SELECT versions.rubygem_id
                                FROM versions
                            WHERE versions.indexed = 'true' AND
                                  versions.created_at > '#{six_months_ago_ts}'
                            GROUP BY versions.rubygem_id
                              HAVING COUNT(versions.id) > 1
                              ORDER BY MAX(created_at) DESC LIMIT :limit)
    SQL

    where(subquery, limit: limit)
      .joins(:rubygem)
      .indexed
      .by_created_at
      .limit(limit)
  end

  def self.published(limit)
    indexed.by_created_at.limit(limit)
  end

  def self.rubygem_name_for(full_name)
    find_by(full_name: full_name)&.rubygem&.name
  end

  def self.created_between(start_time, end_time)
    where(created_at: start_time..end_time).order(:created_at)
  end

  def platformed?
    platform != "ruby"
  end

  delegate :reorder_versions, to: :rubygem

  def authored_at
    return built_at if rely_on_built_at?

    created_at
  end

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
      required_ruby_version: spec.required_ruby_version.to_s,
      indexed: true
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
      "sha"                        => sha256_hex
    }
  end

  def as_json(*)
    payload
  end

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

  def to_bundler
    if number[0] == "0" || prerelease?
      %(gem '#{rubygem.name}', '~> #{number}')
    else
      release = feature_release(number)
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
               rubygem.versions.most_recent
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

  def self._sha256_hex(raw)
    raw.unpack1("m0").unpack1("H*")
  end

  def metadata_uri_set?
    Links::LINKS.any? { |_, long| metadata.key? long }
  end

  def rubygems_metadata_mfa_required?
    ActiveRecord::Type::Boolean.new.cast(metadata["rubygems_mfa_required"])
  end

  def yanker
    Deletion.find_by(rubygem: rubygem.name, number: number, platform: platform)&.user unless indexed
  end

  def prerelease
    !!to_gem_version.prerelease?
  end
  alias prerelease? prerelease

  private

  def update_prerelease
    self[:prerelease] = prerelease
  end

  def platform_and_number_are_unique
    return unless Version.exists?(rubygem_id: rubygem_id, number: number, platform: platform)
    errors.add(:base, "A version already exists with this number or platform.")
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

  def feature_release(number)
    feature_version = Gem::Version.new(number).segments[0, 2].join(".")
    Gem::Version.new(feature_version)
  end

  def metadata_links_format
    Linkset::LINKS.each do |link|
      errors.add(:metadata, "['#{link}'] does not appear to be a valid URL") if
        metadata[link] && metadata[link] !~ Patterns::URL_VALIDATION_REGEXP
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
end
