module PrivacyPassSupportable
  extend ActiveSupport::Concern

  private

  def setup_privacy_pass_challenge
    tokenizer = PrivacyPassTokenizer.new
    tokenizer.register_challenge_for_redemption(session.id)
    challenge = tokenizer.challenge_token
    response.set_header("WWW-Authenticate", "PrivateToken challenge=#{challenge}, token-key=#{PrivacyPassTokenizer.issuer_public_key}")
  end

  def redeemed_privacy_pass_token?
    return session[:redeemed_privacy_pass] unless session[:redeemed_privacy_pass].nil?

    success = PrivacyPassRedeemer.call(request.headers["Authorization"], session.id)
    session[:redeemed_privacy_pass] = success
    success
  end

  def delete_privacy_pass_token_redemption
    session.delete(:redeemed_privacy_pass)
  end
end
