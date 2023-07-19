require "test_helper"

class OIDC::ProviderTest < ActiveSupport::TestCase
  should have_many :api_key_roles
  should have_many :id_tokens
  should have_many :users

  context "with an issuer that does not match the configuration" do
    setup do
      @provider = build(:oidc_provider, configuration: { issuer: "https//example.com/other" })
    end

    should "fail to validate" do
      refute_predicate @provider, :valid?
      assert_equal ["issuer (https//example.com/other) does not match the provider issuer: #{@provider.issuer}"],
                   @provider.errors.messages[:configuration]
    end
  end
end
