# frozen_string_literal: true

require "test_helper"

class PagesControllerTest < ActionController::TestCase
  context "when valid page is requested" do
    setup do
      get :show, params: { id: "about" }
    end

    should respond_with :ok
  end

  context "when the security page is requested" do
    setup do
      get :show, params: { id: "security" }
    end

    should respond_with :ok

    should "direct security reports to the security email" do
      assert_select "a[href='mailto:security@rubygems.org']"
    end

    should "no longer present HackerOne as a reporting channel" do
      assert_select "a[href='https://hackerone.com/rubygems']", false
      assert_no_match(/HackerOne/, @response.body)
    end
  end

  context "when invalid page is requested" do
    should "error" do
      assert_raises(ActionController::UrlGenerationError) do
        get :show, params: { id: "not-found-page" }
      end
    end
  end
end
