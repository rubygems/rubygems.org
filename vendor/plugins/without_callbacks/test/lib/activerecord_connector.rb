require "rubygems"
require "active_record"
require 'active_record/fixtures'

conf = YAML::load(File.open(File.dirname(__FILE__) + '/../database.yml'))
ActiveRecord::Base.establish_connection(conf['sqlite3'])