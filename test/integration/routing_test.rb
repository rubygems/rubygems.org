require "test_helper"

class RoutingTest < ActionDispatch::IntegrationTest
  def contoller_in_ui?(controller)
    !controller.nil? && controller !~ /^api|internal|sendgrid_events.*$/
  end

  setup do
    @prev_env = ENV["RAILS_ENV"]
    ENV["RAILS_ENV"] = "production"
    routes = Rails.application.routes.routes
    @ui_paths_verb = routes.filter_map { |r| [r.path.spec.to_s, r.verb] if contoller_in_ui? r.defaults[:controller] }.to_h
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
        # ex: get(/password/new.json)
        send(verb.downcase, path.gsub("(.:format)", ".something"))
      end
    end
  end

  test "adding format param to UI routes doesn't break the app" do
    @ui_paths_verb.each do |path, verb|
      next if path == "/"

      format_path = path.gsub("(.:format)", "?format=something")
      format_path.gsub!(":rubygem_id", "someid")
      format_path.gsub!(":id", "someid")
      format_path.gsub!("*id", "about") # used in high voltage route
      format_path.gsub!(":version_id", "someid")

      assert_nothing_raised do
        # ex: get(/password/new?format=json)
        send(verb.downcase, format_path)
      end
    end
  end

  test "invalid regex in static page route doesn't raise RegexpError" do
    assert_raises(ActionController::RoutingError) do
      get "/pages/%29"
    end
  end

  test "long static page route doesn't raise Errno::ENAMETOOLONG" do
    assert_raises(ActionController::RoutingError) do
      get "/pages/%EF%BF%BD%EF%BF%BD%EF%BF%BD%EF%BF%BD%EF%BF%BD%EF%BF%BD%EF%BF%BD%EF%BF%BD%EF%BF%BD%EF%BF%BD%EF%BF%BD%EF"\
          "%BF%BD%EF%BF%BD%EF%BF%BD%EF%BF%BD%EF%BF%BD%EF%BF%BD%EF%BF%BD%EF%BF%BD%EF%BF%BD%EF%BF%BD%EF%BF%BD%EF%BF%BD%EF%BF"\
          "%BD%EF%BF%BD%EF%BF%BD%EF%BF%BD%EF%BF%BD%EF%BF%BD%EF%BF%BD%EF%BF%BD%EF%BF%BD%EF%BF%BD%EF%BF%BD%EF%BF%BD%EF%BF%BD"\
          "%EF%BF%BD%EF%BF%BD%EF%BF%BD%EF%BF%BD%EF%BF%BD%EF%BF%BD%EF%BF%BD%EF%BF%BD%EF%BF%BD%EF%BF%BD%EF%BF%BD%EF%BF%BD%EF"\
          "%BF%BD%EF%BF%BD%EF%BF%BD%EF%BF%BD%EF%BF%BD%EF%BF%BD%EF%BF%BD%EF%BF%BD%EF%BF%BD%EF%BF%BD%EF%BF%BD%EF%BF%BD%EF%BF"\
          "%BD%EF%BF%BD%EF%BF%BD%EF%BF%BD%EF%BF%BD%EF%BF%BD%EF%BF%BD%EF%BF%BD%EF%BF%BD%EF%BF%BD%EF%BF%BD%EF%BF%BD%EF%BF%BD"\
          "%EF%BF%BD%EF%BF%BD%EF%BF%BD%EF%BF%BD%EF%BF%BD%EF%BF%BD%EF%BF%BD%EF%BF%BD%EF%BF%BD%EF%BF%BD%EF%BF%BD%EF%BF%BD%EF"\
          "%BF%BD%EF%BF%BD%EF%BF%BD%EF%BF%BD%EF%BF%BD%EF%BF%BD%EF%BF%BD%EF%BF%BD%EF%BF%BD%EF%BF%BD%EF%BF%BD/etc/passwd"
    end
  end

  test "any page with pagination doesn't raise TypeError when params exists in url" do
    assert_nothing_raised do
      get "/releases?page=2&params=thing"
    end
  end

  teardown do
    ENV["RAILS_ENV"] = @prev_env
  end
end
