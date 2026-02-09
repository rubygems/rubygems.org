require "test_helper"

class RoutingErrorsTest < ActionDispatch::IntegrationTest
  test "pages gracefully fails on unknown page" do
    assert_raises(ActionController::RoutingError) do
      get "/pages/not-existing-one"
    end
  end

  test "pages only allows html format" do
    assert_raises(ActionController::RoutingError) do
      get "/pages/data.zip"
    end
  end

  test "policies gracefully fails on unknown page" do
    assert_raises(ActionController::RoutingError) do
      get "/policies/not-existing-one"
    end
  end

  test "policies only allows html format" do
    assert_raises(ActionController::RoutingError) do
      get "/policies/privacy-notice.zip"
    end
  end

  test "sign up route is disabled when sign up is disabled" do
    Clearance.configure { |config| config.allow_sign_up = false }
    Rails.application.reload_routes!

    assert_raises(ActionController::RoutingError) do
      get "/sign_up"
    end
  ensure
    Clearance.configure { |config| config.allow_sign_up = true }
    Rails.application.reload_routes!
  end
end
