require "test_helper"

class OIDC::IdTokenTest < ActiveSupport::TestCase
  should belong_to :api_key_role
  should belong_to :provider
  should belong_to :api_key
  should have_one(:user)

  should validate_presence_of :jwt

  test "validates jti uniqueness" do
    id_token = FactoryBot.create(:oidc_id_token)
    assert_raises(ActiveRecord::RecordInvalid) do
      pp FactoryBot.create(:oidc_id_token, provider: id_token.provider, jwt: id_token.jwt)
    end
  end
end
