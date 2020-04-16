Honeybadger.configure do |config|
  config.report_data = false if Rails.env.development?
  config.before_notify do |notice|
    notice.halt! if ActionDispatch::ExceptionWrapper.rescue_responses.key?(notice.error_class)
  end
end
