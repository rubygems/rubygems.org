# frozen_string_literal: true

# The TokenChallenge structure contains the type of token, the hostname of the issuer,
# an optional context to bind to your challenge, and the hostname of your server.
# iOS 16 and macOS Ventura support token type 2, which uses publicly verifiable RSA Blind Signatures.

# struct {
#     uint16_t token_type;               // 0x0002, in network-byte order
#     uint16_t issuer_name_length;       // Issuer name length, in network-byte order
#     char issuer_name[];                // Hostname of the token issuer
#     uint8_t redemption_context_length; // Redemption context length (0 or 32)
#     uint8_t redemption_context[];      // Redemption context, either 0 or 32 bytes
#     uint16_t origin_info_length;       // Origin info length, in network-byte order
#     char origin_info[];                // Hostname of your server
# } TokenChallenge;

class PrivacyPassTokenizer
  TOKEN_TYPE = 2
  CHALLENGE_DIGEST_CACHE_PREFIX = "privacy_pass_challenge_digest_"

  # Base64 url encoded
  def self.issuer_public_key
    Rails.application.secrets.privacy_pass_issuer_public_key
  end

  def challenge_token
    Base64.urlsafe_encode64(raw_challenge_token)
  end

  def register_challenge_for_redemption(session_id)
    digest = Digest::SHA256.hexdigest(Base64.urlsafe_decode64(challenge_token))

    Rails.cache.write("#{CHALLENGE_DIGEST_CACHE_PREFIX}#{session_id}", digest)
  end

  private

  REDEMPTION_CONTEXT_LENGTH = 32

  def raw_challenge_token
    "#{token_type}#{issuer_name_length}#{issuer_name}#{redemption_context_length}#{redemption_context}#{origin_info_length}#{origin_info}"
  end

  def token_type
    as_unsigned_16_bit([TOKEN_TYPE])
  end

  def issuer_name
    ENV.fetch("PRIVACY_PASS_ISSUER_NAME", "demo-issuer.private-access-tokens.fastly.com")
  end

  def issuer_name_length
    as_unsigned_16_bit([issuer_name.size])
  end

  def raw_redemption_context
    @raw_redemption_context ||= SecureRandom.hex(REDEMPTION_CONTEXT_LENGTH / 2)
  end

  def redemption_context
    as_unsigned_8_bit(raw_redemption_context.bytes) unless raw_redemption_context.empty?
  end

  def redemption_context_length
    as_unsigned_8_bit([raw_redemption_context.size])
  end

  def origin_info
    "" # this is optional, omitting for now
  end

  def origin_info_length
    as_unsigned_16_bit([origin_info.size])
  end

  def as_unsigned_16_bit(bytes, length = "*")
    # 16-bit unsigned, network (big-endian) byte order
    bytes.pack("n#{length}")
  end

  def as_unsigned_8_bit(bytes, length = "*")
    # 8-bit unsigned (unsigned char)
    bytes.pack("C#{length}")
  end
end
