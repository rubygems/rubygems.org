require "test_helper"

class DashboardTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user, remember_token_expires_at: Gemcutter::REMEMBER_FOR.from_now)
    cookies[:remember_token] = @user.remember_token

    create(:rubygem, name: "arrakis", number: "1.0.0")
  end

  test "gems I have pushed show on my dashboard" do
    rubygem = create(:rubygem, name: "sandworm", number: "1.0.0")
    create(:ownership, rubygem: rubygem, user: @user)

    get dashboard_path

    assert page.has_content? "sandworm"
    refute page.has_content?("arrakis")
  end

  test "gems I have subscribed to show on my dashboard" do
    rubygem = create(:rubygem, name: "sandworm", number: "1.0.0")
    create(:subscription, rubygem: rubygem, user: @user)

    get dashboard_path

    assert page.has_content? "sandworm"
    refute page.has_content?("arrakis")
  end

  test "dashboard with a non valid format" do
    assert_raises(ActionController::RoutingError) do
      get dashboard_path(format: :json)
    end
  end

  test "dashboard with atom format" do
    rubygem = create(:rubygem, name: "sandworm", number: "1.0.0")
    create(:subscription, rubygem: rubygem, user: @user)

    get dashboard_path(format: :atom)
    assert_response :success
    assert_equal "application/atom+xml", response.content_type
    assert page.has_content? "sandworm"
  end

  test "shows announcements on dashboard" do
    Announcement.create!(body: "hello w.")
    get dashboard_path
    assert page.has_content?("hello w.")
  end
end
