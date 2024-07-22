require "test_helper"

class IpAddressTest < ActiveSupport::TestCase
  subject { create(:ip_address) }

  should validate_presence_of(:ip_address)
  should validate_uniqueness_of(:ip_address)
  should validate_uniqueness_of(:hashed_ip_address)
end
