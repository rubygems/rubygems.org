require 'rubygems'
require 'rubygems/indexer'
require 'rubygems/installer'
require 'sinatra'

set :app_file, __FILE__

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

  Gem.configuration.verbose = false
  indexer = Gem::Indexer.new(Gemcutter.server_path)
  class << indexer
    def say(message = "")
    end
  end
  indexer.generate_index

  content_type "text/plain"
  status(201)
  "#{name} registered."
end

class Gemcutter
  def self.server_path(*more)
    File.join(File.dirname(__FILE__), 'server', *more)
  end
end
