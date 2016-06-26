class Rubygem < ActiveRecord::Base
  include Patterns
  include RubygemSearchable

  has_many :owners, through: :ownerships, source: :user
  has_many :ownerships, dependent: :destroy
  has_many :subscribers, through: :subscriptions, source: :user
  has_many :subscriptions, dependent: :destroy
  has_many :versions, dependent: :destroy, validate: false
  has_one :latest_version, -> { where(latest: true).order(:position) }, class_name: "Version"
  has_many :web_hooks, dependent: :destroy
  has_one :linkset, dependent: :destroy
  has_one :gem_download, -> { where(version_id: 0) }

  validate :ensure_name_format, if: :needs_name_validation?
  validates :name,
    presence: true,
    uniqueness: true,
    exclusion: { in: GEM_NAME_BLACKLIST, message: "'%{value}' is a reserved gem name." }

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

  def self.reverse_dependencies(name)
    where(id: Version.reverse_dependencies(name).select(:rubygem_id))
  end

  def self.reverse_development_dependencies(name)
    where(id: Version.reverse_development_dependencies(name).select(:rubygem_id))
  end

  def self.reverse_runtime_dependencies(name)
    where(id: Version.reverse_runtime_dependencies(name).select(:rubygem_id))
  end

  def self.total_count
    with_versions.count
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

  def all_errors(version = nil)
    [self, linkset, version].compact.map do |ar|
      ar.errors.full_messages
    end.flatten.join(", ")
  end

  def public_versions(limit = nil)
    versions.by_position.published(limit)
  end

  def public_versions_with_extra_version(extra_version)
    versions = public_versions(5)
    versions << extra_version
    versions.uniq.sort_by(&:position)
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

  def payload(version = versions.most_recent, protocol = Gemcutter::PROTOCOL, host_with_port = Gemcutter::HOST)
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
      'homepage_uri'      => linkset.try(:home),
      'wiki_uri'          => linkset.try(:wiki),
      'documentation_uri' => linkset.try(:docs).presence || version.documentation_path,
      'mailing_list_uri'  => linkset.try(:mail),
      'source_code_uri'   => linkset.try(:code),
      'bug_tracker_uri'   => linkset.try(:bugs),
      'dependencies'      => {
        'development' => deps.select { |r| r.rubygem && 'development' == r.scope },
        'runtime'     => deps.select { |r| r.rubygem && 'runtime' == r.scope }
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
    new_record? || versions.indexed.count.zero?
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
      update_linkset! spec
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
      Version.find(platforms.sort.last.id).update_column(:latest, true)
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

  def first_built_date
    versions.by_earliest_built_at.limit(1).last.built_at
  end

  def self.ordered_names
    names = Rails.cache.read('names')
    if names
      StatsD.increment "compact_index.memcached.names.hit"
      response
    else
      StatsD.increment "compact_index.memcached.names.miss"
      names = order("name").pluck("name")
      Rails.cache.write('names', names)
      names
    end
  end

  def self.compact_index_versions(date)
    versions_after_date = Rails.cache.read('versions')
    if versions_after_date
      StatsD.increment "compact_index.memcached.versions.hit"
      versions_after_date
    else
      StatsD.increment "compact_index.memcached.versions.miss"
      versions_after_date = versions_after(date)
      Rails.cache.write('versions', versions_after_date)
      versions_after_date
    end
  end

  def compact_index_info
    info = Rails.cache.read("info/#{name}")
    if info
      StatsD.increment "compact_index.memcached.info.hit"
      info
    else
      StatsD.increment "compact_index.memcached.info.miss"
      compute_compact_index_info.tap do |info|
        Rails.cache.write("info/#{name}", info)
      end
    end
  end

  private

  def ensure_name_format
    if name.class != String
      errors.add :name, "must be a String"
    elsif name !~ /[a-zA-Z]+/
      errors.add :name, "must include at least one letter"
    elsif name !~ NAME_PATTERN
      errors.add :name, "can only include letters, numbers, dashes, and underscores"
    end
  end

  def needs_name_validation?
    new_record? || name_changed?
  end

  def update_unresolved
    Dependency.where(unresolved_name: name).find_each do |dependency|
      dependency.update_resolved(self)
    end

    true
  end

  def mark_unresolved
    Dependency.mark_unresolved_for(self)
    true
  end

  def compute_compact_index_info
    group_by_columns =
      "number, platform, sha256, info_checksum, required_ruby_version, required_rubygems_version, versions.created_at"
    dep_req_agg =
      "string_agg(dependencies.requirements, '@' order by rubygems_dependencies.name)"
    dep_name_agg =
      "string_agg(coalesce(rubygems_dependencies.name, '0'), ',' order by rubygems_dependencies.name) as dep_name"

    result = Rubygem.includes(versions: { dependencies: :rubygem })
      .where("rubygems.name = ? and indexed = true and (scope = 'runtime' or scope is null)", name)
      .group(group_by_columns)
      .order("versions.created_at, number, platform, dep_name")
      .pluck("#{group_by_columns}, #{dep_req_agg}, #{dep_name_agg}")

    result.map do |r|
      deps = []
      if r[7]
        reqs = r[7].split('@')
        dep_names = r[8].split(',')
        raise 'BUG: different size of reqs and dep_names.' unless reqs.size == dep_names.size
        dep_names.zip(reqs).each do |name, req|
          deps << CompactIndex::Dependency.new(name, req) unless name == '0'
        end
      end

      CompactIndex::GemVersion.new(r[0], r[1], Version._sha256_hex(r[2]), r[3], deps, r[4], r[5])
    end
  end

  private_class_method def self.versions_after(date)
    query = ["(SELECT r.name, v.created_at as date, v.info_checksum, v.number, v.platform
              FROM rubygems AS r, versions AS v
              WHERE v.rubygem_id = r.id AND
                    v.created_at > ?)
              UNION
              (SELECT r.name, v.yanked_at as date, v.info_checksum, '-'||v.number, v.platform
              FROM rubygems AS r, versions AS v
              WHERE v.rubygem_id = r.id AND
                    v.indexed is false AND
                    v.yanked_at > ?)
              ORDER BY date, number, platform, name", date, date]
    sanitize_sql = ActiveRecord::Base.send(:sanitize_sql_array, query)
    gems = ActiveRecord::Base.connection.execute(sanitize_sql)

    gems.map do |gem|
      CompactIndex::Gem.new(gem['name'], [
                              CompactIndex::GemVersion.new(
                                gem['number'],
                                gem['platform'],
                                nil,
                                gem['info_checksum']
                              )
                            ])
    end
  end
end
