require 'digest/sha2'

class Version < ActiveRecord::Base
  belongs_to :rubygem, touch: true
  has_many :dependencies, -> { order('rubygems.name ASC').includes(:rubygem) }, dependent: :destroy
  has_one :gem_download, proc { |m| where(rubygem_id: m.rubygem_id) }

  before_save :update_prerelease
  before_validation :full_nameify!
  after_save :reorder_versions

  serialize :licenses
  serialize :requirements

  validates :number,   format: { with: /\A#{Gem::Version::VERSION_PATTERN}\z/ }
  validates :platform, format: { with: Rubygem::NAME_PATTERN }
  validates :full_name, presence: true, uniqueness: { case_sensitive: false }
  validates :rubygem, presence: true

  validate :platform_and_number_are_unique, on: :create
  validate :authors_format, on: :create
  class AuthorType < Type::String
    def cast_value(value)
      if value.is_a?(Array)
        value.join(', ')
      else
        super
      end
    end
  end
  attribute :authors, AuthorType.new

  # TODO: Remove this once we move to GemDownload only
  after_create :create_gem_download
  def create_gem_download
    GemDownload.create!(count: 0, rubygem_id: rubygem_id, version_id: id)
  end

  def self.reverse_dependencies(name)
    joins(dependencies: :rubygem)
      .indexed
      .where(rubygems: { name: name })
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

  def self.by_built_at
    order(built_at: :desc)
  end

  def self.by_earliest_built_at
    order(built_at: :asc)
  end

  def self.by_created_at
    order(created_at: :desc)
  end

  def self.rows_for_index
    joins(:rubygem)
      .indexed
      .release
      .order("rubygems.name asc, position desc")
      .pluck('rubygems.name', :number, :platform)
  end

  def self.rows_for_latest_index
    joins(:rubygem)
      .indexed
      .latest
      .order("rubygems.name asc, position desc")
      .pluck('rubygems.name', :number, :platform)
  end

  def self.rows_for_prerelease_index
    joins(:rubygem)
      .indexed
      .prerelease
      .order("rubygems.name asc, position desc")
      .pluck('rubygems.name', :number, :platform)
  end

  def self.most_recent
    latest.find_by(platform: 'ruby') || latest.order(number: :desc).first || last
  end

  # This method returns the new versions for brand new rubygems
  def self.new_pushed_versions(limit = 5)
    subquery = <<-SQL
      versions.id IN (SELECT max(versions.id)
                                FROM versions
                            GROUP BY versions.rubygem_id
                              HAVING COUNT(versions.rubygem_id) = 1)
    SQL

    Version.where(subquery).by_created_at.limit limit
  end

  def self.just_updated(limit = 5)
    subquery = <<-SQL
      versions.rubygem_id IN (SELECT versions.rubygem_id
                                FROM versions
                            GROUP BY versions.rubygem_id
                              HAVING COUNT(versions.id) > 1)
    SQL

    where(subquery)
      .joins(:rubygem)
      .indexed
      .by_created_at
      .limit(limit)
  end

  def self.published(limit)
    indexed.by_created_at.limit(limit)
  end

  def self.find_from_slug!(rubygem_id, slug)
    rubygem = rubygem_id.is_a?(Rubygem) ? rubygem_id : Rubygem.find(rubygem_id)
    find_by!(full_name: "#{rubygem.name}-#{slug}")
  end

  def self.rubygem_name_for(full_name)
    find_by(full_name: full_name).try(:rubygem).try(:name)
  end

  def platformed?
    platform != "ruby"
  end

  delegate :reorder_versions, to: :rubygem

  def can_yank?
    gem_download.count < 15_000
  end

  def yanked?
    !indexed
  end

  def size
    self[:size] || 'N/A'
  end

  def byte_size
    self[:size]
  end

  def byte_size=(bs)
    self[:size] = bs.to_i
  end

  def info
    [description, summary, "This rubygem does not have a description or summary."].find(&:present?)
  end

  def update_attributes_from_gem_specification!(spec)
    update_attributes!(
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
    gem_download.try(:count) || 0
  end

  def payload
    {
      'authors'          => authors,
      'built_at'         => built_at,
      'created_at'       => created_at,
      'description'      => description,
      'downloads_count'  => downloads_count,
      'metadata'         => metadata,
      'number'           => number,
      'summary'          => summary,
      'platform'         => platform,
      'rubygems_version' => required_rubygems_version,
      'ruby_version'     => required_ruby_version,
      'prerelease'       => prerelease,
      'licenses'         => licenses,
      'requirements'     => requirements,
      'sha'              => sha256_hex
    }
  end

  def as_json(*)
    payload
  end

  def to_xml(options = {})
    payload.to_xml(options.merge(root: 'version'))
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
    authors.split(',').flatten
  end

  def sha256_hex
    Version._sha256_hex(sha256) if sha256
  end

  def self._sha256_hex(raw)
    raw.unpack("m0").first.unpack("H*").first
  end

  def recalculate_sha256
    key = "gems/#{full_name}.gem"
    file = RubygemFs.instance.get(key)
    Digest::SHA2.base64digest(file) if file
  end

  def recalculate_sha256!
    update_attributes(sha256: recalculate_sha256)
  end

  def recalculate_metadata!
    metadata = get_spec_attribute('metadata')
    update(metadata: metadata || {})
  end

  def assign_required_rubygems_version!
    required_rubygems_version = get_spec_attribute('required_rubygems_version')
    update_column(:required_rubygems_version, required_rubygems_version.to_s)
  end

  def documentation_path
    "http://www.rubydoc.info/gems/#{rubygem.name}/#{number}"
  end

  private

  def get_spec_attribute(attribute_name)
    key = "gems/#{full_name}.gem"
    file = RubygemFs.instance.get(key)
    return nil unless file
    spec = Gem::Package.new(StringIO.new(file)).spec
    spec.send(attribute_name)
  rescue Gem::Package::FormatError
    nil
  end

  def platform_and_number_are_unique
    return unless Version.exists?(rubygem_id: rubygem_id, number: number, platform: platform)
    errors[:base] << "A version already exists with this number or platform."
  end

  def authors_format
    authors = authors_before_type_cast
    return unless authors
    string_authors = authors.is_a?(Array) && authors.grep(String)
    return unless string_authors.blank? || string_authors.size != authors.size
    errors.add :authors, "must be an Array of Strings"
  end

  def update_prerelease
    self[:prerelease] = !!to_gem_version.prerelease? # rubocop:disable Style/DoubleNegation
    true
  end

  def full_nameify!
    return if rubygem.nil?
    self.full_name = "#{rubygem.name}-#{number}"
    full_name << "-#{platform}" if platformed?
  end

  def feature_release(number)
    feature_version = Gem::Version.new(number).segments[0, 2].join('.')
    Gem::Version.new(feature_version)
  end
end
