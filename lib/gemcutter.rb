require 'rubygems'
require 'rubygems/indexer'
require 'rubygems/installer'
require 'sinatra'
require 'json'

require 'gemcutter/helper'
#require 'gemcutter/app'

Gem.configuration.verbose = false
Gemcutter::Helper.indexer.generate_index
Gemcutter::Helper.host = "http://gemcutter.org"
