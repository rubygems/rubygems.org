$:.unshift File.expand_path(File.dirname(__FILE__))

require 'rubygems'
require 'sinatra'
require 'json'
require 'haml'

require 'cutter'
require 'indexer'
Gem.configuration.verbose = false

module Gem
  class App < Sinatra::Default
    set :app_file, __FILE__

    get '/' do
      @count = Cutter.count
      haml :index
    end

    get '/gems' do
      @gems = Cutter.find_all
      haml :gems
    end

    get '/gems/:gem' do
      @gem = Cutter.find(params[:gem])
      haml :gem
    end

    post '/gems' do
      cutter = Cutter.new(request.body)
      cutter.process
      Cutter.indexer.update_index

      content_type "text/plain"

      if cutter.exists
        status(200)
        "Gem '#{cutter.spec.name}' version #{cutter.spec.version} updated."
      else
        status(201)
        "New gem '#{cutter.spec.name}' registered."
      end
    end

    helpers do
      def title
        "gemcutter"
      end

      def subtitle
        "kickass gem hosting"
      end

      # Thanks, ActionView!
      def number_with_delimiter(number, delimiter = ',', separator = ' ')
        begin
          parts = number.to_s.split('.')
          parts[0].gsub!(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1#{delimiter}")
          parts.join(separator)
        rescue
          number
       end
      end
    end
  end
end
