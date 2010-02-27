class Rubygem < ActiveRecord::Base
  include Pacecar unless Rails.env.maintenance?

  has_many :owners, :through => :ownerships, :source => :user
  has_many :ownerships, :dependent => :destroy
  has_many :subscribers, :through => :subscriptions, :source => :user
  has_many :subscriptions, :dependent => :destroy
  has_many :versions, :dependent => :destroy do
    def latest
      # try to find a ruby platform in the latest version
      latest = scopes[:latest][self]
      latest.find_by_platform('ruby') || latest.first || first
    end
  end
  has_many :web_hooks, :dependent => :destroy
  has_one :linkset, :dependent => :destroy

  validates_presence_of :name
  validates_uniqueness_of :name

  named_scope :with_versions,
    :select => 'DISTINCT rubygems.*',
    :joins => :versions
  named_scope :with_one_version,
    :select => 'rubygems.*',
    :joins => :versions,
    :group => column_names.map{ |name| "rubygems.#{name}" }.join(', '),
    :having => 'COUNT(versions.id) = 1'

  named_scope :name_is, lambda { |name| {
    :conditions => ["name = ?", name.strip],
    :limit      => 1 }
  }

  named_scope :search, lambda { |query| {
    :conditions => ["(upper(name) like upper(:query) or upper(versions.description) like upper(:query))",
      {:query => "%#{query.strip}%"}],
    :include    => [:versions],
    :having     => 'count(versions.id) > 0',
    :order      => "rubygems.downloads desc" }
  }

  def validate
    if name.class != String
      errors.add :name, "must be a String"
    elsif name =~ /^[\d]+$/
      errors.add :name, "must include at least one letter"
    elsif name =~ /[^\d\w\-\.]/
      errors.add :name, "can only include letters, numbers, dashes, and underscores"
    end
  end

  def all_errors(version = nil)
    [self, linkset, version].compact.map do |ar|
      ar.errors.full_messages
    end.flatten.join(", ")
  end

  def self.total_count
    with_versions.count
  end

  def self.latest(limit=5)
    with_one_version.by_created_at(:desc).limited(limit)
  end

  def self.downloaded(limit=5)
    with_versions.by_downloads(:desc).limited(limit)
  end

  def hosted?
    !versions.count.zero?
  end

  def unowned?
    ownerships.find_by_approved(true).blank?
  end

  def owned_by?(user)
    ownerships.find_by_user_id(user.id).try(:approved) if user
  end

  def metrics_link(project_path)
    project_url = CGI.escape(project_path)
    "http://getcaliper.com/caliper/project?repo=#{project_url}"
  end

  def to_s
    versions.latest.try(:to_title) || name
  end

  def payload(version = versions.latest, host_with_port = HOST)
    {
      'name'              => name,
      'downloads'         => downloads,
      'version'           => version.number,
      'version_downloads' => version.downloads_count,
      'authors'           => version.authors,
      'info'              => version.info,
      'project_uri'       => "http://#{host_with_port}/gems/#{name}",
      'gem_uri'           => "http://#{host_with_port}/gems/#{version.full_name}.gem",
      'dependencies'      => {
        'development' => version.dependencies.development,
        'runtime'     => version.dependencies.runtime
      }
    }
  end

  def to_json(options = {})
    payload.to_json(options)
  end

  def to_xml(options = {})
    payload.to_xml(options.merge(:root => "rubygem"))
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
    if unowned? && !user.try(:rubyforge_importer?)
      ownerships.create(:user => user, :approved => true)
    end
  end

  def update_versions!(version, spec)
    version.update_attributes_from_gem_specification!(spec)
  end

  def update_dependencies!(version, spec)
    version.dependencies.delete_all
    spec.dependencies.each do |dependency|
      version.dependencies.create_from_gem_dependency!(dependency)
    end
  end

  def update_linkset!(spec)
    self.linkset ||= Linkset.new
    self.linkset.update_attributes_from_gem_specification!(spec)
    self.linkset.save!
  end

  def update_attributes_from_gem_specification!(version, spec)
    self.save!
    update_versions!     version, spec
    update_dependencies! version, spec
    update_linkset!      spec
  end

  def reorder_versions
    numbers = self.reload.versions.sort.reverse.map(&:number).uniq

    Version.without_callbacks(:reorder_versions) do
      self.versions.each do |version|
        version.update_attribute(:position, numbers.index(version.number))
      end

      self.versions.update_all(:latest => false)

      if first_release = versions.indexed.release.first
        versions.find_all_by_number(first_release.number).each do |version|
          version.update_attributes(:latest => true)
        end
      end
    end
  end

  def yank!(version)
    version.yank!
    if versions(true).indexed.count.zero?
      ownerships.each(&:destroy_without_callbacks)
    end
  end

  def find_or_initialize_version_from_spec(spec)
    version = self.versions.find_or_initialize_by_number_and_platform(spec.version.to_s, spec.original_platform.to_s)
    version.rubygem = self
    version
  end
end
