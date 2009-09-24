require 'sinatra'
require 'rack/cache'

use Rack::Cache do
  set :verbose, true
  set :metastore,   'heap:/'
  set :entitystore, 'heap:/'

  on :receive do
    pass! if request.url =~ /favicon/
  end
end

before do
  last_modified $updated_at ||= Time.now
end

get '/' do
  erb :index
end

put '/' do
  $updated_at = nil
  redirect '/'
end
