require "test_helper"

class PrivacyPassRedeemerTest < ActiveSupport::TestCase
  def generate_token_type(val = 2)
    [val].pack("n*")
  end

  def generate_nonce(val = SecureRandom.hex(16))
    val.bytes.pack("C*")
  end

  def generate_challenge_digest(val = SecureRandom.hex(32))
    hex = [val].pack("H*")
    hex.bytes.pack("C*")
  end

  def generate_token_key_id(val = SecureRandom.hex(16))
    val.bytes.pack("C*")
  end

  def generate_authenticator(public_key, token_type, nonce, challenge_digest, token_key_id)
    data = token_type + nonce + challenge_digest + token_key_id
    signature = public_key.sign(nil, data)
    signature.bytes.pack("C*")
  end

  def base64_public_key(rsa_key)
    rsa_key.public_key.to_pem.gsub(/^-*BEGIN PUBLIC KEY-*\n/, "").gsub(/\n-*END PUBLIC KEY-*\n$/, "")
  end

  def encode(val)
    Base64.urlsafe_encode64(val)
  end

  setup do
    @rsa_keypair = OpenSSL::PKey::RSA.new 4096

    @token_type = generate_token_type
    @nonce = generate_nonce
    @challenge_digest = generate_challenge_digest
    @token_key_id = generate_token_key_id
    @authenticator = generate_authenticator(@rsa_keypair, @token_type, @nonce, @challenge_digest, @token_key_id)
  end

  context "#redeem" do
    should "return false with a missing authorization header" do
      refute PrivacyPassRedeemer.call(nil, 1)
    end

    should "return false with a malformed authorization header" do
      token = encode("#{@token_type}#{@nonce}#{@challenge_digest}#{@token_key_id}#{@authenticator}")
      # missing 'PrivateToken token='
      auth_header = token

      refute PrivacyPassRedeemer.call(auth_header, 1)
    end

    should "return false when token type is not 2 (publicly verifiable RSA Blind Signatures)" do
      invalid_token_type = generate_token_type(1)
      new_authenticator = generate_authenticator(@rsa_keypair, invalid_token_type, @nonce, @challenge_digest, @token_key_id)

      token = encode("#{invalid_token_type}#{@nonce}#{@challenge_digest}#{@token_key_id}#{new_authenticator}")
      auth_header = "PrivateToken token=#{token}"

      refute PrivacyPassRedeemer.call(auth_header, 1)
    end

    should "return false when the token is not the correct length" do
      invalid_nonce = generate_nonce(SecureRandom.hex(10))
      new_authenticator = generate_authenticator(@rsa_keypair, @token_type, invalid_nonce, @challenge_digest, @token_key_id)

      token = encode("#{@token_type}#{invalid_nonce}#{@challenge_digest}#{@token_key_id}#{new_authenticator}")
      auth_header = "PrivateToken token=#{token}"

      refute PrivacyPassRedeemer.new(auth_header, 1).redeem
    end

    should "return false when the token did not get registered for redemption with this server" do
      token = encode("#{@token_type}#{@nonce}#{@challenge_digest}#{@token_key_id}#{@authenticator}")
      auth_header = "PrivateToken token=#{token}"

      refute PrivacyPassRedeemer.new(auth_header, 1).redeem
    end

    should "return false when the token cannot be verified with the issuer's public key" do
      challenge_digest_val = SecureRandom.hex(32)
      Rails.cache.write("#{PrivacyPassTokenizer::CHALLENGE_DIGEST_CACHE_PREFIX}1", challenge_digest_val)

      unexpected_rsa_keypair = OpenSSL::PKey::RSA.new 4096
      PrivacyPassTokenizer.expects(:issuer_public_key).returns(base64_public_key(unexpected_rsa_keypair))

      unregistered_challenge_digest = generate_challenge_digest(challenge_digest_val)
      new_authenticator = generate_authenticator(@rsa_keypair, @token_type, @nonce, unregistered_challenge_digest, @token_key_id)

      token = encode("#{@token_type}#{@nonce}#{unregistered_challenge_digest}#{@token_key_id}#{new_authenticator}")
      auth_header = "PrivateToken token=#{token}"

      refute PrivacyPassRedeemer.new(auth_header, 1).redeem
    end

    should "return true when the token can be verified with the issuer's public key" do
      challenge_digest_val = SecureRandom.hex(32)
      Rails.cache.write("#{PrivacyPassTokenizer::CHALLENGE_DIGEST_CACHE_PREFIX}1", challenge_digest_val)

      PrivacyPassTokenizer.expects(:issuer_public_key).returns(base64_public_key(@rsa_keypair))

      registered_challenge_digest = generate_challenge_digest(challenge_digest_val)
      new_authenticator = generate_authenticator(@rsa_keypair, @token_type, @nonce, registered_challenge_digest, @token_key_id)

      token = encode("#{@token_type}#{@nonce}#{registered_challenge_digest}#{@token_key_id}#{new_authenticator}")
      auth_header = "PrivateToken token=#{token}"

      assert PrivacyPassRedeemer.new(auth_header, 1).redeem
    end

    should "return false when trying to redeem a token multiple times" do
      challenge_digest_val = SecureRandom.hex(32)
      Rails.cache.write("#{PrivacyPassTokenizer::CHALLENGE_DIGEST_CACHE_PREFIX}1", challenge_digest_val)

      PrivacyPassTokenizer.expects(:issuer_public_key).returns(base64_public_key(@rsa_keypair))

      registered_challenge_digest = generate_challenge_digest(challenge_digest_val)
      new_authenticator = generate_authenticator(@rsa_keypair, @token_type, @nonce, registered_challenge_digest, @token_key_id)

      token = encode("#{@token_type}#{@nonce}#{registered_challenge_digest}#{@token_key_id}#{new_authenticator}")
      auth_header = "PrivateToken token=#{token}"

      assert PrivacyPassRedeemer.new(auth_header, 1).redeem
      refute PrivacyPassRedeemer.new(auth_header, 1).redeem
    end
  end
end
