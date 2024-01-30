require "test_helper"

class Events::RubygemEventTest < ActiveSupport::TestCase
  should belong_to(:rubygem)
  should belong_to(:ip_address).optional
end
