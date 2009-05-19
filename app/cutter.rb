module Gem
  class Cutter
    attr_accessor :data

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

    def save_gem
      temp = Tempfile.new("gem")

      File.open(temp.path, 'wb') do |f|
        f.write data.read
      end

      if File.size(temp.path) == 0
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

      [spec, exists]
    end
  end
end
