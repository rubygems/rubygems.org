module CaptchaVerifiable
  extend ActiveSupport::Concern

  private

  def verified_captcha?
    HcaptchaVerifier.call(captcha_response, request.remote_ip)
  end

  def captcha_response
    params.permit("h-captcha-response")["h-captcha-response"]
  end
end
