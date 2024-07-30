Rails.logger.silence(:error) do
  require "honeybadger"

  Honeybadger.configure do |config|
    config.before_notify do |notice|
      notice.halt! if ActionDispatch::ExceptionWrapper.rescue_responses.key?(notice.error_class)
    end

    config.logger = SemanticLogger[Honeybadger]

    if Rails.env.development?
      config.report_data = false
      config.logger.level = :error
    end
  end
end
