require "test_helper"

class Events::RubygemEventTest < ActiveSupport::TestCase
  should belong_to(:rubygem)
  should belong_to(:ip_address).optional
  should belong_to(:geoip_info).optional
  should validate_presence_of(:tag)
  should validate_inclusion_of(:tag).in_array(Events::RubygemEvent.tags.keys)
end
