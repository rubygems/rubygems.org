# frozen_string_literal: true

require "test_helper"

class ErbSafetyTest < ActiveSupport::TestCase
  ERB_GLOB = File.join(
    "app", "views", "**", "{*.htm,*.html,*.htm.erb,*.html.erb,*.html+*.erb}"
  )

  Dir[ERB_GLOB, base: Rails.root].each do |filename|
    test "erb safety in #{filename}" do
      source = Rails.root.join(filename).read

      assert_nothing_raised do
        Herb::Engine.new(
          source,
          filename:,
          validation_mode: :raise,
          validators: { security: true }
        )
      end
    end
  end
end
