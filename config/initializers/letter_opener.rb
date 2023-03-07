return unless Rails.env.development?

Rails.configuration.to_prepare do
  LetterOpenerWeb::ApplicationController.content_security_policy do |policy|
    policy.style_src :self, :unsafe_inline
    policy.img_src :self, 'data:'
  end
end
