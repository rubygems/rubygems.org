module PrivacyPassSupportable
  extend ActiveSupport::Concern

  private

  def setup_privacy_pass_challenge
    return unless privacy_pass_enabled?

    tokenizer = PrivacyPassTokenizer.new
    tokenizer.register_challenge_for_redemption(session.id)
    challenge = tokenizer.challenge_token
    response.set_header("WWW-Authenticate", "PrivateToken challenge=#{challenge}, token-key=#{PrivacyPassTokenizer.issuer_public_key}")
  end

  def valid_privacy_pass_redemption?
    return false unless privacy_pass_enabled?
    return session[:redeemed_privacy_pass] unless session[:redeemed_privacy_pass].nil?

    success = PrivacyPassRedeemer.call(request.headers["Authorization"], session.id)
    session[:redeemed_privacy_pass] = success
    success
  end

  def delete_privacy_pass_token_redemption
    session.delete(:redeemed_privacy_pass)
  end

  def privacy_pass_enabled?
    ld_context = LaunchDarkly::LDContext.with_key(self.class.name, "controller")
    Rails.configuration.launch_darkly_client.variation("gemcutter.privacy_pass.enabled", ld_context, false)
  end
end
