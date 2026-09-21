# frozen_string_literal: true

require "test_helper"

class Events::UserEvent::User::CreatedComponentTest < ComponentTest
  should "render preview" do
    preview

    assert_text "Email: user@rubygems-test.org", exact: true, normalize_ws: false
  end
end
