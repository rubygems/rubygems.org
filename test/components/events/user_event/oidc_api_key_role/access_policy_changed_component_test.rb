# frozen_string_literal: true

require "test_helper"

class Events::UserEvent::OIDCApiKeyRole::AccessPolicyChangedComponentTest < ComponentTest
  should "render preview" do
    preview

    assert_text "Role: Push example\nChanged by RubyGems.org staff, not by you\n" \
                "Conditions are now: sub string_equals repo:example/repo:ref:refs/heads/main",
      exact: true, normalize_ws: false
  end

  should "not say an admin changed it when the owner did" do
    preview(by_owner: true, conditions: ["repository string_equals example/repo"])

    assert_text "Role: Push example\nConditions are now: repository string_equals example/repo",
      exact: true, normalize_ws: false
  end
end
