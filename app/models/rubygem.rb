class Rubygem < ActiveRecord::Base
  belongs_to :user
  has_many :versions
  has_many :dependencies

  validates_presence_of :name
  validates_uniqueness_of :name

  attr_accessor :spec, :path
  before_validation :build
  after_save :store

  default_scope :order => 'name ASC'

  def self.pull_spec(data)
    Gem::Format.from_file_by_path(data.path).spec
  end

  def to_s
    name
  end

  def to_param
    name.gsub(/[^\w_-]/, "")
  end

  protected
    def build
      return unless self.spec

      self.name = self.spec.name if self.name.blank?

      version = self.versions.build(
        :authors     => self.spec.authors.join(", "),
        :description => self.spec.description || self.spec.summary,
        :created_at  => self.spec.date,
        :number      => self.spec.version.to_s)
    end

    def store
      cache = Gemcutter.server_path('gems', "#{self.spec.original_name}.gem")
      FileUtils.cp self.path, cache
      File.chmod 0644, cache

      source_path = Gemcutter.server_path("source_index")

      if File.exists?(source_path)
        source_index = Marshal.load(File.open(source_path))
      else
        source_index = Gem::SourceIndex.new
      end

      source_index.add_spec self.spec, self.spec.original_name

      File.open(source_path, "wb") do |f|
        f.write Marshal.dump(source_index)
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
