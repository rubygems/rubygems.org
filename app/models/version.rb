require 'digest/sha2'

class Version < ActiveRecord::Base
  belongs_to :rubygem, touch: true
  has_many :dependencies, -> { order('rubygems.name ASC').includes(:rubygem) }, :dependent => :destroy

  before_save      :update_prerelease
  after_validation :join_authors
  after_create     :full_nameify!
  after_save       :reorder_versions

  serialize :licenses
  serialize :requirements

  validates :number,   :format => {:with => /\A#{Gem::Version::VERSION_PATTERN}\z/}
  validates :platform, :format => {:with => Rubygem::NAME_PATTERN}

  validate :platform_and_number_are_unique, :on => :create
  validate :authors_format, :on => :create
  attribute :authors, Type::Value.new

  def self.reverse_dependencies(name)
    joins({ dependencies: :rubygem }).
      where(rubygems: { name: name })
  end

  def self.owned_by(user)
    where(:rubygem_id => user.rubygem_ids)
  end

  def self.subscribed_to_by(user)
    where(:rubygem_id => user.subscribed_gem_ids).
      by_created_at
  end

  def self.with_deps
    includes(:dependencies)
  end

  def self.latest
    where(:latest => true)
  end

  def self.prerelease
    where(:prerelease => true)
  end

  def self.release
    where(:prerelease => false)
  end

  def self.indexed
    where(:indexed => true)
  end

  def self.yanked
    where(:indexed => false)
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
    joins(:rubygem).indexed.release.order("rubygems.name asc, position desc").pluck('rubygems.name', :number, :platform)
  end

  def self.rows_for_latest_index
    joins(:rubygem).indexed.latest.order("rubygems.name asc, position desc").pluck('rubygems.name', :number, :platform)
  end

  def self.rows_for_prerelease_index
    joins(:rubygem).indexed.prerelease.order("rubygems.name asc, position desc").pluck('rubygems.name', :number, :platform)
  end

  def self.most_recent
    latest.find_by(platform: 'ruby') || latest.order(number: :desc).first || last
  end

  def self.just_updated(limit=5)
    where("versions.rubygem_id IN (SELECT versions.rubygem_id FROM versions GROUP BY versions.rubygem_id HAVING COUNT(versions.id) > 1)").
      joins(:rubygem).
      indexed.
      by_created_at.
      limit(limit)
  end

  def self.published(limit)
    where("built_at <= ?", DateTime.now.utc).
      indexed.
      by_built_at.
      limit(limit)
  end

  def self.find_from_slug!(rubygem_id, slug)
    rubygem = rubygem_id.is_a?(Rubygem) ? rubygem_id : Rubygem.find(rubygem_id)
    find_by!(full_name: "#{rubygem.name}-#{slug}")
  end

  def self.rubygem_name_for(full_name)
    Redis.current.hget(info_key(full_name), :name)
  end

  def self.info_key(full_name)
    "v:#{full_name}"
  end

  def platformed?
    platform != "ruby"
  end

  def reorder_versions
    rubygem.reorder_versions
  end

  def yank!
    update!(indexed: false)
    Redis.current.lrem(Rubygem.versions_key(rubygem.name), 1, full_name)
    RubygemFs.instance.remove("gems/#{full_name}.gem")
  end

  def push
    Redis.current.lpush(Rubygem.versions_key(rubygem.name), full_name)
  end

  def yanked?
    !indexed
  end

  def size
    read_attribute(:size) || 'N/A'
  end

  def byte_size
    read_attribute(:size)
  end

  def byte_size=(bs)
    write_attribute :size, bs.to_i
  end

  def info
    [ description, summary, "This rubygem does not have a description or summary." ].detect(&:present?)
  end

  def update_attributes_from_gem_specification!(spec)
    update_attributes!(
      :authors      => spec.authors,
      :description  => spec.description,
      :summary      => spec.summary,
      :licenses     => spec.licenses,
      :metadata     => spec.metadata || {},
      :requirements => spec.requirements,
      :built_at     => spec.date,
      :ruby_version => spec.required_ruby_version.to_s,
      :indexed      => true
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
    self_version  = self.to_gem_version
    other_version = other.to_gem_version

    if self_version == other_version
      self.platform_as_number <=> other.platform_as_number
    else
      self_version <=> other_version
    end
  end

  def slug
    full_name.gsub(/^#{rubygem.name}-/, '')
  end

  def downloads_count
    Download.for(self)
  end

  def payload
    {
      'authors'         => authors,
      'built_at'        => built_at,
      'description'     => description,
      'downloads_count' => downloads_count,
      'metadata'        => metadata,
      'number'          => number,
      'summary'         => summary,
      'platform'        => platform,
      'ruby_version'    => ruby_version,
      'prerelease'      => prerelease,
      'licenses'        => licenses,
      'requirements'    => requirements,
      'sha'             => sha256_hex
    }
  end

  def as_json(options={})
    payload
  end

  def to_xml(options={})
    payload.to_xml(options.merge(:root => 'version'))
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
    %{gem '#{rubygem.name}', '~> #{number}'}
  end

  def to_gem_version
    Gem::Version.new(number)
  end

  def to_index
    [rubygem.name, to_gem_version, platform]
  end

  def to_install
    command = "gem install #{rubygem.name}"
    latest = prerelease ? rubygem.versions.by_position.prerelease.first : rubygem.versions.most_recent
    command << " -v #{number}" if latest != self
    command << " --pre" if prerelease
    command
  end

  def authors_array
    self.authors.split(',').flatten
  end

  def sha256_hex
    sha256.unpack("m0").first.unpack("H*").first if sha256
  end

  def recalculate_sha256
    key = "gems/#{full_name}.gem"
    if file = RubygemFs.instance.get(key)
      Digest::SHA2.base64digest file
    end
  end

  def recalculate_sha256!
    update_attributes(sha256: recalculate_sha256)
  end

  private

  def platform_and_number_are_unique
    if Version.exists?(:rubygem_id => rubygem_id,
                       :number     => number,
                       :platform   => platform)
      errors[:base] << "A version already exists with this number or platform."
    end
  end

  def authors_format
    string_authors = authors.is_a?(Array) && authors.grep(String)
    if string_authors.blank? || string_authors.size != authors.size
      errors.add :authors, "must be an Array of Strings"
    end
  end

  def update_prerelease
    self[:prerelease] = !!to_gem_version.prerelease?
    true
  end

  def join_authors
    self.authors = self.authors.join(', ') if self.authors.is_a?(Array)
  end

  def full_nameify!
    self.full_name = "#{rubygem.name}-#{number}"
    self.full_name << "-#{platform}" if platformed?

    Version.find(id).update_attributes(full_name: full_name)

    Redis.current.hmset(Version.info_key(full_name),
                 :name, rubygem.name,
                 :number, number,
                 :platform, platform)

    push
  end
end
