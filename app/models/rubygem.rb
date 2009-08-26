class Rubygem < ActiveRecord::Base
  include Pacecar

  has_many :owners, :through => :ownerships, :source => :user
  has_many :ownerships
  has_many :subscribers, :through => :subscriptions, :source => :user
  has_many :subscriptions
  has_many :versions, :dependent => :destroy, :order => "built_at desc, number desc" do
    def latest
      self.find(:first, :order => "updated_at desc")
    end

    def current
      self.find(:first)
    end
  end
  has_one :linkset, :dependent => :destroy

  validates_presence_of :name
  validates_uniqueness_of :name
  validates_format_of :name, :with => /(?=[^0-9]+)/, :message => "must include at least one letter."

  named_scope :with_versions, :conditions => ["versions_count > 0"]
  named_scope :search, lambda { |query| {
    :conditions => ["upper(name) like upper(:query) or upper(versions.description) like upper(:query)", 
      {:query => "%#{query}%"}],
    :include => [:versions] }
  }

  def self.total_count
    with_versions.count
  end

  def self.latest(limit=5)
    with_versions.by_created_at(:desc).limited(limit)
  end

  def self.downloaded(limit=5)
    with_versions.by_downloads(:desc).limited(limit)
  end

  def hosted?
    !versions.count.zero?
  end

  def rubyforge_project
    versions.current ? versions.current.rubyforge_project : ""
  end

  def unowned?
    ownerships.find_by_approved(true).blank?
  end

  def owned_by?(user)
    ownerships.find_by_user_id(user.id).try(:approved) if user
  end

  def allow_push_from?(user)
    new_record? || owned_by?(user)
  end

  def to_s
    versions.current.try(:to_title) || name
  end

  def to_json
    {:name              => name,
     :downloads         => downloads,
     :version           => versions.current.number,
     :authors           => versions.current.authors,
     :info              => versions.current.info,
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

  def update_versions!(spec)
    version_number = version_number_from_spec(spec)
    version = self.versions.find_or_initialize_by_number(version_number)
    version.update_attributes_from_gem_specification!(spec)
  end

  def update_dependencies!(spec)
    version_number = version_number_from_spec(spec)
    version = self.versions.find_or_initialize_by_number(version_number)
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

  def update_attributes_from_gem_specification!(spec)
    update_versions!     spec
    update_dependencies! spec
    update_linkset!      spec

    self.save!
  end

  private

    def version_number_from_spec(spec)
      case spec.platform.to_s
        when 'ruby' then spec.version.to_s
        else "#{spec.version}-#{spec.platform}"
      end
    end

end
