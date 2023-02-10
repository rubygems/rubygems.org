require "test_helper"

class WebauthnCredentialTest < ActiveSupport::TestCase
  subject { build(:webauthn_credential) }

  should belong_to :user
  should validate_presence_of(:external_id)
  should validate_uniqueness_of(:external_id)
  should validate_presence_of(:public_key)
  should validate_presence_of(:nickname)
  should validate_presence_of(:sign_count)
  should validate_numericality_of(:sign_count).is_greater_than_or_equal_to(0)
end
