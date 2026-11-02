# frozen_string_literal: true

require "test_helper"

class OIDC::ApiKeyRole::TableComponentTest < ComponentTest
  should "render preview" do
    api_key_roles = create_list(:oidc_api_key_role, 2)
    preview api_key_roles: api_key_roles

    table = page.find("table")

    assert_equal %w[Name Token Issuer], table.all("thead tr th").map(&:text)
    assert_equal api_key_roles.map(&:name), table.all("tbody tr td:nth-child(1)").map(&:text)
  end

  should "style the name link like the other links in the row" do
    api_key_role = create(:oidc_api_key_role)
    preview api_key_roles: [api_key_role]

    # The name rendered with only a hover underline and no colour, so it read as
    # body text rather than a link to the role.
    name_link = page.find("tbody tr td:nth-child(1) a")
    provider_link = page.find("tbody tr td:nth-child(3) a")

    assert_equal provider_link[:class], name_link[:class]
    assert_includes name_link[:class].split, "text-orange-500"
    # Split on whitespace so "hover:underline" cannot satisfy this as a substring.
    assert_includes name_link[:class].split, "underline"
  end
end
