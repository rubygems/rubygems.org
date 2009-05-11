require 'sinatra'
require File.join(File.dirname(__FILE__), 'helper')

set :app_file, __FILE__

get '/' do
  haml :index
end

get '/gems' do
  cache_path = Gemcutter::Helper.server_path('cache', "*.gem")
  @gems = Dir[cache_path].map do |gem| 
    gem = File.basename(gem).split("-")
    "#{gem[0..-2]} (#{gem.last.chomp(".gem")})"
  end
  haml :gems
end

get '/gems/:gem' do
  gem = Gemcutter::Helper.server_path('specifications', params[:gem] + "*")
  spec = Gem::Specification.load Dir[gem].first

  content_type "application/json"
  { :name => spec.name, :version => spec.version }.to_json
end

post '/gems' do
  spec = Gemcutter::Helper.save_gem(request.env["rack.input"])

  content_type "text/plain"
  status(201)
  "New gem '#{spec.name}' registered."
end

put '/gems/:gem' do
  spec = Gemcutter::Helper.save_gem(request.env["rack.input"])

  content_type "text/plain"
  status(200)
  "Gem '#{spec.name}' version #{spec.version} updated."
end
