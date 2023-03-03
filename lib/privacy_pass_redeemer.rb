class PrivacyPassRedeemer
  HEADER_FORMAT = /^PrivateToken token=(?<token>.*)$/
  # See https://www.ietf.org/archive/id/draft-ietf-privacypass-protocol-04.html#name-token-type
  # See https://www.ietf.org/archive/id/draft-ietf-privacypass-protocol-04.html#section-6.3
  # struct {
  #   uint16_t token_type = 0x0002
  #   uint8_t nonce[32];
  #   uint8_t challenge_digest[32];
  #   uint8_t token_key_id[32];
  #   uint8_t authenticator[Nk];
  # } Token;
  TOKEN_TYPE_LENGTH = 1
  NONCE_LENGTH = 32
  CHALLENGE_DIGEST_LENGTH = 32
  TOKEN_KEY_ID_LENGTH = 32
  NK_AUTHENTICATOR_LENGTH = 512

  def self.call(authorization_header, session_id)
    new(authorization_header, session_id).redeem
  rescue ArgumentError
    false
  end

  def initialize(authorization_header, session_id)
    matches = HEADER_FORMAT.match(authorization_header)
    raise ArgumentError, "invalid Privacy Pass Authorization header format" if authorization_header.nil? || matches.nil?

    token = matches.named_captures["token"]
    decoded_token = Base64.urlsafe_decode64(token)
    unpacked_token = decoded_token.unpack("nC#{NONCE_LENGTH}C#{CHALLENGE_DIGEST_LENGTH}C#{TOKEN_KEY_ID_LENGTH}C*")

    @token_length = unpacked_token.length
    @token_type_bytes = unpacked_token.slice!(0, TOKEN_TYPE_LENGTH)
    @nonce_bytes = unpacked_token.slice!(0, NONCE_LENGTH)
    @challenge_digest_bytes = unpacked_token.slice!(0, CHALLENGE_DIGEST_LENGTH)
    @token_key_id_bytes = unpacked_token.slice!(0, TOKEN_KEY_ID_LENGTH)
    @authenticator_bytes = unpacked_token.slice!(0, NK_AUTHENTICATOR_LENGTH)

    @session_id = session_id
  end

  def redeem
    return false unless valid_token_type?
    return false unless valid_token_length?
    return false unless confirm_single_redemption?

    public_key.verify(nil, authenticator_string, data_string)
  end

  private

  attr_reader :token_length, :token_type_bytes, :nonce_bytes, :challenge_digest_bytes, :token_key_id_bytes, :authenticator_bytes, :session_id

  def valid_token_type?
    token_type_bytes == [PrivacyPassTokenizer::TOKEN_TYPE]
  end

  def valid_token_length?
    expected_token_length = TOKEN_TYPE_LENGTH + NONCE_LENGTH + CHALLENGE_DIGEST_LENGTH + TOKEN_KEY_ID_LENGTH + NK_AUTHENTICATOR_LENGTH
    token_length == expected_token_length
  end

  def confirm_single_redemption?
    cache_key = "#{PrivacyPassTokenizer::CHALLENGE_DIGEST_CACHE_PREFIX}#{session_id}"
    cached_challenge_digest = Rails.cache.fetch(cache_key)
    exists = cached_challenge_digest && cached_challenge_digest == challenge_digest_hex
    Rails.cache.delete(cache_key) if exists
    exists
  end

  def challenge_digest_hex
    challenge_digest_bytes.pack("C*").unpack1("H*")
  end

  def authenticator_string
    authenticator_bytes.pack("C#{NK_AUTHENTICATOR_LENGTH}")
  end

  def data_string
    verifiable_data = token_type_bytes + nonce_bytes + challenge_digest_bytes + token_key_id_bytes
    verifiable_data.pack("nC#{NONCE_LENGTH}C#{CHALLENGE_DIGEST_LENGTH}C#{TOKEN_KEY_ID_LENGTH}")
  end

  def public_key
    gsubbed = PrivacyPassTokenizer.issuer_public_key.tr("-", "+").tr("_", "/")
    with_line_endings = gsubbed[0] + gsubbed[1..].scan(/.{1,64}/).join("\n")
    pem = "-----BEGIN PUBLIC KEY-----\n#{with_line_endings}\n-----END PUBLIC KEY-----\n"
    OpenSSL::PKey.read(pem)
  end
end
