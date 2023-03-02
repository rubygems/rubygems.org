class PrivacyPassRedeemer
  # TEST_HEADER = "PrivateToken token=AALLcAly6EBWhQyLe7d2jQVMqj_w7v2hckQXu5eKu54mU80z0u0E7GYrFJZIgA9ThFzYXSj_ClklhsUFukcUko1h4Wnyhorwo9CdnHxm9RcdbiX5wzcNo47zc4Al24lDNrehyirOcQyXbw1MIki0dHfjP0w5IshPGULtqYXdY0dQBeu9r_94BTFWThH2RiX6saYBWyj8t-AZS8wI6ZgBVleng8t611TYgacqua_NBpQ4zzWy44fsqNM6j5HhpmZEUWnh0_DwS1i4CsutizdljoVrMkzmHPf-x2PaPVN5gUbFDGf49u0nrcg80HiEeRzNjeek79duhJLHCdVZ-W3pX64zcLhlRiA4HHGdnx4eCC1IqY6o-iXl68nd0lcopz8GReSsKw4tKlmhuj8pk5kTpqZ7qdLdW4x2a-TSfpidzwUv9VYMVFwaVxZXjMpzQlbaKSTvXC5dQ2EAWC-4S7k1GnMWdOJ_YMmnWRXKGfuc_UyJP5UJ8yDcGWLr3HIXS5dDmVIM4_d0ncxFd1GIcSXliHt3ih1zUE5x6f7u5M7D0RrY37eqsCBYM3azOVPqKvPnF5hryzdBlY8vjuBSu__2_XAzBgOfkn1gouXU4ebYeWW5A0t6lEDII6T3hv-YsdmB8oMC-_V0qDyGQjYBM3LeKTYqXD9ndufQXwMaHy6XQzZkhRYpUYHSI7BagNS_rK4ogYLUdo1mqczbQMBedMRAfSlINBF01FTW9aTC0RHpVD7auDEQ4YVBUaAN1dt9K1X59LTFOBvrN8e6Ahi8RU2wWMz-wfq6NRzNg7o391h9jHicTA==".freeze
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
    return false unless authorization_header

    new(authorization_header, session_id).redeem
  rescue ArgumentError
    false
  end

  def initialize(authorization_header, session_id)
    matches = HEADER_FORMAT.match(authorization_header)
    raise ArgumentError, "invalid Privacy Pass Authorization header format" if matches.nil?

    token = matches.named_captures["token"]
    decoded_token = Base64.urlsafe_decode64(token)
    @unpacked_token = decoded_token.unpack("nC#{NONCE_LENGTH}C#{CHALLENGE_DIGEST_LENGTH}C#{TOKEN_KEY_ID_LENGTH}C*")
    @token_type = @unpacked_token.slice(0, TOKEN_TYPE_LENGTH)

    @session_id = session_id
  end

  def redeem
    return false unless valid_token_type?
    return false unless valid_token_length?
    return false unless confirm_single_redemption?

    public_key.verify(nil, authenticator_string, data_string)
  end

  private

  attr_reader :token_type, :unpacked_token, :session_id

  def valid_token_type?
    token_type == [PrivacyPassTokenizer::TOKEN_TYPE]
  end

  def valid_token_length?
    expected_token_length = TOKEN_TYPE_LENGTH + NONCE_LENGTH + CHALLENGE_DIGEST_LENGTH + TOKEN_KEY_ID_LENGTH + NK_AUTHENTICATOR_LENGTH
    unpacked_token.length == expected_token_length
  end

  def confirm_single_redemption?
    cache_key = "#{PrivacyPassTokenizer::CHALLENGE_DIGEST_CACHE_PREFIX}#{session_id}"
    cached_challenge_digest = Rails.cache.fetch(cache_key)
    exists = cached_challenge_digest && cached_challenge_digest == challenge_digest_hex
    Rails.cache.delete(cache_key) if exists
    exists
  end

  def token_type_bytes
    start_index = 0
    unpacked_token.slice(start_index, TOKEN_TYPE_LENGTH)
  end

  def nonce_bytes
    start_index = TOKEN_TYPE_LENGTH
    unpacked_token.slice(start_index, NONCE_LENGTH)
  end

  def challenge_digest_bytes
    start_index = TOKEN_TYPE_LENGTH + NONCE_LENGTH
    unpacked_token.slice(start_index, CHALLENGE_DIGEST_LENGTH)
  end

  def challenge_digest_hex
    challenge_digest_bytes.pack("C*").unpack1("H*")
  end

  def token_key_id_bytes
    start_index = TOKEN_TYPE_LENGTH + NONCE_LENGTH + CHALLENGE_DIGEST_LENGTH
    unpacked_token.slice(start_index, TOKEN_KEY_ID_LENGTH)
  end

  def authenticator_bytes
    start_index = TOKEN_TYPE_LENGTH + NONCE_LENGTH + CHALLENGE_DIGEST_LENGTH + TOKEN_KEY_ID_LENGTH
    unpacked_token.slice(start_index, NK_AUTHENTICATOR_LENGTH)
  end

  def authenticator_string
    authenticator_bytes.pack("C#{NK_AUTHENTICATOR_LENGTH}")
  end

  def data_string
    verifiable_data = token_type_bytes + nonce_bytes + challenge_digest_bytes + token_key_id_bytes
    verifiable_data.pack("nC#{NONCE_LENGTH}C#{CHALLENGE_DIGEST_LENGTH}C#{TOKEN_KEY_ID_LENGTH}")
  end

  def public_key
    # gsubbed = issuer_public_key.tr("-", "+").tr("_", "/").gsub("\r\n", "").scan(/.{1,64}/).join("\n")
    gsubbed = PrivacyPassTokenizer.issuer_public_key.tr("-", "+").tr("_", "/")
    with_line_endings = gsubbed[0] + gsubbed[1..].scan(/.{1,64}/).join("\n")
    pem = "-----BEGIN PUBLIC KEY-----\n#{with_line_endings}\n-----END PUBLIC KEY-----\n"
    OpenSSL::PKey.read(pem)
  end
end
