require 'rubygems'
require 'rubygems/indexer'
require 'rubygems/installer'
require 'sinatra'
require 'json'

require 'gemcutter/helper'
require 'gemcutter/app'

set :app_file, __FILE__
Gem.configuration.verbose = false
Gemcutter::Helper.indexer.generate_index

