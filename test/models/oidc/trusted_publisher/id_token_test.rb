# frozen_string_literal: true

require "test_helper"

class OIDC::TrustedPublisher::IdTokenTest < ActiveSupport::TestCase
  setup do
    @id_token = build(:oidc_trusted_publisher_id_token)
  end
  subject { @id_token }

  should belong_to(:provider)
  should belong_to(:api_key).optional
  should belong_to(:asserted_owner).optional

  should validate_presence_of(:jti)
  should validate_uniqueness_of(:jti).scoped_to(:oidc_provider_id)

  test "allows the same jti for different providers" do
    existing = create(:oidc_trusted_publisher_id_token)
    other = build(:oidc_trusted_publisher_id_token, jti: existing.jti)

    assert_predicate other, :valid?
  end

  test "survives its api key being destroyed" do
    id_token = create(:oidc_trusted_publisher_id_token)
    id_token.api_key.destroy!

    assert_nil id_token.reload.api_key
  end
end
