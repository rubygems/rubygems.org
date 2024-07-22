# frozen_string_literal: true

require "test_helper"
require "better_html/test_helper/safe_erb_tester"

class ErbSafetyTest < ActiveSupport::TestCase
  include BetterHtml::TestHelper::SafeErbTester
  ERB_GLOB = File.join(
    "app", "views", "**", "{*.htm,*.html,*.htm.erb,*.html.erb,*.html+*.erb}"
  )

  Dir[ERB_GLOB, base: Rails.root].each do |filename|
    test "missing javascript escapes in #{filename}" do
      assert_erb_safety(Rails.root.join(filename).read, filename:)
    end
  end
end
