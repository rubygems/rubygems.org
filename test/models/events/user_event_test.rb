require "test_helper"

class Events::UserEventTest < ActiveSupport::TestCase
  should belong_to(:user)
  should belong_to(:ip_address).optional
  should belong_to(:geoip_info).optional
end
