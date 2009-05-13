$:.unshift File.expand_path(File.join(File.dirname(__FILE__), '..'))

require 'rubygems'
require 'sinatra'
require 'gemcutter'
root_dir = File.join(File.dirname(__FILE__), 'lib', 'gemcutter')

set :environment, :production
set :root, root_dir
set :app_file, File.join(root_dir, 'app.rb')
disable :run

run Gemcutter::App
