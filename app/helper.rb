module Gemcutter
  class Helper
    class << self
      attr_accessor :host

      def server_path(*more)
        File.join(File.dirname(__FILE__), '..', 'server', *more)
      end

      def indexer
        indexer = Gem::Indexer.new(server_path, :build_legacy => false)
        def indexer.say(message) end
        indexer
      end

      def save_gem(data)
        temp = Tempfile.new("gem")

        File.open(temp.path, 'wb') do |f|
          f.write data.read
        end

        begin
          spec = Gem::Format.from_file_by_path(temp.path).spec
          ruby_spec = spec.to_ruby
        rescue Exception => e
          puts e
          return
        end

        name = "#{spec.name}-#{spec.version}.gem"

        cache_path = Gemcutter::Helper.server_path('cache', name)
        spec_path = Gemcutter::Helper.server_path('specifications', name + "spec")

        exists = File.exists?(spec_path)

        FileUtils.cp temp.path, cache_path
        File.open(spec_path, "w") do |f|
          f.write ruby_spec
        end

        [spec, exists]
      end
    end
  end
end
