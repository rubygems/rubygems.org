require "test_helper"

class PoliciesTest < SystemTest
  test "gracefully fails on unknown page" do
    assert_raises(ActionController::RoutingError) do
      visit "/policies/not-existing-one"
    end
  end

  test "it only allows html format" do
    assert_raises(ActionController::RoutingError) do
      visit "/policies/privacy-notice.zip"
    end
  end

  test "renders /policies/terms-of-service" do
    visit "/policies/terms-of-service"

    assert page.has_content?("Terms of Service")
  end

  test "renders /policies/privacy" do
    visit "/policies/privacy"

    assert page.has_content?("Privacy Policy")
  end

  test "renders /policies/acceptable-use" do
    visit "/policies/acceptable-use"

    assert page.has_content?("Acceptable Use Policy")
  end

  test "renders /policies/copyright" do
    visit "/policies/copyright"

    assert page.has_content?("Copyright Policy")
  end

  test "POST to valid policy returns method not allowed" do
    post "/policies/copyright"

    assert_response :method_not_allowed
    assert_equal "GET", response.headers["Allow"]
  end

  test "POST to invalid policy is disallowed" do
    assert_raises(ActionController::RoutingError) do
      post "/policies/nonexistent-policy"
    end
  end
end
