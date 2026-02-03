require "application_system_test_case"

class PoliciesTest < ApplicationSystemTestCase
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
end
