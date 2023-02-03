require "test_helper"

class AuditTest < ActiveSupport::TestCase
  should belong_to(:auditable)
  should validate_presence_of(:github_username)
  should validate_presence_of(:github_user_id)
end
