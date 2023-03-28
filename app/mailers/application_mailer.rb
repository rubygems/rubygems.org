class ApplicationMailer < ActionMailer::Base
  include SemanticLogger::Loggable

  layout "mailer"
end
