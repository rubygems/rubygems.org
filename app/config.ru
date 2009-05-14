$:.unshift File.expand_path(File.join(File.dirname(__FILE__)))

require 'rubygems'
require 'sinatra'
require 'app'

set :environment, :production
Gemcutter::Helper.indexer.generate_index
run Gemcutter::App
