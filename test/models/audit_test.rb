require "test_helper"

class AuditTest < ActiveSupport::TestCase
  should belong_to(:auditable)
  should belong_to(:admin_github_user)

  should validate_presence_of(:action)
end
