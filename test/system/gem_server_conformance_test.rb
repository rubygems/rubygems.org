require "application_system_test_case"

require_relative "../../lib/gemcutter/middleware/hostess"

class GemServerConformanceTest < ApplicationSystemTestCase
  include ActionDispatch::Assertions::RoutingAssertions
  include ActiveJob::TestHelper

  setup do
    @tmp_versions_file = Tempfile.new("tmp_versions_file")
    tmp_path = @tmp_versions_file.path

    Rails.application.config.rubygems.stubs(:[]).with("versions_file_location").returns(tmp_path)
    Rails.application.config.rubygems.stubs(:[]).with("s3_compact_index_bucket").returns("s3_compact_index_bucket")
    Rails.application.config.rubygems.stubs(:[]).with("s3_contents_bucket").returns("s3_contents_bucket")

    test = self
    Rails.application.routes.disable_clear_and_finalize = true
    Rails.application.routes.draw do
      post "/set_time", to: lambda { |env|
        test.travel_to Time.iso8601(Rack::Request.new(env).body.read)
        [200, {}, ["OK"]]
      }
      post "/rebuild_versions_list", to: lambda { |_env|
        Rake::Task["compact_index:update_versions_file"].execute
        Rake::Task["compact_index:update_versions_file"].reenable
        [200, {}, ["OK"]]
      }
      hostess = Gemcutter::Middleware::Hostess.new(nil)
      to = lambda { |env|
        hostess.call(env)
          .tap do |response|
          response[1].delete("x-cascade")
        end
      }
      match "/quick/Marshal.4.8/:name", to:, via: :get, constraints: { name: /[A-Za-z0-9._-]+/ }
      match "/gems/:name", to:, via: :get, constraints: { name: Patterns::ROUTE_PATTERN }
      match "/specs.4.8.gz", to:, via: :get
      match "/prerelease_specs.4.8.gz", to:, via: :get
      match "/latest_specs.4.8.gz", to:, via: :get
    end

    Indexer.perform_now
    @subscriber = ActiveSupport::Notifications.subscribe("process_action.action_controller") do
      perform_enqueued_jobs only: [Indexer]
    end
  end

  teardown do
    ActiveSupport::Notifications.unsubscribe(@subscriber)
    Rails.application.reload_routes!
  end

  test "is a conformant gem server" do
    create(:api_key, scopes: %w[push_rubygem yank_rubygem])

    output, status = Open3.capture2e(
      {
        "UPSTREAM" => "http://#{Capybara.current_session.config.server_host}:#{Capybara.current_session.config.server_port}",
        "GEM_HOST_API_KEY" => "12345"
      },
      "gem_server_conformance",
      "--fail-fast", "--tag=~content_type_header", "--tag=~content_length_header"
    )

    assert_predicate status, :success?, output
  end
end
