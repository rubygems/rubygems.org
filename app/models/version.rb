class Version < ActiveRecord::Base
  include Pacecar unless Rails.env.maintenance?

  default_scope :order => 'position'

  belongs_to :rubygem
  has_many :dependencies, :dependent => :destroy
  has_many :downloads, :dependent => :destroy

  validates_format_of :number, :with => /^#{Gem::Version::VERSION_PATTERN}$/

  named_scope :owned_by, lambda { |user|
    { :conditions => { :rubygem_id => user.rubygem_ids } }
  }

  named_scope :subscribed_to_by, lambda { |user|
    { :conditions => { :rubygem_id => user.subscribed_gem_ids },
      :order => 'created_at desc' }
  }

  named_scope :with_associated, {
    :conditions => ["versions.rubygem_id IN (SELECT versions.rubygem_id FROM versions GROUP BY versions.rubygem_id HAVING COUNT(versions.id) > 1)"],
    :include    => :rubygem,
    :order      => "versions.built_at desc"
  }

  named_scope :latest,     { :conditions => { :latest       => true  }}
  named_scope :with_deps,  { :include    => { :dependencies => :rubygem }}
  named_scope :prerelease, { :conditions => { :prerelease   => true  }}
  named_scope :release,    { :conditions => { :prerelease   => false }}

  before_save :update_prerelease
  after_save  :reorder_versions
  after_save  :full_nameify!

  def validate_on_create
    if Version.exists?(:rubygem_id => rubygem_id,
                       :number     => number,
                       :platform   => platform)
      errors.add_to_base("A version already exists with this number or platform.")
    end

    if !authors.is_a?(Array) || authors.any? { |a| !a.is_a?(String) }
      errors.add :authors, "must be an Array of Strings"
    end
  end

  def after_validation
    self.authors = self.authors.join(', ') if self.authors.is_a?(Array)
  end

  def self.with_indexed(reverse = false)
    order =  "rubygems.name asc"
    order << ", position desc" if reverse

    all :conditions => {:indexed => true},
        :include    => :rubygem,
        :order      => order
  end

  def self.updated(limit=5)
    built_at_before(DateTime.now.utc).with_associated.limited(limit)
  end

  def self.published(limit=5)
    created_at_before(DateTime.now.utc).by_created_at(:desc).limited(limit)
  end

  def self.find_from_slug!(rubygem_id, slug)
    rubygem = Rubygem.find(rubygem_id)
    find_by_full_name!("#{rubygem.name}-#{slug}")
  end

  def self.platforms
    find(:all, :select => 'platform').map(&:platform).uniq
  end

  def platformed?
    platform != "ruby"
  end

  def update_prerelease
    self[:prerelease] = to_gem_version.prerelease?
    true
  end

  def reorder_versions
    rubygem.reorder_versions
  end

  def yank!
    update_attributes!(:indexed => false)
  end

  def yanked?
    !indexed
  end

  def info
    [ description, summary, "This rubygem does not have a description or summary." ].detect(&:present?)
  end

  def update_attributes_from_gem_specification!(spec)
    self.update_attributes!(
      :authors           => spec.authors,
      :description       => spec.description,
      :summary           => spec.summary,
      :built_at          => spec.date,
      :indexed           => true
    )
  end

  def platform_as_number
    case self.platform
      when 'ruby' then 1
      else             0
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

  def built_at_date
    built_at.to_date.to_formatted_s(:long)
  end

  def full_nameify!
    full_name = "#{rubygem.name}-#{number}"
    full_name << "-#{platform}" if platformed?

    Version.without_callbacks do
      update_attribute(:full_name, full_name)
    end
  end

  def slug
    full_name.gsub(/^#{rubygem.name}-/, '')
  end

  def to_s
    number
  end

  def to_title
    "#{rubygem.name} (#{to_s})"
  end

  def to_gem_version
    Gem::Version.new(number)
  end

  def to_index
    [rubygem.name, to_gem_version, platform]
  end

  def to_install
    command = "gem install #{rubygem.name}"
    latest = prerelease ? rubygem.versions.prerelease.first : rubygem.versions.latest
    command << " -v #{number}" if latest != self
    command << " --pre" if prerelease
    command
  end

  def to_spec
    Gem::Specification.new do |spec|
      spec.name        = rubygem.name
      spec.version     = to_gem_version
      spec.authors     = authors.split(', ')
      spec.date        = built_at
      spec.description = description
      spec.summary     = summary

      dependencies.each do |dep|
        spec.add_dependency(dep.rubygem.name, dep.requirements.split(', '))
      end
    end
  end
end
