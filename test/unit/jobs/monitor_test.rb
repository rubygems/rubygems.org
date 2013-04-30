require 'test_helper'

class Jobs::MonitorTest < ActiveSupport::TestCase
  setup do
    @stub = stub_request(:post, "https://app.datadoghq.com/api/v1/events?api_key=test")
  end

  should "emit DataDog event" do
    ENV['DATADOG_API_KEY'] = "test"
    monitor = Jobs::Monitor.new
    monitor.alert_error(Object.new, StandardError.new)
    assert_requested @stub
  end
end

