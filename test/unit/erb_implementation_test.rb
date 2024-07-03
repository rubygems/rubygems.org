# frozen_string_literal: true

require "test_helper"

class ErbImplementationTest < ActiveSupport::TestCase
  ERB_GLOB = File.join(
    "app", "views", "**", "{*.htm,*.html,*.htm.erb,*.html.erb,*.html+*.erb}"
  )

  Dir[ERB_GLOB, base: Rails.root].each do |filename|
    test "html errors in #{filename}" do
      data = Rails.root.join(filename).read
      BetterHtml::BetterErb::ErubiImplementation.new(data, filename:).validate!
    end
  end
end
