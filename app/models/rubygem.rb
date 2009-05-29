class Rubygem < ActiveRecord::Base
  belongs_to :user
  has_many :versions
  has_many :dependencies

  attr_accessor :data, :spec
  before_validation :parse_spec
  after_save :update_index

  protected
    def parse_spec
      self.spec = Gem::Format.from_file_by_path(self.data.path).spec
      self.name = spec.name

      cache = Gemcutter.server_path('gems', "#{spec.original_name}.gem")
      FileUtils.cp self.data.path, cache
      File.chmod 0644, cache

      version = self.versions.build(
        :authors     => spec.authors,
        :description => spec.description || spec.summary,
        :number      => spec.version)
    end

    def update_index
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

      Cutter.indexer.abbreviate self.spec
      Cutter.indexer.sanitize self.spec

      quick_path = Gemcutter.server_path("quick", "Marshal.#{Gem.marshal_version}", "#{self.spec.original_name}.gemspec.rz")

      zipped = Gem.deflate(Marshal.dump(self.spec))
      File.open(quick_path, "wb") do |f|
        f.write zipped
      end

      Cutter.indexer.update_index
    end
end
