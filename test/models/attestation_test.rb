require "test_helper"

class AttestationTest < ActiveSupport::TestCase
  should belong_to(:version)
  should validate_presence_of(:media_type)
  should validate_presence_of(:body)
end
