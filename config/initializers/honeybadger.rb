return if Rails.env.local? # Don't enable Honeybadger in local Development & Test environments

Rails.logger.silence(:error) do
  require "honeybadger"

  Honeybadger.configure do |config|
    config.before_notify do |notice|
      notice.halt! if ActionDispatch::ExceptionWrapper.rescue_responses.key?(notice.error_class)
    end

    config.logger = SemanticLogger[Honeybadger]
  end
end
