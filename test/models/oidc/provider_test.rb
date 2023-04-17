require "test_helper"

class OIDC::ProviderTest < ActiveSupport::TestCase
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
