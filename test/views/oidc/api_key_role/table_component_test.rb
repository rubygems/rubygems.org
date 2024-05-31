require "test_helper"

class OIDC::ApiKeyRole::TableComponentTest < ComponentTest
  should "render preview" do
    api_key_roles = create_list(:oidc_api_key_role, 2)
    preview api_key_roles: api_key_roles

    table = page.find("table")

    assert_equal %w[Name Token Issuer], table.all("thead tr th").map(&:text)
    assert_equal api_key_roles.map(&:name), table.all("tbody tr td:nth-child(1)").map(&:text)
  end
end
