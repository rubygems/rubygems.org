require 'rubygems'
require 'lib/gemcutter'
set :run, false
set :environment, :production
run Gemcutter::App
