module HcaptchaHelper
  def hcaptcha_site_key
    Rails.application.secrets.hcaptcha_site_key
  end
end
