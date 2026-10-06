# frozen_string_literal: true

require "test_helper"

class Events::RubygemEvent::Organization::AddedComponentTest < ComponentTest
  should "render preview" do
    preview(
      rubygem: create(:rubygem),
      organization: create(:organization, handle: "acme"),
      user: create(:user, handle: "Adder")
    )

    assert_text "Organization: acme\nAdded by: Adder", exact: true
    assert_link "acme", href: "/organizations/acme"
    assert_link "Adder"
  end
end
