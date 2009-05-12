require 'rubygems'
require 'rubygems/indexer'
require 'rubygems/installer'
require 'sinatra'
require 'json'
require 'haml'

require 'gemcutter/app'
require 'gemcutter/helper'

module Gemcutter
end

Gem.configuration.verbose = false
Gemcutter::Helper.indexer.generate_index
