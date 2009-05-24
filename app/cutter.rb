module Gem
  class Cutter
    attr_accessor :data, :error, :spec, :exists

    def initialize(data)
      self.data = data
    end

    def self.server_path(*more)
      File.join(File.dirname(__FILE__), '..', 'server', *more)
    end

    def self.indexer
      indexer = Indexer.new(server_path, :build_legacy => false)
      def indexer.say(message) end
      indexer
    end

    def self.find_all
      all_gems = Marshal.load(File.open(Cutter.server_path("latest_specs.4.8")))
      unique_gems = {}

      all_gems.each do |gem|
        key = gem.first
        version = gem[1].version
        if !unique_gems[key] || (unique_gems[key] && version > unique_gems[key][1].version)
          unique_gems[key] = gem
        end
      end

      unique_gems.values.sort { |a, b| a.first <=> b.first }
    end

    def self.find(gem)
      path = Cutter.server_path('specifications', gem + "*")
      Specification.load Dir[path].last
    end

    def self.count
      self.find_all.size
    end

    def validate
      temp = Tempfile.new("gem")

      File.open(temp.path, 'wb') do |f|
        f.write self.data.read
      end

      if File.size(temp.path).zero?
        self.error = "Empty gem cannot be processed."
        nil
      else
        temp
      end
    end

    def save(temp)
      begin
        self.spec = Format.from_file_by_path(temp.path).spec
        ruby_spec = self.spec.to_ruby
      rescue Exception => e
        puts e
        return
      end

      name = "#{self.spec.name}-#{self.spec.version}.gem"

      cache_path = Cutter.server_path('cache', name)
      spec_path = Cutter.server_path('specifications', name + "spec")

      self.exists = File.exists?(spec_path)

      FileUtils.cp temp.path, cache_path
      File.chmod 0644, cache_path
      File.open(spec_path, "w") do |f|
        f.write ruby_spec
      end
    end

    def index
      source_path = Cutter.server_path("source_index")

      if File.exists?(source_path)
        source_index = Marshal.load(File.open(source_path))
      else
        source_index = SourceIndex.new
      end

      source_index.add_spec self.spec, self.spec.original_name

      File.open(source_path, "wb") do |f|
        f.write Marshal.dump(source_index)
      end

      Cutter.indexer.abbreviate self.spec
      Cutter.indexer.sanitize self.spec

      quick_path = Cutter.server_path("quick", "Marshal.#{Gem.marshal_version}", "#{self.spec.name}-#{self.spec.version}.gemspec.rz")

      zipped = Gem.deflate(Marshal.dump(self.spec))
      File.open(quick_path, "wb") do |f|
        f.write zipped
      end
    end

    def process
      temp = validate
      unless temp.nil?
        save(temp)
        index
      end
    end
  end
end
