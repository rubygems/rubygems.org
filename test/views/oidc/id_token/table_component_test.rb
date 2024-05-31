require "test_helper"

class OIDC::IdToken::TableComponentTest < ComponentTest
  should "render preview" do
    id_tokens = create_list(:oidc_id_token, 2)
    preview id_tokens: id_tokens

    table = page.find("table")
    header = table.find("thead tr")
    table.all("tbody tr", count: 2)

    assert_equal ["Created at", "Expires at", "API Key Role", "JWT ID"], header.all("th").map(&:text)
  end
end
