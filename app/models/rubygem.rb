class Rubygem < ActiveRecord::Base
  include Pacecar
  sluggable_finder :name

  belongs_to :user
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

  cattr_accessor :source_index
  attr_accessor :spec, :path, :processing

  before_validation :build
  after_save :store

  named_scope :with_versions, :conditions => ["versions_count > 0"]

  def self.process(data, user)
    temp = Tempfile.new("gem")
    temp.write data
    temp.flush
    temp.close

    spec = pull_spec(temp.path)

    if spec.nil?
      return ["Gemcutter cannot process this gem. Please try rebuilding it and installing it locally to make sure it's valid.", 422]
    end

    rubygem = Rubygem.find_or_initialize_by_name(spec.name)

    if !rubygem.new_record? && !rubygem.owned_by?(user)
      return ["You do not have permission to push to this gem.", 403]
    end

    rubygem.spec = spec
    rubygem.path = temp.path
    rubygem.ownerships.build(:user => user, :approved => true) if rubygem.new_record?
    rubygem.save
    ["Successfully registered gem: #{rubygem.name} (#{rubygem.versions.latest})", 200]
  end

  def self.pull_spec(path)
    begin
      format = Gem::Format.from_file_by_path(path)
      format.spec
    rescue Exception => e
      logger.info "Problem loading gem at #{path}: #{e}"
      nil
    end
  end

  def unowned?
    ownerships.find_by_approved(true).blank?
  end

  def owned_by?(user)
    ownerships.find_by_user_id(user.id).try(:approved) if user
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

  def build
    return unless self.spec

    self.name = self.spec.name if self.name.blank?

    number = self.spec.original_name.gsub("#{self.spec.name}-", '')

    Version.destroy_all(:number => number, :rubygem_id => self.id)
    version = self.versions.build(
      :authors     => self.spec.authors.join(", "),
      :description => self.spec.description || self.spec.summary,
      :created_at  => self.spec.date,
      :number      => number)

    self.spec.dependencies.each do |dependency|
      version.dependencies.build(
        :rubygem_name => dependency.name.to_s,
        :name         => dependency.requirements_list.to_s)
    end

    self.build_linkset(:home => self.spec.homepage) if new_record?
  end

  def store
    return unless self.spec

    cache = Gemcutter.server_path('gems', "#{self.spec.original_name}.gem")
    FileUtils.cp self.path, cache
    File.chmod 0644, cache

    source_path = Gemcutter.server_path("source_index")

    if File.exists?(source_path)
      Rubygem.source_index ||= Marshal.load(File.open(source_path))
    else
      Rubygem.source_index ||= Gem::SourceIndex.new
    end

    Rubygem.source_index.add_spec self.spec, self.spec.original_name

    unless self.processing
      File.open(source_path, "wb") do |f|
        f.write Marshal.dump(Rubygem.source_index)
      end
    end

    Gemcutter.indexer.abbreviate self.spec
    Gemcutter.indexer.sanitize self.spec

    quick_path = Gemcutter.server_path("quick", "Marshal.#{Gem.marshal_version}", "#{self.spec.original_name}.gemspec.rz")

    zipped = Gem.deflate(Marshal.dump(self.spec))
    File.open(quick_path, "wb") do |f|
      f.write zipped
    end

    Gemcutter.indexer.update_index
  end
end
