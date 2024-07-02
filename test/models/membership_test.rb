require "test_helper"

class MembershipTest < ActiveSupport::TestCase
  should belong_to(:org)
  should belong_to(:user)
end
