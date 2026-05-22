# frozen_string_literal: true

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

  test "sign up route stays available and shows a notice when sign up is disabled" do
    Clearance.configuration.stubs(:allow_sign_up?).returns(false)

    get "/sign_up"

    assert_response :success
    assert_select "#flash_alert", text: "New account registration has been temporarily disabled."
  end
end
