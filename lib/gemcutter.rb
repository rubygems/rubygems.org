$:.unshift File.expand_path(File.dirname(__FILE__))

require 'rubygems'
require 'rubygems/indexer'
require 'rubygems/installer'
require 'sinatra'
require 'json'
require 'haml'

require 'gemcutter/helper'
require 'gemcutter/app'

module Gemcutter
end

Gem.configuration.verbose = false
Gemcutter::Helper.indexer.generate_index
