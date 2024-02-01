require "test_helper"

class IpAddressTest < ActiveSupport::TestCase
  should validate_presence_of(:ip_address)
end
