require "test_helper"

class Events::UserEventTest < ActiveSupport::TestCase
  should belong_to(:user)
end
