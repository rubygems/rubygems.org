require "test_helper"

class AuditTest < ActiveSupport::TestCase
  should belong_to(:auditable)

  should validate_presence_of(:action)
  should validate_presence_of(:github_user_id)
  should validate_presence_of(:github_username)
end
