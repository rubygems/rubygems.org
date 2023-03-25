require "test_helper"
require_relative "mailer_preview"

class MailerPreviewTest < ActiveSupport::TestCase
  setup do
    capture_io { Rails.application.load_seed }
  end

  MailerPreview.emails.each do |email_name|
    test email_name do
      assert_nothing_raised do
        MailerPreview.call(email_name)
      end
    end
  end
end
