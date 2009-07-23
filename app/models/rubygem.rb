class Rubygem < ActiveRecord::Base
  include Pacecar
  sluggable_finder :name

  has_many :owners, :through => :ownerships, :source => :user
  has_many :ownerships
  has_many :versions, :dependent => :destroy, :order => "created_at desc, number desc" do
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
    :conditions => ["name like :query or versions.description like :query", 
      {:query => "%#{query}%"}],
    :include => [:versions] }
  }

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
    if versions.current
      "#{name} (#{versions.current})"
    else
      name
    end
  end

  def with_downloads
    "#{name} (#{downloads})"
  end

  def build_name(name)
    self.name = name if self.name.blank?
  end

  def build_dependencies(deps)
    deps.each do |dep|
      versions.last.dependencies.build(
        :rubygem_name => dep.name.to_s,
        :name         => dep.requirements_list.to_s)
    end
  end

  def build_version(data)
    Version.destroy_all(:number => data[:number], :rubygem_id => self.id)
    versions.build(data)
  end

  def build_links(homepage)
    if linkset
      linkset.home = homepage
    else
      build_linkset(:home => homepage)
    end
  end

  def build_ownership(user)
    ownerships.build(:user => user, :approved => true) if new_record?
  end
end
