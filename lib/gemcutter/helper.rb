module Gemcutter
  class Helper
    class << self
      def server_path(*more)
        File.join(File.dirname(__FILE__), '..', '..', 'server', *more)
      end

      def indexer
        indexer = Gem::Indexer.new(server_path, :build_legacy => false)
        def indexer.say(message) end
        indexer
      end

      def save_gem(data)
        temp = Tempfile.new(data.original_filename)
        File.open(temp.path, 'wb') do |f|
          f.write data.open.read
        end

        installer = Gem::Installer.new(temp.path, :unpack => true)
        spec = installer.spec
        name = "#{spec.name}-#{spec.version}.gem"

        cache_path = Gemcutter::Helper.server_path('cache', name)
        spec_path = Gemcutter::Helper.server_path('specifications', name + "spec")

        FileUtils.cp temp.path, cache_path
        File.open(spec_path, "w") do |f|
          f.write spec.to_ruby
        end

        Gemcutter::Helper.indexer.update_index
        spec
      end
    end
  end
end
