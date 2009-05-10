require 'rubygems'
require 'sinatra'
require 'haml'

set :app_file, __FILE__

get '/' do
  haml :index
end

post '/gems' do
  path = Gemcutter.server_path('cache', request.body.original_filename)

  File.open(path, "wb") do |f|
    f.write request.read
  end
end

class Gemcutter
  def self.server_path(*more)
    File.join(File.dirname(__FILE__), 'server', *more)
  end
end
