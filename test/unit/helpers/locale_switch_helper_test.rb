# frozen_string_literal: true

require "test_helper"

class LocaleSwitchHelperTest < ActionView::TestCase
  include Rails.application.routes.url_helpers

  should "fall back to the localized home for a non-GET action with no GET form" do
    request.stubs(:get?).returns(false)
    request.stubs(:head?).returns(false)
    request.stubs(:path_parameters).returns(controller: "rubygems", action: "destroy")
    request.stubs(:query_parameters).returns({})

    assert_equal root_path(locale: :de), locale_switch_path(:de)
  end
end
