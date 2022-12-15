require "test_helper"

class WebauthnVerificationTest < ActiveSupport::TestCase
  subject { build(:webauthn_verification) }

  should belong_to :user

  should validate_uniqueness_of(:user_id)
  should validate_presence_of(:path_token)
  should validate_uniqueness_of(:path_token)
  should validate_presence_of(:path_token_expires_at)
end
