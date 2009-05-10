require 'rubygems'
require 'rubygems/indexer'
require 'rubygems/installer'
require 'sinatra'

class Gemcutter
  class << self
    def server_path(*more)
      File.join(File.dirname(__FILE__), 'server', *more)
    end

    def indexer
      indexer = Gem::Indexer.new(server_path, :build_legacy => false)
      def indexer.say(message) end
      indexer
    end
  end
end

set :app_file, __FILE__
Gem.configuration.verbose = false
Gemcutter.indexer.generate_index

post '/gems' do
  name = request.body.original_filename
  cache_path = Gemcutter.server_path('cache', name)
  spec_path = Gemcutter.server_path('specifications', name + "spec")

  File.open(cache_path, "wb") do |f|
    f.write request.env["rack.input"].open.read
  end

  installer = Gem::Installer.new(cache_path, :unpack => true)
  File.open(spec_path, "w") do |f|
    f.write installer.spec.to_ruby
  end

  Gemcutter.indexer.update_index

  content_type "text/plain"
  status(201)
  "#{name} registered."
end

