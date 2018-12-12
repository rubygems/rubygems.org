require "test_helper"

class RoutingTest < ActionDispatch::IntegrationTest
  def contoller_in_ui?(controller)
    !controller.nil? && controller !~ /^api|internal|email_confirmations.*$/
  end

  setup do
    @prev_env = ENV["RAILS_ENV"]
    ENV["RAILS_ENV"] = "production"
    routes = Rails.application.routes.routes
    @ui_paths_verb = routes.map { |r| [r.path.spec.to_s, r.verb] if contoller_in_ui? r.defaults[:controller] }.compact.to_h
  end

  test "active storate routes don't exist" do
    assert_raises(ActionController::RoutingError) do
      post "/rails/active_storage/direct_uploads"
    end
  end

  test "non html format route don't exist for UI" do
    @ui_paths_verb.each do |path, verb|
      next if path == "/" # adding random format after root (/) gives 404

      assert_raises(ActionController::RoutingError) do
        send(verb.downcase, path.gsub("(.:format)", ".something"))
      end
    end
  end

  test "adding format param to UI routes doesn't break the app" do
    @ui_paths_verb.each do |path, verb|
      next if path == "/" # adding random format after root (/) gives 404

      format_path = path.gsub("(.:format)", "?format=something")
      format_path.gsub!(":rubygem_id", "someid")
      format_path.gsub!(":id", "someid")
      format_path.gsub!("*id", "about") # used in high voltage route

      assert_nothing_raised do
        send(verb.downcase, format_path)
      end
    end
  end

  teardown do
    ENV["RAILS_ENV"] = @prev_env
  end
end
