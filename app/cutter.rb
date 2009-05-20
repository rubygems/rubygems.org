module Gem
  class Cutter
    attr_accessor :data, :error

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

    def self.list_gems
      cache_path = Cutter.server_path('cache', "*.gem")
      Dir[cache_path].map do |gem| 
        gem = File.basename(gem).split("-")
        "#{gem[0..-2]} (#{gem.last.chomp(".gem")})"
      end
    end

    def self.find_gem(gem)
      path = Cutter.server_path('specifications', gem + "*")
      Specification.load Dir[path].first
    end

    def save_gem
      temp = Tempfile.new("gem")

      File.open(temp.path, 'wb') do |f|
        f.write data.read
      end

      if File.size(temp.path).zero?
        self.error = "Empty gem cannot be processed."
        return
      end

      begin
        spec = Format.from_file_by_path(temp.path).spec
        ruby_spec = spec.to_ruby
      rescue Exception => e
        puts e
        return
      end

      name = "#{spec.name}-#{spec.version}.gem"

      cache_path = Cutter.server_path('cache', name)
      spec_path = Cutter.server_path('specifications', name + "spec")

      exists = File.exists?(spec_path)

      FileUtils.cp temp.path, cache_path
      File.open(spec_path, "w") do |f|
        f.write ruby_spec
      end

      # Do the indexer's work for it.
      Cutter.indexer.abbreviate spec
      Cutter.indexer.sanitize spec

      quick_path = Cutter.server_path("quick", "Marshal.#{Gem.marshal_version}", "#{spec.name}-#{spec.version}.gemspec.rz")

      zipped = Gem.deflate(Marshal.dump(spec))
      File.open(quick_path, "wb") do |f|
        f.write zipped
      end

      [spec, exists]
    end
  end
end
