require 'test_helper'

class DashboardTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user, email: "nick@example.com", api_key: "secret123")
    cookies[:remember_token] = @user.remember_token

    create(:rubygem_with_version, name: "arrakis")
  end

  test "gems I have pushed show on my dashboard" do
    rubygem = create(:rubygem_with_version, name: "sandworm")
    create(:ownership, rubygem: rubygem, user: @user)

    get dashboard_path

    assert page.has_content? "sandworm"
    assert ! page.has_content?("arrakis")
  end

  test "gems I have subscribed to show on my dashboard" do
    rubygem = create(:rubygem_with_version, name: "sandworm")
    create(:subscription, rubygem: rubygem, user: @user)

    get dashboard_path

    assert page.has_content? "sandworm"
    assert ! page.has_content?("arrakis")
  end
end
