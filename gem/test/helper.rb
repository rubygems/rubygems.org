require 'rubygems'
require 'test/unit'

require 'shoulda'
require 'active_support'
require 'active_support/test_case'
require 'webmock'
require 'rr'

begin
  require 'redgreen'
rescue LoadError
end

WebMock.disable_net_connect!(:allow => 'localhost:8981')

class CommandTest < ActiveSupport::TestCase
  include RR::Adapters::TestUnit unless include?(RR::Adapters::TestUnit)
  include WebMock

  def teardown
    reset_webmock
  end
end

def stub_api_key(api_key)
  file = Gem::ConfigFile.new({})
  stub(file).rubygems_api_key { api_key }
  stub(Gem).configuration { file }
end

def assert_said(command, what)
  assert_received(command) do |command|
    command.say(what)
  end
end

def assert_never_said(command, what)
  assert_received(command) do |command|
    command.say(what).never
  end
end
