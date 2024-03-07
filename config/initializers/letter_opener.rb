return unless Rails.env.development?

Rails.configuration.to_prepare do
  LetterOpenerWeb::ApplicationController.content_security_policy false
end
