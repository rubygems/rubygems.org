require 'rubygems'
require 'rubygems/indexer'
require 'rubygems/installer'
require 'sinatra'
require 'json'

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

    def save_gem(data)
      temp = Tempfile.new(data.original_filename)
      File.open(temp.path, 'wb') do |f|
        f.write data.open.read
      end

      installer = Gem::Installer.new(temp.path, :unpack => true)
      spec = installer.spec

      cache_path = Gemcutter.server_path('cache', spec.name)
      spec_path = Gemcutter.server_path('specifications', spec.name + "spec")

      FileUtils.cp temp.path, cache_path
      File.open(spec_path, "w") do |f|
        f.write spec.to_ruby
      end

      Gemcutter.indexer.update_index
      spec
    end
  end
end

set :app_file, __FILE__
Gem.configuration.verbose = false
Gemcutter.indexer.generate_index

get '/gems/:gem' do
  gem = Gemcutter.server_path('specifications', params[:gem] + "*")
  spec = Gem::Specification.load Dir[gem].first

  content_type "application/json"
  { :name => spec.name, :version => spec.version }.to_json
end

post '/gems' do
  spec = Gemcutter.save_gem(request.env["rack.input"])

  content_type "text/plain"
  status(201)
  "New gem '#{spec.name}' registered."
end

put '/gems/:gem' do
  name = Gemcutter.save_gem(request.env["rack.input"])
end
