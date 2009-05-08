require 'rubygems'
require 'sinatra'
require 'haml'

set :app_file, __FILE__

get '/' do
  haml :index
end

post '/gems' do
end
