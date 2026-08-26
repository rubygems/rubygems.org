# frozen_string_literal: true

require "test_helper"

class Events::UserEvent::Email::VerifiedComponentTest < ComponentTest
  should "render preview" do
    preview rubygem: create(:rubygem)

    assert_text "user@rubygems-test.org", exact: true
  end
end
