$:.unshift File.expand_path(File.join(File.dirname(__FILE__)))

require 'rubygems'
require 'sinatra'
require 'site'

set :environment, :production
run Gem::Site
