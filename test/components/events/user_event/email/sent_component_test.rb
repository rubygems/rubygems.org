# frozen_string_literal: true

require "test_helper"

class Events::UserEvent::Email::SentComponentTest < ComponentTest
  should "render preview" do
    preview

    assert_text "Subject: [Subject]"
    assert_text "From: example@rubygems.org"
    assert_text "To: user@rubygems-test.org"
  end
end
