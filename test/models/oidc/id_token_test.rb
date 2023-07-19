require "test_helper"

class OIDC::IdTokenTest < ActiveSupport::TestCase
  should belong_to :api_key_role
  should belong_to :provider
  should belong_to :api_key
  should have_one(:user)

  should validate_presence_of :jwt

  test "validates jti uniqueness" do
    api_key_role = FactoryBot.create(:oidc_api_key_role)
    id_token = FactoryBot.create(:oidc_id_token, api_key_role:)
    assert_raises(ActiveRecord::RecordInvalid) do
      pp FactoryBot.create(:oidc_id_token, provider: id_token.provider, jwt: id_token.jwt, api_key_role:)
    end
  end
end
