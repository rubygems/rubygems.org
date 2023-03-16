require "test_helper"

class PrivacyPassTokenizerTest < ActiveSupport::TestCase
  setup do
    @tokenizer = PrivacyPassTokenizer.new
  end

  def urlsafe_base64?(value)
    value.is_a?(String) && Base64.urlsafe_encode64(Base64.urlsafe_decode64(value)) == value
  end

  context ".issuer_public_key" do
    should "return a url encoded base64 string" do
      key = PrivacyPassTokenizer.issuer_public_key

      assert urlsafe_base64?(key)
    end
  end

  context "#challenge_token" do
    should "return a url encoded base64 string" do
      token = @tokenizer.challenge_token

      assert urlsafe_base64?(token)
    end

    should "return a string of the correct length" do
      token = @tokenizer.challenge_token

      assert_equal(112, token.length)
    end
  end

  context "#register_challenge_for_redemption" do
    should "should write a digest to the cache" do
      Rails.cache.expects(:write)
        .with("#{PrivacyPassTokenizer::CHALLENGE_DIGEST_CACHE_PREFIX}1",
          regexp_matches(/[0-9a-fA-F]{32}/))

      @tokenizer.register_challenge_for_redemption(1)
    end
  end
end
