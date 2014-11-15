class Rubygem < ActiveRecord::Base
  include Patterns

  has_many :owners, :through => :ownerships, :source => :user
  has_many :ownerships, :dependent => :destroy
  has_many :subscribers, :through => :subscriptions, :source => :user
  has_many :subscriptions, :dependent => :destroy
  has_many :versions, :dependent => :destroy, :validate => false
  has_many :web_hooks, :dependent => :destroy
  has_one :linkset, :dependent => :destroy

  validate :ensure_name_format, :if => :needs_name_validation?
  validates :name, :presence => true, :uniqueness => true

  after_create :update_unresolved
  before_destroy :mark_unresolved

  def self.with_versions
    where("rubygems.id IN (SELECT rubygem_id FROM versions where versions.indexed IS true)")
  end

  def self.with_one_version
    select('rubygems.*').
    joins(:versions).
    group(column_names.map { |name| "rubygems.#{name}" }.join(', ')).
    having('COUNT(versions.id) = 1')
  end

  def self.name_is(name)
    sensitive = where(:name => name.strip).limit(1)
    return sensitive unless sensitive.empty?

    where("UPPER(name) = UPPER(?)", name.strip).limit(1)
  end

  def self.search(query)
    conditions = <<-SQL
      versions.indexed and
        (upper(name) like upper(:query) or
         upper(translate(name, '#{SPECIAL_CHARACTERS}', '#{' ' * SPECIAL_CHARACTERS.length}')) like upper(:query))
    SQL

    where(conditions, {:query => "%#{query.strip}%"}).
      includes(:versions).
      by_downloads
  end

  def self.name_starts_with(letter)
    where("upper(name) like upper(?)", "#{letter}%")
  end

  def self.reverse_dependencies(name)
    find(Version.reverse_dependencies(name).pluck("versions.rubygem_id"))
  end

  def self.total_count
    with_versions.count
  end

  def self.latest(limit=5)
    with_one_version.order("created_at desc").limit(limit)
  end

  def self.downloaded(limit=5)
    with_versions.by_downloads.limit(limit)
  end

  def self.letter(letter)
    name_starts_with(letter).order("name asc").with_versions
  end

  def self.letterize(letter)
    letter =~ /\A[A-Za-z]\z/ ? letter.upcase : 'A'
  end

  def self.monthly_dates
    (2..31).map { |n| n.days.ago.to_date }.reverse
  end

  def self.monthly_short_dates
    monthly_dates.map { |date| date.strftime("%m/%d") }
  end

  def self.versions_key(name)
    "r:#{name}"
  end

  def self.by_downloads
    order("rubygems.downloads desc")
  end

  def self.current_rubygems_release
    if g = find_by_name("rubygems-update")
      if v = g.versions.release.indexed.by_created_at.first
        v.number
      else
        "0.0.0"
      end
    else
      "0.0.0"
    end
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
    ownerships.find_by_user_id(user.id) if user
  end

  def to_s
    versions.most_recent.try(:to_title) || name
  end

  def downloads
    Download.for(self)
  end

  def downloads_today
    versions.to_a.sum {|v| Download.today(v) }
  end

  def payload(version=versions.most_recent, host_with_port=HOST)
    {
      'name'              => name,
      'downloads'         => downloads,
      'version'           => version.number,
      'version_downloads' => version.downloads_count,
      'platform'          => version.platform,
      'authors'           => version.authors,
      'info'              => version.info,
      'licenses'          => version.licenses,
      'project_uri'       => "http://#{host_with_port}/gems/#{name}",
      'gem_uri'           => "http://#{host_with_port}/gems/#{version.full_name}.gem",
      'gem_sha256'        => version.sha256,
      'homepage_uri'      => linkset.try(:home),
      'wiki_uri'          => linkset.try(:wiki),
      'documentation_uri' => linkset.try(:docs),
      'mailing_list_uri'  => linkset.try(:mail),
      'source_code_uri'   => linkset.try(:code),
      'bug_tracker_uri'   => linkset.try(:bugs),
      'dependencies'      => {
        'development' => version.dependencies.development.to_a,
        'runtime'     => version.dependencies.runtime.to_a
      }
    }
  end

  def as_json(options={})
    payload
  end

  def to_xml(options={})
    payload.to_xml(options.merge(:root => 'rubygem'))
  end

  def to_param
    name
  end

  def with_downloads
    "#{name} (#{downloads})"
  end

  def pushable?
    new_record? || versions.indexed.count.zero?
  end

  def create_ownership(user)
    ownerships.create(:user => user) if unowned?
  end

  def update_versions!(version, spec)
    version.update_attributes_from_gem_specification!(spec)
  end

  def update_dependencies!(version, spec)
    spec.dependencies.each do |dependency|
      version.dependencies.create!(:gem_dependency => dependency)
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
      update_versions!     version, spec
      update_dependencies! version, spec
      update_linkset!      spec
    end
  end

  delegate :count,
    :to => :versions,
    :prefix => true

  def yanked_versions?
    versions.yanked.exists?
  end

  def reorder_versions
    numbers = self.reload.versions.sort.reverse.map(&:number).uniq

    self.versions.each do |version|
      Version.update_all({:position => numbers.index(version.number)}, {:id => version.id})
    end

    self.versions.update_all(:latest => false)

    self.versions.release.indexed.inject(Hash.new{|h, k| h[k] = []}) do |platforms, version|
      platforms[version.platform] << version
      platforms
    end.each_value do |platforms|
      Version.update_all({:latest => true}, {:id => platforms.sort.last.id})
    end
  end

  def disown
    ownerships.each(&:delete)
    ownerships.clear
  end

  def find_version_from_spec(spec)
    self.versions.find_by_number_and_platform(spec.version.to_s, spec.original_platform.to_s)
  end

  def find_or_initialize_version_from_spec(spec)
    version = self.versions.find_or_initialize_by_number_and_platform(spec.version.to_s, spec.original_platform.to_s)
    version.rubygem = self
    version
  end

  def monthly_downloads
    key_dates = self.class.monthly_dates.map(&:to_s)
    $redis.hmget(Download.history_key(self), *key_dates).map(&:to_i)
  end

  def first_built_date
    versions.by_earliest_built_at.limit(1).last.built_at
  end

  def gittip_url
    'https://www.gittip.com/on/rubygems/gem/' + name + '/'
  end

  def gittip_enabled?
    owners.where('gittip_username is not null').count > 0
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
    Dependency.where(:unresolved_name => name).each do |dependency|
      dependency.update_resolved(self)
    end

    true
  end

  def mark_unresolved
    Dependency.mark_unresolved_for(self)
    true
  end
end
