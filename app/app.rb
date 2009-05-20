$:.unshift File.expand_path(File.dirname(__FILE__))

require 'rubygems'
require 'rubygems/indexer'
require 'rubygems/installer'
require 'sinatra'
require 'json'
require 'haml'

require 'cutter'
Gem.configuration.verbose = false

module Gem
  class App < Sinatra::Default
    set :app_file, __FILE__

    get '/' do
      haml :index
    end

    get '/gems' do
      @gems = Cutter.list_gems
      haml :gems
    end

    get '/gems/:gem' do
      @gem = Cutter.find_gem(params[:gem])
      haml :gem
    end

    post '/gems' do
      spec, exists = Cutter.new(request.body).save_gem
      Cutter.indexer.update_index

      content_type "text/plain"

      if exists
        status(200)
        "Gem '#{spec.name}' version #{spec.version} updated."
      else
        status(201)
        "New gem '#{spec.name}' registered."
      end
    end
  end
end
