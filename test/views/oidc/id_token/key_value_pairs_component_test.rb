require "test_helper"

class OIDC::IdToken::KeyValuePairsComponentTest < ComponentTest
  test "renders a list" do
    preview

    page.find("dt", text: "sub").sibling("dd", text: "1234567890")
  end

  test "renders an empty list" do
    preview scenario: :empty

    assert_text "", exact: true
  end
end
