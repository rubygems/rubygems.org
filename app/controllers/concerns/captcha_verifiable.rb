module CaptchaVerifiable
  extend ActiveSupport::Concern

  private

  def verified_captcha?
    HcaptchaVerifier.call(captcha_response, request.remote_ip)
  end

  def create_catpcha_user(id: nil, user_params: nil)
    session[:captcha_user] = if user_params
                               user_params.to_h
                             else
                               id
                             end
  end

  def user_from_captcha_user
    User.find(session[:captcha_user])
  end

  def captcha_user_params_present?
    session[:captcha_user].present? && session[:captcha_user].is_a?(Hash)
  end

  def user_params_from_captcha_user
    session[:captcha_user].symbolize_keys
  end

  def delete_captcha_user_from_session
    session.delete(:captcha_user)
  end

  def captcha_response
    params.permit("h-captcha-response")["h-captcha-response"]
  end
end
