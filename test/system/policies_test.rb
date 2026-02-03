require "application_system_test_case"

class PoliciesTest < ApplicationSystemTestCase
  test "renders /policies/terms-of-service" do
    visit "/policies/terms-of-service"

    assert_text("Terms of Service")
  end

  test "renders /policies/privacy" do
    visit "/policies/privacy"

    assert_text("Privacy Policy")
  end

  test "renders /policies/acceptable-use" do
    visit "/policies/acceptable-use"

    assert_text("Acceptable Use Policy")
  end

  test "renders /policies/copyright" do
    visit "/policies/copyright"

    assert_text("Copyright Policy")
  end
end
