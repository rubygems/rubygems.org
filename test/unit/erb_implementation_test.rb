# frozen_string_literal: true

require "test_helper"
require "herb/engine"
require "herb/engine/validators"

class ErbImplementationTest < ActiveSupport::TestCase
  ERB_GLOB = File.join(
    "app", "views", "**", "{*.htm,*.html,*.htm.erb,*.html.erb,*.html+*.erb}"
  )

  Dir[ERB_GLOB, base: Rails.root].each do |filename|
    test "html errors in #{filename}" do
      data = Rails.root.join(filename).read
      assert_nothing_raised { Herb::Engine.new(data, filename:, visitors: Herb::Engine::Validators.all) }
    end
  end
end
