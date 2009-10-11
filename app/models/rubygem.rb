class Rubygem < ActiveRecord::Base
  include Pacecar

  has_many :owners, :through => :ownerships, :source => :user
  has_many :ownerships, :dependent => :destroy
  has_many :subscribers, :through => :subscriptions, :source => :user
  has_many :subscriptions
  has_many :versions, :dependent => :destroy do
    def latest
      self.find(:first)
    end
  end
  has_one :linkset, :dependent => :destroy

  validates_presence_of :name
  validates_uniqueness_of :name

  named_scope :with_versions, :conditions => ["versions_count > 0"]
  named_scope :with_one_version, :conditions => ["versions_count = 1"]

  named_scope :search, lambda { |query| {
    :conditions => ["upper(name) like upper(:query) or upper(versions.description) like upper(:query)",
      {:query => "%#{query}%"}],
    :include    => [:versions],
    :order      => "name asc" }
  }

  def validate
    if name =~ /^[\d]+$/
      errors.add "Name must include at least one letter."
    elsif name =~ /[^\d\w_\-\.]/
      errors.add "Name can only include letters, numbers, dashes, and underscores."
    end
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

  def rubyforge_project
    versions.find(:first, :conditions => "rubyforge_project is not null").try(:rubyforge_project)
  end

  def unowned?
    ownerships.find_by_approved(true).blank?
  end

  def owned_by?(user)
    ownerships.find_by_user_id(user.id).try(:approved) if user
  end

  def to_s
    versions.latest.try(:to_title) || name
  end

  def to_json
    {:name              => name,
     :downloads         => downloads,
     :version           => versions.latest.number,
     :authors           => versions.latest.authors,
     :info              => versions.latest.info,
     :rubyforge_project => rubyforge_project}.to_json
  end

  def to_param
    name
  end

  def with_downloads
    "#{name} (#{downloads})"
  end

  def pushable?
    new_record? || versions_count.zero?
  end

  def build_ownership(user)
    ownerships.build(:user => user, :approved => true) if pushable?
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

    self.versions.each do |version|
      Version.without_callbacks(:reorder_versions) do
        version.update_attribute(:position, numbers.index(version.number))
      end
    end
  end

  def find_or_initialize_version_from_spec(spec)
    version = self.versions.find_or_initialize_by_number_and_platform(spec.version.to_s, spec.original_platform.to_s)
    version.rubygem = self
    version
  end

end
