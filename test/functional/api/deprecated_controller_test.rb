require "test_helper"

class Api::DeprecatedControllerTest < ActionController::TestCase
  should "route old paths to new controller" do
    route = { controller: "api/deprecated" }
    assert_recognizes(route.merge(action: "index"), path: "/api_key")

    route = { controller: "api/deprecated", id: "rails" }
    assert_recognizes(route.merge(action: "index"), path: "/gems/rails.json")

    route = { controller: "api/deprecated" }
    assert_recognizes(route.merge(action: "index"), path: "/gems", method: :post)

    assert_recognizes(route.merge(action: "index"), path: "api/v1/gems/unyank", method: :put)
  end
end
