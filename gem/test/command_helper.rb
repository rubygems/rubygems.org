require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'redgreen'
require 'active_support'
require 'active_support/test_case'
gem 'fakeweb', '>= 1.2.5'
require 'fakeweb'
require 'rr'

FakeWeb.allow_net_connect = false

$:.unshift File.expand_path(File.join(File.dirname(__FILE__), ".."))

require "rubygems_plugin"

class CommandTest < ActiveSupport::TestCase
  include RR::Adapters::TestUnit unless include?(RR::Adapters::TestUnit)
end
